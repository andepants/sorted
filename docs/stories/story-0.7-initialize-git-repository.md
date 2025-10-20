---
# Story 0.7: Initialize Git Repository

id: STORY-0.7
title: "Initialize Git Repository with .gitignore and Initial Commit"
epic: "Epic 0: Project Scaffolding & Development Environment Setup"
status: draft
priority: P0
estimate: 1
assigned_to: null
created_date: "2025-10-20"
sprint_day: 0

---

## Description

**As a** developer
**I need** version control set up for the project with proper .gitignore
**So that** I can track changes, collaborate with team members, and maintain project history

This story initializes a Git repository for the Sorted project, creates a comprehensive .gitignore file to exclude build artifacts and sensitive files, and creates an initial commit with the complete project scaffolding.

**Note:** Git repository has already been initialized. This story focuses on creating .gitignore and making the initial commit.

---

## Acceptance Criteria

**This story is complete when:**

- [ ] Git repository initialized (if not already done)
- [ ] Comprehensive .gitignore created for Xcode, Swift, Firebase, and SPM
- [ ] All project files staged for initial commit
- [ ] Initial commit created with descriptive message
- [ ] Remote repository linked (GitHub/GitLab) if available
- [ ] Commit includes all scaffolding work from Stories 0.1-0.6

---

## Technical Tasks

**Implementation steps:**

1. **Verify Git Repository**
   - Check if git is already initialized:
     ```bash
     git status
     ```
   - If not initialized, run:
     ```bash
     git init
     ```

2. **Create Comprehensive .gitignore**
   - Create `.gitignore` file in project root
   - Include patterns for:
     - Xcode build artifacts
     - Swift Package Manager
     - Firebase (note: GoogleService-Info.plist should be ignored in production)
     - macOS system files
     - Secrets and environment variables
   - See code examples below for complete .gitignore

3. **Stage All Files**
   - Stage all project files:
     ```bash
     git add .
     ```
   - Verify staged files:
     ```bash
     git status
     ```
   - Ensure sensitive files are NOT staged (check .gitignore)

4. **Create Initial Commit**
   - Create commit with comprehensive message:
     ```bash
     git commit -m "feat: initial project setup with BMAD framework and development tooling

     This commit includes the complete project scaffolding for Sorted:

     Epic 0 Completion:
     - ✅ STORY-0.1: Xcode project initialized (Swift 6, iOS 17+, SwiftUI)
     - ✅ STORY-0.2: SPM dependencies installed (Firebase SDK, Kingfisher)
     - ✅ STORY-0.3: Firebase backend configured (Auth, Firestore, Storage, FCM)
     - ✅ STORY-0.4: SwiftData ModelContainer with 5 core entities
     - ✅ STORY-0.5: Feature-based project structure created
     - ✅ STORY-0.6: Firebase Emulators configured (optional)
     - ✅ STORY-0.7: Git repository initialized

     Project Structure:
     - App entry point with Firebase and SwiftData initialization
     - Feature folders: Auth, Chat, AI, Settings
     - Core modules: Models, Services, Networking, Theme, Utilities
     - SwiftData entities: Message, Conversation, User, Attachment, FAQ

     Tech Stack:
     - Swift 6 with strict concurrency
     - SwiftUI (iOS 17+)
     - Firebase (Auth, Firestore, Storage, FCM, Analytics, Crashlytics)
     - SwiftData (local persistence with offline queue)
     - Kingfisher (image caching)

     Development Environment:
     - Xcode 15.0+ project configuration
     - Build configurations: Development, Staging, Production
     - Firebase Emulators for local development
     - README.md with setup instructions

     🤖 Generated with [Claude Code](https://claude.com/claude-code)

     Co-Authored-By: Claude <noreply@anthropic.com>"
     ```

5. **Link Remote Repository** (if available)
   - Add remote origin:
     ```bash
     git remote add origin <repository-url>
     ```
   - Verify remote:
     ```bash
     git remote -v
     ```

