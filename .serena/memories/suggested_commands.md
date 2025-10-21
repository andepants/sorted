# Suggested Commands

## Building & Running

### Build for Simulator
```bash
# Using XcodeBuildMCP (preferred in Claude Code)
build_sim({ 
  projectPath: '/Users/andre/coding/sorted/sorted.xcodeproj', 
  scheme: 'sorted', 
  simulatorName: 'iPhone 16' 
})

# In Xcode
⌘B  # Build
⌘R  # Build and Run
```

### Build and Run (Parallel Rebuilds)
When making changes that require rebuilding multiple running simulators:
```bash
# Rebuild ALL running simulators in parallel
build_run_sim calls for each simulator simultaneously
```

### Run on Physical Device
```bash
# Using XcodeBuildMCP
build_device({ 
  projectPath: '/Users/andre/coding/sorted/sorted.xcodeproj', 
  scheme: 'sorted' 
})
```

## Testing

### Run Tests
```bash
# In Xcode
⌘U  # Run all unit tests

# Using XcodeBuildMCP
test_sim({ 
  projectPath: '/Users/andre/coding/sorted/sorted.xcodeproj', 
  scheme: 'sorted', 
  simulatorName: 'iPhone 16' 
})
```

### UI Tests
```bash
# Run specific UI test suite
test_sim with specific test target (sortedUITests)
```

## Code Quality

### Linting
```bash
# Run SwiftLint (if installed via Homebrew)
swiftlint lint

# Auto-fix violations
swiftlint --fix

# Lint specific file
swiftlint lint --path sorted/Features/Auth/Views/LoginView.swift
```

### Format Code
SwiftLint has auto-fix capabilities:
```bash
swiftlint --fix --format
```

## Firebase

### Deploy Functions
```bash
cd /Users/andre/coding/sorted
firebase deploy --only functions

# Deploy with linting and building
npm --prefix functions run lint
npm --prefix functions run build
firebase deploy --only functions
```

### Deploy Rules
```bash
# Firestore rules
firebase deploy --only firestore:rules

# Storage rules
firebase deploy --only storage

# Database rules
firebase deploy --only database
```

### Emulators (Local Development)
```bash
firebase emulators:start
```

## Git Commands (macOS Darwin)

### Basic Git
```bash
git status
git add .
git commit -m "message"
git push
git pull
```

### Branch Management
```bash
git checkout -b feature/branch-name
git branch
git merge main
```

## Xcode Utilities

### List Available Simulators
```bash
# Using XcodeBuildMCP
list_sims()

# Using xcrun
xcrun simctl list devices
```

### List Schemes
```bash
# Using XcodeBuildMCP
list_schemes({ projectPath: '/Users/andre/coding/sorted/sorted.xcodeproj' })

# Using xcodebuild
xcodebuild -list -project sorted.xcodeproj
```

### Clean Build
```bash
# Using XcodeBuildMCP
clean({ projectPath: '/Users/andre/coding/sorted/sorted.xcodeproj', scheme: 'sorted' })

# In Xcode
⌘⇧K  # Clean Build Folder
```

## macOS System Utilities (Darwin)

### File Operations
```bash
ls -la          # List files with details
find . -name    # Find files by name
grep -r         # Search in files (use Grep tool in Claude Code)
cat filename    # Display file contents (use Read tool in Claude Code)
```

### Process Management
```bash
ps aux | grep   # List processes
kill -9 PID     # Force kill process
```

### Network
```bash
nslookup domain.com
dig domain.com
curl -X GET url
```

### Package Management
```bash
npm ls          # List npm packages
npm install     # Install dependencies
```

## Dependencies

### Resolve SPM Dependencies
In Xcode:
- File > Packages > Resolve Package Versions
- Or: ⌘⇧K to clean, then ⌘B to rebuild (auto-resolves)

## Debugging

### Capture Logs
```bash
# Using XcodeBuildMCP for simulator
start_sim_log_cap({ simulatorUuid: 'UUID', bundleId: 'com.sorted.app.dev' })
stop_sim_log_cap({ logSessionId: 'SESSION_ID' })

# For device
start_device_log_cap({ deviceId: 'DEVICE_ID', bundleId: 'com.sorted.app.dev' })
```

### View Build Settings
```bash
# Using XcodeBuildMCP
show_build_settings({ 
  projectPath: '/Users/andre/coding/sorted/sorted.xcodeproj', 
  scheme: 'sorted' 
})
```
