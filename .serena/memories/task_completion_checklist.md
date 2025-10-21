# Task Completion Checklist

When completing a task (bug fix, new feature, refactoring), follow these steps:

## 1. Code Quality Checks

### SwiftLint
```bash
# Run linting on changed files
swiftlint lint --path sorted/path/to/changed/file.swift

# Auto-fix simple violations
swiftlint --fix
```

### File Length Verification
- Ensure all modified files are **under 500 lines**
- If a file exceeds 500 lines, split it into smaller modules

### Documentation Check
- [ ] All new public APIs documented with `///` doc comments
- [ ] File header documentation added for new files
- [ ] Complex logic includes inline comments

## 2. Build Verification

### Rebuild All Active Simulators
**IMPORTANT**: If you have multiple simulators running, rebuild ALL of them in parallel:
```bash
# Use parallel build_run_sim calls for each running simulator
```

### Clean Build
```bash
# Perform clean build to catch any issues
⌘⇧K  # Clean Build Folder in Xcode
⌘B   # Rebuild
```

## 3. Testing

### Unit Tests
```bash
# Run all unit tests
⌘U in Xcode

# Or using XcodeBuildMCP
test_sim({ 
  projectPath: '/Users/andre/coding/sorted/sorted.xcodeproj', 
  scheme: 'sorted', 
  simulatorName: 'iPhone 16' 
})
```

### Manual Testing
- [ ] Test on iOS 17 simulator (minimum target)
- [ ] Test on latest iOS simulator
- [ ] If auth/push notifications: Test on physical device
- [ ] Verify offline-first behavior (airplane mode test)

### UI Tests (if applicable)
```bash
# Run UI test suite
# Especially for Auth changes: sortedUITests/AuthenticationUITests.swift
```

## 4. Code Review Checklist

### Swift 6 Compliance
- [ ] Using `async/await` (no completion handlers)
- [ ] `@MainActor` annotations for UI code
- [ ] Errors thrown explicitly (no silent failures)
- [ ] Strict concurrency rules followed

### SwiftUI Best Practices
- [ ] Correct state management (`@State`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`)
- [ ] `.task` modifier used for async work in view lifecycle
- [ ] Complex views extracted into separate structs

### Naming & Style
- [ ] Descriptive variable names (`isLoading`, `hasError`, `canSend`)
- [ ] Boolean properties prefixed (`is`, `has`, `can`, `should`)
- [ ] `// MARK: -` sections added for organization
- [ ] No force unwrapping (`!`) without justification

### Architecture
- [ ] Follows feature-based structure
- [ ] No unnecessary code duplication
- [ ] Protocol-oriented design where applicable
- [ ] Prefer structs over classes

## 5. Firebase Integration (if applicable)

### Security Rules
```bash
# Deploy updated rules if modified
firebase deploy --only firestore:rules
firebase deploy --only storage
firebase deploy --only database
```

### Cloud Functions
```bash
# If functions modified
npm --prefix functions run lint
npm --prefix functions run build
firebase deploy --only functions
```

## 6. Git Commit

### Commit Message Format
```bash
git add .
git commit -m "type: brief description

- Detailed change 1
- Detailed change 2

Addresses Story X.Y or fixes #issue-number"
```

**Types**: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

### Pre-Commit Verification
- [ ] All tests passing
- [ ] SwiftLint passing
- [ ] No debug print statements left in code
- [ ] No commented-out code blocks

## 7. Documentation Updates

### README.md
- [ ] Update if new setup steps required
- [ ] Update if new dependencies added

### Code Documentation
- [ ] Story documentation updated (if feature work)
- [ ] Epic documentation updated (if significant milestone)

## 8. Verification in ALL Running Instances

**CRITICAL**: When changes require rebuild:
- [ ] Rebuild all running simulator instances (use parallel `build_run_sim`)
- [ ] Verify changes in each instance
- [ ] Test across different device types if UI changes

## Quick Checklist (Minimal)

For small changes:
1. [ ] SwiftLint passes
2. [ ] File under 500 lines
3. [ ] Build succeeds
4. [ ] Tests pass (if applicable)
5. [ ] Rebuild all running simulators
6. [ ] Commit with clear message
