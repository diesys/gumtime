#!/usr/bin/env bash

# GumTime - A beautiful interface for time management
# Requires: gum (https://github.com/charmbracelet/gum)

set -e

# Configuration
CONFIG_DIR="$HOME/.gumtime"
CONFIG_FILE="$CONFIG_DIR/config.json"
PROJECTS_FILE="$CONFIG_DIR/projects.json"
USER_FILE="$CONFIG_DIR/user.json"

# API Configuration (mock for now)
API_BASE_URL="https://api.gumtime.example.com"
API_TOKEN="your-api-token-here"

# Colors and styling
export GUM_INPUT_CURSOR_FOREGROUND="#FF06B7"
export GUM_INPUT_PROMPT_FOREGROUND="#04B575"
export GUM_CHOOSE_CURSOR_FOREGROUND="#FF06B7"
export GUM_CHOOSE_SELECTED_FOREGROUND="#FF06B7"

# Initialize configuration
init_config() {
    if [[ ! -d "$CONFIG_DIR" ]]; then
        echo "📁 Creating configuration directory..."
        mkdir -p "$CONFIG_DIR" || {
            echo "❌ Error: Cannot create config directory $CONFIG_DIR"
            echo "Please check permissions or manually create the directory."
            exit 1
        }
        echo "✅ Created: $CONFIG_DIR"
    fi
    
    # Create default user config if it doesn't exist
    if [[ ! -f "$USER_FILE" ]]; then
        echo "👤 Creating user configuration..."
        if ! cat > "$USER_FILE" << 'EOF'
{
  "uuid": "user-12345-abcde",
  "name": "Demo User",
  "email": "demo@example.com"
}
EOF
        then
            echo "❌ Error: Cannot create user config file"
            exit 1
        fi
        echo "✅ Created: $USER_FILE"
    fi
    
    # Create default projects if they don't exist
    if [[ ! -f "$PROJECTS_FILE" ]]; then
        echo "📋 Creating projects configuration..."
        if ! cat > "$PROJECTS_FILE" << 'EOF'
{
  "projects": [
    {
      "uuid": "proj-001-website",
      "name": "Company Website Redesign",
      "description": "Complete redesign of company website",
      "status": "active"
    },
    {
      "uuid": "proj-002-mobile",
      "name": "Mobile App Development",
      "description": "iOS and Android app development",
      "status": "active"
    },
    {
      "uuid": "proj-003-api",
      "name": "REST API Backend",
      "description": "Backend API development",
      "status": "active"
    },
    {
      "uuid": "proj-004-docs",
      "name": "Documentation Update",
      "description": "Technical documentation update",
      "status": "paused"
    }
  ]
}
EOF
        then
            echo "❌ Error: Cannot create projects config file"
            exit 1
        fi
        echo "✅ Created: $PROJECTS_FILE"
    fi
    
    # Create default config
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "⚙️  Creating main configuration..."
        if ! cat > "$CONFIG_FILE" << EOF
{
  "api_url": "$API_BASE_URL",
  "api_token": "$API_TOKEN",
  "mock_mode": true,
  "show_curl_commands": true,
  "last_updated": "$(date -Iseconds)"
}
EOF
        then
            echo "❌ Error: Cannot create main config file"
            exit 1
        fi
        echo "✅ Created: $CONFIG_FILE"
        echo ""
        echo "🎉 Configuration setup complete!"
        echo "📁 All files created in: $CONFIG_DIR"
        echo ""
        sleep 1
    fi
}

# Check dependencies
check_dependencies() {
    if ! command -v gum &> /dev/null; then
        echo "❌ Error: 'gum' is required but not installed."
        echo "Install it from: https://github.com/charmbracelet/gum"
        echo ""
        echo "Quick install options:"
        echo "  macOS: brew install gum"
        echo "  Linux: Check the GitHub releases page"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo "❌ Error: 'jq' is required but not installed."
        echo "Install jq for JSON processing"
        exit 1
    fi
}

