---
# Story 0.2: Install Swift Package Manager Dependencies

id: STORY-0.2
title: "Install SPM Dependencies (Firebase SDK, Kingfisher)"
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
**I need** all required Swift Package Manager (SPM) dependencies installed
**So that** I can use Firebase services, image caching, and other third-party libraries during development

This story installs all required dependencies via Swift Package Manager, focusing on the Firebase iOS SDK and Kingfisher for image loading. All packages must resolve without conflicts and the project must build successfully with all dependencies integrated.

---

## Acceptance Criteria

**This story is complete when:**

- [ ] Firebase iOS SDK 10.20+ installed via SPM with all required packages
- [ ] Kingfisher 7.10+ installed via SPM for image caching
- [ ] All packages resolve without version conflicts
- [ ] Project builds successfully with all dependencies
- [ ] Package dependencies are properly imported in code
- [ ] Package.resolved file committed to version control

---

## Technical Tasks

**Implementation steps:**

1. **Add Firebase iOS SDK**
   - In Xcode: File → Add Package Dependencies
   - Enter URL: `https://github.com/firebase/firebase-ios-sdk`
   - Version: 10.20.0 or newer (Up to Next Major Version)
   - Select required Firebase products:
     - FirebaseAuth (Authentication)
     - FirebaseFirestore (Cloud Firestore)
     - FirebaseMessaging (Cloud Messaging / FCM)
     - FirebaseStorage (Cloud Storage)
     - FirebaseAnalytics (Analytics)
     - FirebaseCrashlytics (Crash Reporting)
   - Add to target: Sorted

2. **Add Kingfisher**
   - In Xcode: File → Add Package Dependencies
   - Enter URL: `https://github.com/onevcat/Kingfisher`
   - Version: 7.10.0 or newer (Up to Next Major Version)
   - Add to target: Sorted

3. **Resolve Package Dependencies**
   - Wait for SPM to resolve all packages (may take 2-3 minutes)
   - Verify no version conflicts appear
   - If conflicts occur, check version compatibility and adjust

4. **Verify Integration**
   - Add import statements to SortedApp.swift to test:
     ```swift
     import Firebase
     import FirebaseAuth
     import FirebaseFirestore
     import FirebaseMessaging
     import FirebaseStorage
     import Kingfisher
     ```
   - Build project (⌘B) and verify no import errors

5. **Commit Package.resolved**
   - Ensure Package.resolved is tracked in git
   - This locks package versions for consistent builds across team

---

## Technical Specifications

### Files to Create/Modify

```
Sorted.xcodeproj/
├── project.xcworkspace/
│   └── xcshareddata/
│       └── swiftpm/
│           └── Package.resolved (created by Xcode)
└── Sorted/
    └── SortedApp.swift (modify - add imports)
```

### Package Dependencies

**Firebase iOS SDK (10.20.0+):**
```swift
.package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.20.0")
```

**Products to add:**
- FirebaseAuth
- FirebaseFirestore
- FirebaseMessaging
- FirebaseStorage
- FirebaseAnalytics
- FirebaseCrashlytics

**Kingfisher (7.10.0+):**
```swift
.package(url: "https://github.com/onevcat/Kingfisher", from: "7.10.0")
```

### Code Examples

**SortedApp.swift (with imports):**
```swift
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import FirebaseStorage
import Kingfisher

@main
struct SortedApp: App {
    // Note: Firebase initialization will be added in Story 0.3

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Dependencies

**Required:**
- STORY-0.1 (Xcode Project) must be complete
- Active internet connection for package download
- Xcode 15.0+ with SPM support

**Blocks:**
- STORY-0.3 (Set Up Firebase Backend)
- STORY-0.4 (Configure SwiftData ModelContainer)

**External:**
- Firebase iOS SDK repository availability
- Kingfisher repository availability

---

## Testing & Validation

### Test Procedure

1. **Package Resolution Test**
   - Open Xcode
   - Navigate to File → Packages → Resolve Package Versions
   - Verify: All packages resolve successfully
   - Verify: No version conflict warnings

2. **Build Test**
   - Clean build folder (⇧⌘K)
   - Build project (⌘B)
   - Verify: Build succeeds with no errors
   - Check build log for successful package integration

3. **Import Test**
   - Add import statements to SortedApp.swift (see Code Examples)
   - Build again (⌘B)
   - Verify: No "No such module" errors
   - Verify: Autocomplete works for Firebase and Kingfisher classes

4. **Package.resolved Verification**
   - Check that Package.resolved exists in:
     `Sorted.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/`
   - Open file and verify Firebase and Kingfisher are listed with exact versions

### Success Criteria

- [ ] All SPM packages download and resolve successfully
- [ ] Project builds without errors after adding dependencies
- [ ] Import statements work without "No such module" errors
- [ ] Package.resolved file exists and contains locked versions
- [ ] No version conflicts between dependencies
- [ ] Build time is reasonable (under 5 minutes for first build)

---

## References

**Architecture Docs:**
- [Technology Stack](../architecture/technology-stack.md#24-required-dependencies)

**PRD Sections:**
- Not applicable (scaffolding story)

**Epic:**
- [Epic 0: Project Scaffolding](../epics/epic-0-project-scaffolding.md#story-02-install-swift-package-manager-dependencies)

**Related Stories:**
- STORY-0.1: Initialize Xcode Project (prerequisite)
- STORY-0.3: Set Up Firebase Backend (blocked by this)

---

## Notes & Considerations

### Implementation Notes

- Firebase iOS SDK is large (~300MB) - first download may take several minutes
- Use "Up to Next Major Version" to get latest patch and minor updates
- Package.resolved should be committed to ensure consistent builds across team
- If SPM is slow, try: File → Packages → Reset Package Caches

### Edge Cases

- **Slow Internet**: Package download may timeout - retry or use cellular hotspot
- **Xcode Cache Issues**: Clear derived data if packages fail to resolve:
  ```bash
  rm -rf ~/Library/Developer/Xcode/DerivedData
  ```
- **Version Conflicts**: If conflicts occur, check Firebase's compatibility guide

### Performance Considerations

- First build after adding Firebase will be slow (indexing ~300MB of code)
- Subsequent builds will be faster due to Xcode caching
- Consider using `-Onone` optimization for Debug builds to improve compile time

### Security Considerations

- Always use HTTPS URLs for package repositories
- Pin major versions to avoid breaking changes (e.g., `from: "10.20.0"` not `branch: "main"`)
- Review Package.resolved to ensure no unexpected version changes

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
