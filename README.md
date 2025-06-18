GUM-TimeTracker


## 🌟 Features

**Main Interface:**
- Beautiful welcome screen with styling
- Interactive menu system with emojis and clear navigation
- Smart input validation and error handling

**Core Functionality:**
- **Log Work Time**: Select project, enter date/time, add notes
- **View Time Logs**: See logs for any date with totals
- **Manage Projects**: List and refresh projects from server
- **Settings**: View user configuration

**Smart UI Elements:**
- Project selection with active projects only
- Date input with current date as default
- Time validation (hours 0-23, minutes 0-59)
- Loading spinners for API calls
- Color-coded feedback (green for success, red for errors)

## 🔧 Setup

1. **Install dependencies:**
   ```bash
   # macOS
   brew install gum jq

   # Or download from GitHub releases
   ```

2. **Make executable:**
   ```bash
   chmod +x timetracker.sh
   ```

3. **Run:**
   ```bash
   ./timetracker.sh
   ```

## 📁 Data Structure

The script creates a `~/.timetracker/` directory with:
- `config.json` - API configuration
- `projects.json` - Projects list with UUIDs and names
- `user.json` - User information

## 🔄 Mock API Integration

Currently includes mock API calls that simulate:
- `POST /time-logs` - Log work time
- `GET /time-logs?date=YYYY-MM-DD` - Get logs for date
- `GET /projects` - List all projects
- `PUT /projects` - Update projects list

## 🎨 Customization

To adapt for real API:
1. Update `API_BASE_URL` and `API_TOKEN` in the script
2. Modify the `api_call()` function to make real curl requests
3. Adjust JSON structures to match your API

**Example real API call:**
```bash
api_call() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    
    curl -s -X "$method" \
         -H "Authorization: Bearer $API_TOKEN" \
         -H "Content-Type: application/json" \
         -d "$data" \
         "$API_BASE_URL$endpoint"
}
```

The interface is fully functional with realistic mock data, so you can test the entire user experience before connecting to your actual API! 🚀