6. **Push Initial Commit** (if remote is set up)
   - Push to main branch:
     ```bash
     git push -u origin main
     ```
   - OR if using 'master' branch:
     ```bash
     git push -u origin master
     ```

7. **Verify Commit**
   - Check git log:
     ```bash
     git log --oneline
     ```
   - Verify commit message is complete
   - Check remote repository (if pushed)

---

## Technical Specifications

### Files to Create

```
Project Root/
└── .gitignore (create)
```

### Complete .gitignore File

```gitignore
# Xcode
#
# gitignore contributors: remember to update Global/Xcode.gitignore, Objective-C.gitignore & Swift.gitignore

## User settings
xcuserdata/

## Compatibility with Xcode 8 and earlier (ignoring not required starting Xcode 9)
*.xcscmblueprint
*.xccheckout

## Compatibility with Xcode 3 and earlier (ignoring not required starting Xcode 4)
build/
DerivedData/
*.moved-aside
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3

## Xcode Patch
*.xcodeproj/*
!*.xcodeproj/project.pbxproj
!*.xcodeproj/xcshareddata/
!*.xcworkspace/contents.xcworkspacedata
**/xcshareddata/WorkspaceSettings.xcsettings

## Obj-C/Swift specific
*.hmap

## App packaging
*.ipa
*.dSYM.zip
*.dSYM

## Playgrounds
timeline.xctimeline
playground.xcworkspace

# Swift Package Manager
#
# Add this line if you want to avoid checking in source code from Swift Package Manager dependencies.
Packages/
Package.pins
Package.resolved
*.xcodeproj
# Xcode automatically generates this directory with a .xcworkspacedata file and xcuserdata
# hence it is not needed unless you have added a package configuration file to your project
.swiftpm

.build/

# CocoaPods
#
# We recommend against adding the Pods directory to your .gitignore. However
# you should judge for yourself, the pros and cons are mentioned at:
# https://guides.cocoapods.org/using/using-cocoapods.html#should-i-check-the-pods-directory-into-source-control
#
# Pods/
#
# Add this line if you want to avoid checking in source code from the Xcode workspace
# *.xcworkspace

# Carthage
#
# Add this line if you want to avoid checking in source code from Carthage dependencies.
# Carthage/Checkouts

Carthage/Build/

# Accio dependency management
Dependencies/
.accio/

# fastlane
#
# It is recommended to not store the screenshots in the git repo.
# Instead, use fastlane to re-generate the screenshots whenever they are needed.
# For more information about the recommended setup visit:
# https://docs.fastlane.tools/best-practices/source-control/#source-control

fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output

# Code Injection
#
# After new code Injection tools there's a generated folder /iOSInjectionProject
# https://github.com/johnno1962/injectionforxcode

iOSInjectionProject/

# Firebase
#
# Uncomment the next line if you want to ignore GoogleService-Info.plist
# For open source projects, it's generally safe to commit this file
# For private projects with multiple environments, you may want to ignore it
# GoogleService-Info.plist
.firebase/
firebase-debug.log
firestore-debug.log
ui-debug.log
firebase-data/

# Environment Variables & Secrets
.env
.env.local
.env.*.local
secrets.json
service-account.json

# macOS
.DS_Store
.AppleDouble
.LSOverride

# Thumbnails
._*

# Files that might appear in the root of a volume
.DocumentRevisions-V100
.fseventsd
.Spotlight-V100
.TemporaryItems
.Trashes
.VolumeIcon.icns
.com.apple.timemachine.donotpresent

# Directories potentially created on remote AFP share
.AppleDB
.AppleDesktop
Network Trash Folder
Temporary Items
.apdisk

# IDEs
.vscode/
.idea/
*.swp
*.swo
*~

# Debug logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# BMAD (optional - if you want to ignore BMAD-generated files)
# .bmad-core/
# .claude/
```

### Commit Message Format