# API call function with curl command display
api_call() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    local show_curl="${4:-true}"
    
    # Get API configuration
    local api_url=$(jq -r '.api_url' "$CONFIG_FILE")
    local api_token=$(jq -r '.api_token' "$CONFIG_FILE")
    
    # Build curl command
    local curl_cmd="curl -s -X $method"
    curl_cmd="$curl_cmd -H 'Authorization: Bearer $api_token'"
    curl_cmd="$curl_cmd -H 'Content-Type: application/json'"
    curl_cmd="$curl_cmd -H 'User-Agent: TimeTracker-CLI/1.0'"
    
    if [[ -n "$data" && "$method" != "GET" ]]; then
        # Escape quotes in data for display
        local escaped_data=$(echo "$data" | sed 's/"/\\"/g')
        curl_cmd="$curl_cmd -d \"$escaped_data\""
    fi
    
    curl_cmd="$curl_cmd '$api_url$endpoint'"
    
    # Show the curl command that would be executed
    if [[ "$show_curl" == "true" ]]; then
        echo ""
        gum style --foreground 240 "📡 API Call:"
        gum style --foreground 245 --border rounded --padding "1 2" "$curl_cmd"
        echo ""
    fi
    
    # For demo purposes, show what the real call would be, but return mock data
    if [[ "$MOCK_MODE" == "false" ]]; then
        # Uncomment this line to make real API calls:
        # eval "$curl_cmd"
        
        # For now, show that we would make the call but return an error
        gum style --foreground 196 "⚠️  Real API mode not implemented yet"
        gum style --foreground 240 "Set MOCK_MODE=false in config to enable real calls"
        return 1
    fi
    
    # Mock mode - simulate API delay and return mock data
    sleep 0.5
    
    case "$endpoint" in
        "/projects")
            if [[ "$method" == "GET" ]]; then
                cat "$PROJECTS_FILE"
            elif [[ "$method" == "PUT" ]]; then
                echo "$data" > "$PROJECTS_FILE"
                echo '{"status": "success", "message": "Projects updated successfully"}'
            fi
            ;;
        "/time-logs")
            if [[ "$method" == "POST" ]]; then
                echo '{"status": "success", "message": "Time logged successfully", "id": "log-'$(date +%s)'"}'
            elif [[ "$method" == "GET" ]]; then
                # Mock response for time logs (filter by date if provided)
                local query_date=""
                if [[ "$endpoint" == *"date="* ]]; then
                    query_date=$(echo "$endpoint" | grep -o 'date=[^&]*' | cut -d'=' -f2)
                fi
                
                echo '{
                  "logs": [
                    {
                      "id": "log-001",
                      "date": "'${query_date:-2025-06-19}'",
                      "hours": 2,
                      "minutes": 30,
                      "project_uuid": "proj-001-website",
                      "project_name": "Company Website Redesign",
                      "note": "Worked on responsive design",
                      "user_uuid": "user-12345-abcde"
                    },
                    {
                      "id": "log-002",
                      "date": "'${query_date:-2025-06-19}'",
                      "hours": 1,
                      "minutes": 45,
                      "project_uuid": "proj-002-mobile",
                      "project_name": "Mobile App Development",
                      "note": "Fixed authentication bug",
                      "user_uuid": "user-12345-abcde"
                    }
                  ],
                  "total_entries": 2,
                  "date_filter": "'${query_date:-2025-06-19}'"
                }'
            fi
            ;;
        "/time-logs/"*)
            if [[ "$method" == "PUT" ]]; then
                echo '{"status": "success", "message": "Time log updated successfully"}'
            elif [[ "$method" == "DELETE" ]]; then
                echo '{"status": "success", "message": "Time log deleted successfully"}'
            fi
            ;;
    esac
}

# Welcome screen
show_welcome() {
    clear
    gum style \
        --foreground 212 --border-foreground 212 --border double \
        --align center --width 60 --margin "1 2" --padding "2 4" \
        '⏰ GumTime' 'Beautiful time management at your fingertips'
    
    echo ""
    gum style --foreground 240 "Manage your work hours with style ✨"
    echo ""
}

# Main menu
show_main_menu() {
    gum choose --cursor-prefix "→ " --selected-prefix "✓ " \
        "📝 Log Work Time" \
        "📊 View Time Logs" \
        "📋 Manage Projects" \
        "⚙️  Settings" \
        "🚪 Exit"
}

# Project selection menu
select_project() {
    local projects_json=$(cat "$PROJECTS_FILE")
    local project_names=($(echo "$projects_json" | jq -r '.projects[] | select(.status == "active") | .name'))
    
    if [[ ${#project_names[@]} -eq 0 ]]; then
        gum style --foreground 196 "❌ No active projects found!"
        return 1
    fi
    
    gum style --foreground 212 "🎯 Select a project:"
    echo ""
    
    local selected_name=$(printf '%s\n' "${project_names[@]}" | gum choose --cursor-prefix "→ ")
    
    if [[ -n "$selected_name" ]]; then
        # Get the UUID for the selected project
        echo "$projects_json" | jq -r ".projects[] | select(.name == \"$selected_name\") | .uuid"
    fi
}

# Date input with smart defaults
input_date() {
    local default_date=$(date +%Y-%m-%d)
    
    gum style --foreground 212 "📅 Enter date (YYYY-MM-DD):"
    echo ""
    
    local input_date=$(gum input --placeholder "$default_date" --value "$default_date")
    
    # Validate date format
    if date -d "$input_date" &>/dev/null; then
        echo "$input_date"
    else
        gum style --foreground 196 "❌ Invalid date format!"
        return 1
    fi
}

# Time input
input_time() {
    gum style --foreground 212 "⏱️  Enter time spent:"
    echo ""
    
    local hours=$(gum input --placeholder "Hours (0-23)" --width 20)
    local minutes=$(gum input --placeholder "Minutes (0-59)" --width 20)
    
    # Validate input
    if [[ ! "$hours" =~ ^[0-9]+$ ]] || [[ ! "$minutes" =~ ^[0-9]+$ ]]; then
        gum style --foreground 196 "❌ Please enter valid numbers!"
        return 1
    fi
    
    if [[ $hours -gt 23 ]] || [[ $minutes -gt 59 ]]; then
        gum style --foreground 196 "❌ Invalid time values!"
        return 1
    fi
    
    echo "$hours $minutes"
}

# Log work time
log_work_time() {
    clear
    gum style --foreground 212 --border-foreground 212 --border rounded \
        --padding "1 2" --margin "1 0" \
        "📝 LOG WORK TIME"
    
    echo ""
    
    # Select project
    local project_uuid=$(select_project)
    if [[ -z "$project_uuid" ]]; then
        return 1
    fi
    
    echo ""
    
    # Input date
    local log_date=$(input_date)
    if [[ -z "$log_date" ]]; then
        return 1
    fi
    
    echo ""
    
    # Input time
    local time_input=$(input_time)
    if [[ -z "$time_input" ]]; then
        return 1
    fi
    
    local hours=$(echo "$time_input" | cut -d' ' -f1)
    local minutes=$(echo "$time_input" | cut -d' ' -f2)
    
    echo ""
    
    # Input note
    gum style --foreground 212 "📝 Add a note (optional):"
    local note=$(gum write --placeholder "What did you work on?")
    
    echo ""
    
    # Get user UUID
    local user_uuid=$(jq -r '.uuid' "$USER_FILE")
    
    # Prepare data
    local data=$(jq -n \
        --arg date "$log_date" \
        --argjson hours "$hours" \
        --argjson minutes "$minutes" \
        --arg project_uuid "$project_uuid" \
        --arg note "$note" \
        --arg user_uuid "$user_uuid" \
        '{
            date: $date,
            hours: $hours,
            minutes: $minutes,
            project_uuid: $project_uuid,
            note: $note,
            user_uuid: $user_uuid
        }')
    
    # Show loading
    gum spin --spinner dot --title "Logging time..." -- sleep 1
    
    # Make API call
    local response=$(api_call "POST" "/time-logs" "$data")
    local status=$(echo "$response" | jq -r '.status')
    
    if [[ "$status" == "success" ]]; then
        gum style --foreground 46 "✅ Time logged successfully!"
        echo ""
        gum style --foreground 240 "📊 Summary:"
        gum style --foreground 252 "  Date: $log_date"
        gum style --foreground 252 "  Time: ${hours}h ${minutes}m"
        gum style --foreground 252 "  Project: $(jq -r ".projects[] | select(.uuid == \"$project_uuid\") | .name" "$PROJECTS_FILE")"
        [[ -n "$note" ]] && gum style --foreground 252 "  Note: $note"
    else
        gum style --foreground 196 "❌ Failed to log time!"
    fi
    
    echo ""
    gum style --foreground 240 "Press any key to continue..."
    read -n 1
}

# View time logs
view_time_logs() {
    clear
    gum style --foreground 212 --border-foreground 212 --border rounded \
        --padding "1 2" --margin "1 0" \
        "📊 VIEW TIME LOGS"
    
    echo ""
    
    # Input date
    local log_date=$(input_date)
    if [[ -z "$log_date" ]]; then
        return 1
    fi
    
    echo ""
    gum spin --spinner dot --title "Fetching logs..." -- sleep 1
    
    # Make API call
    local response=$(api_call "GET" "/time-logs?date=$log_date")
    local logs=$(echo "$response" | jq -r '.logs[]')
    
    if [[ -z "$logs" ]]; then
        gum style --foreground 240 "📭 No logs found for $log_date"
    else
        gum style --foreground 46 "📋 Time logs for $log_date:"
        echo ""
        
        echo "$response" | jq -r '.logs[] | "🕐 \(.hours)h \(.minutes)m - \(.project_name)\n   📝 \(.note // "No note")\n"'
        
        # Show total time
        local total_minutes=$(echo "$response" | jq '[.logs[] | (.hours * 60 + .minutes)] | add')
        local total_hours=$((total_minutes / 60))
        local remainder_minutes=$((total_minutes % 60))
        
        echo ""
        gum style --foreground 212 --border-foreground 212 --border rounded \
            --padding "1 2" \
            "⏱️  Total: ${total_hours}h ${remainder_minutes}m"
    fi
    
    echo ""
    gum style --foreground 240 "Press any key to continue..."
    read -n 1
}

# Manage projects
manage_projects() {
    clear
    gum style --foreground 212 --border-foreground 212 --border rounded \
        --padding "1 2" --margin "1 0" \
        "📋 MANAGE PROJECTS"
    
    echo ""
    
    local action=$(gum choose --cursor-prefix "→ " \
        "📝 List Projects" \
        "🔄 Refresh from Server" \
        "⬅️  Back to Main Menu")
    
    case "$action" in
        "📝 List Projects")
            list_projects
            ;;
        "🔄 Refresh from Server")
            refresh_projects
            ;;
        "⬅️  Back to Main Menu")
            return
            ;;
    esac
}