Follow Conventional Commits format:
```
<type>: <short description>

<detailed description>

<footer with metadata>
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only
- `refactor:` - Code restructuring
- `test:` - Adding tests
- `chore:` - Maintenance tasks

### Dependencies

**Required:**
- All Stories 0.1-0.6 complete
- Git installed (comes with Xcode)

**Blocks:**
- None (final story in Epic 0)

**External:**
- GitHub/GitLab account (if pushing to remote)

---

## Testing & Validation

### Test Procedure

1. **.gitignore Verification**
   - Open `.gitignore` file
   - Verify all patterns are present
   - Check that important files are NOT ignored:
     - ✅ Source code (.swift files)
     - ✅ Project file (.xcodeproj/project.pbxproj)
     - ✅ GoogleService-Info.plist (if you want to commit it)
     - ✅ README.md

2. **Staging Verification**
   ```bash
   git status
   ```
   - Verify correct files are staged
   - Check that ignored files don't appear (e.g., build/, DerivedData/)

3. **Commit Verification**
   ```bash
   git log --stat
   ```
   - Verify commit message is complete
   - Check files included in commit
   - Ensure all Epic 0 work is committed

4. **Remote Push Verification** (if applicable)
   ```bash
   git remote -v
   git log --oneline
   ```
   - Verify remote is configured
   - Check that commit appears on remote repository

5. **Clone Test** (Optional but Recommended)
   - Clone repository to new location:
     ```bash
     git clone <repository-url> test-clone
     cd test-clone
     ```
   - Open in Xcode
   - Verify project builds successfully
   - This confirms all necessary files were committed

### Success Criteria

- [ ] Git repository initialized successfully
- [ ] .gitignore file created with comprehensive patterns
- [ ] Initial commit created with all Epic 0 work
- [ ] Commit message is descriptive and follows conventions
- [ ] No sensitive files committed (secrets, build artifacts)
- [ ] Remote repository linked (if applicable)
- [ ] Commit pushed to remote (if applicable)
- [ ] Fresh clone builds successfully

---

## References

**Git Best Practices:**
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub .gitignore templates](https://github.com/github/gitignore)

**Epic:**
- [Epic 0: Project Scaffolding](../epics/epic-0-project-scaffolding.md#story-07-initialize-git-repository)

**Related Stories:**
- All Stories 0.1-0.6 (dependencies)

---

## Notes & Considerations

### Implementation Notes

- Git repository was already initialized in earlier work
- Focus is on creating .gitignore and comprehensive initial commit
- Commit message should summarize ALL Epic 0 work
- GoogleService-Info.plist: Safe to commit for open source, consider ignoring for private repos
- Use descriptive commit messages to maintain clear project history

### Edge Cases

- **Already Committed Files**: If you've already made commits, this will be an additional commit
  - That's OK - focus on ensuring .gitignore is correct going forward
- **Large Files**: If accidentally committed large files (e.g., build artifacts):
  - Use `git rm --cached <file>` to unstage
  - Add to .gitignore
  - Commit removal

### Performance Considerations

- .gitignore patterns are evaluated on every git operation
- Keep patterns simple and specific for best performance
- Ignoring build/ and DerivedData/ significantly reduces repository size

### Security Considerations

- **NEVER commit:**
  - Service account JSON files
  - API keys in .env files
  - Private certificates or signing keys
- **Safe to commit:**
  - GoogleService-Info.plist (contains only client-side API keys)
  - firebase.json (emulator configuration)
  - Package.resolved (dependency versions)
- **Consider ignoring for private repos:**
  - GoogleService-Info.plist (to support multiple environments)

---

## Metadata

**Created by:** SM Agent (Bob)
**Created date:** 2025-10-20
**Last updated:** 2025-10-20
**Sprint:** Day 0 of 7-day sprint
**Epic:** Epic 0: Project Scaffolding
**Story points:** 1
**Priority:** P0 (Blocker)

---

## Story Lifecycle

- [x] **Draft** - Story created, needs review
- [ ] **Ready** - Story reviewed and ready for development
- [ ] **In Progress** - Developer working on story
- [ ] **Blocked** - Story blocked by dependency or issue
- [ ] **Review** - Implementation complete, needs QA review
- [ ] **Done** - Story complete and validated

**Current Status:** Draft