# List projects
list_projects() {
    echo ""
    gum spin --spinner dot --title "Loading projects..." -- sleep 0.5
    
    local projects_json=$(cat "$PROJECTS_FILE")
    
    gum style --foreground 46 "🎯 Available Projects:"
    echo ""
    
    echo "$projects_json" | jq -r '.projects[] | "• \(.name) (\(.status))\n  📝 \(.description)\n"'
    
    echo ""
    gum style --foreground 240 "Press any key to continue..."
    read -n 1
}

# Refresh projects from server
refresh_projects() {
    echo ""
    gum spin --spinner dot --title "Syncing with server..." -- sleep 1.5
    
    # Mock API call to refresh projects
    local response=$(api_call "GET" "/projects")
    
    if [[ $? -eq 0 ]]; then
        echo "$response" > "$PROJECTS_FILE"
        gum style --foreground 46 "✅ Projects refreshed successfully!"
    else
        gum style --foreground 196 "❌ Failed to refresh projects!"
    fi
    
    echo ""
    gum style --foreground 240 "Press any key to continue..."
    read -n 1
}

# Settings menu
show_settings() {
    clear
    gum style --foreground 212 --border-foreground 212 --border rounded \
        --padding "1 2" --margin "1 0" \
        "⚙️  SETTINGS"
    
    echo ""
    
    local user_info=$(cat "$USER_FILE")
    local user_name=$(echo "$user_info" | jq -r '.name')
    local user_email=$(echo "$user_info" | jq -r '.email')
    local config_info=$(cat "$CONFIG_FILE")
    local api_url=$(echo "$config_info" | jq -r '.api_url')
    local mock_mode=$(echo "$config_info" | jq -r '.mock_mode // true')
    
    gum style --foreground 252 "👤 Current User: $user_name"
    gum style --foreground 240 "📧 Email: $user_email"
    gum style --foreground 240 "🌐 API URL: $api_url"
    gum style --foreground 240 "🎭 Mock Mode: $mock_mode"
    gum style --foreground 240 "💾 Config Dir: $CONFIG_DIR"
    
    echo ""
    gum style --foreground 212 "Configuration Options:"
    echo ""
    
    local action=$(gum choose --cursor-prefix "→ " \
        "🔧 Edit API Settings" \
        "👤 Edit User Info" \
        "🎭 Toggle Mock Mode" \
        "⬅️  Back to Main Menu" \
        # "" \
        # "!! INIT CONFIG !!"
        )
    
    case "$action" in
        "🔧 Edit API Settings")
            edit_api_settings
            ;;
        "👤 Edit User Info")
            edit_user_info
            ;;
        "🎭 Toggle Mock Mode")
            toggle_mock_mode
            ;;
        "⬅️  Back to Main Menu")
            return
            ;;
        # "!! INIT CONFIG")
        #     init_config
        #     ;;
    esac
}

# Edit API settings
edit_api_settings() {
    echo ""
    gum style --foreground 212 "🔧 Edit API Settings"
    echo ""
    
    local current_url=$(jq -r '.api_url' "$CONFIG_FILE")
    local current_token=$(jq -r '.api_token' "$CONFIG_FILE")
    
    local new_url=$(gum input --placeholder "API URL" --value "$current_url")
    local new_token=$(gum input --placeholder "API Token" --value "$current_token" --password)
    
    # Update config
    local updated_config=$(jq \
        --arg url "$new_url" \
        --arg token "$new_token" \
        '.api_url = $url | .api_token = $token | .last_updated = now | strftime("%Y-%m-%dT%H:%M:%S%z")' \
        "$CONFIG_FILE")
    
    echo "$updated_config" > "$CONFIG_FILE"
    
    gum style --foreground 46 "✅ API settings updated!"
    sleep 1
}

# Edit user info
edit_user_info() {
    echo ""
    gum style --foreground 212 "👤 Edit User Information"
    echo ""
    
    local current_name=$(jq -r '.name' "$USER_FILE")
    local current_email=$(jq -r '.email' "$USER_FILE")
    
    local new_name=$(gum input --placeholder "Full Name" --value "$current_name")
    local new_email=$(gum input --placeholder "Email" --value "$current_email")
    
    # Update user config
    local updated_user=$(jq \
        --arg name "$new_name" \
        --arg email "$new_email" \
        '.name = $name | .email = $email' \
        "$USER_FILE")
    
    echo "$updated_user" > "$USER_FILE"
    
    gum style --foreground 46 "✅ User information updated!"
    sleep 1
}

# Toggle mock mode
toggle_mock_mode() {
    local current_mode=$(jq -r '.mock_mode // true' "$CONFIG_FILE")
    local new_mode
    
    if [[ "$current_mode" == "true" ]]; then
        new_mode="false"
        gum style --foreground 196 "⚠️  Enabling real API mode!"
        gum style --foreground 240 "Make sure your API settings are correct."
    else
        new_mode="true"
        gum style --foreground 46 "🎭 Enabling mock mode for testing."
    fi
    
    # Update config
    local updated_config=$(jq \
        --argjson mode "$new_mode" \
        '.mock_mode = $mode | .last_updated = now | strftime("%Y-%m-%dT%H:%M:%S%z")' \
        "$CONFIG_FILE")
    
    echo "$updated_config" > "$CONFIG_FILE"
    
    gum style --foreground 46 "✅ Mock mode set to: $new_mode"
    sleep 1
}

# Main application loop
main() {
    check_dependencies
    init_config
    
    # Load configuration
    MOCK_MODE=$(jq -r '.mock_mode // true' "$CONFIG_FILE")
    SHOW_CURL=$(jq -r '.show_curl_commands // true' "$CONFIG_FILE")
    
    while true; do
        show_welcome
        
        local choice=$(show_main_menu)
        
        case "$choice" in
            "📝 Log Work Time")
                log_work_time
                ;;
            "📊 View Time Logs")
                view_time_logs
                ;;
            "📋 Manage Projects")
                manage_projects
                ;;
            "⚙️  Settings")
                show_settings
                ;;
            "🚪 Exit")
                clear
                gum style --foreground 212 "👋 Thanks for using GumTime!"
                echo ""
                exit 0
                ;;
        esac
    done
}

# Run the application
main "$@"