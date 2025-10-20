---
# Story 0.3: Set Up Firebase Backend

id: STORY-0.3
title: "Set Up Firebase Backend (Auth, Firestore, Storage, FCM)"
epic: "Epic 0: Project Scaffolding & Development Environment Setup"
status: draft
priority: P0
estimate: 3
assigned_to: null
created_date: "2025-10-20"
sprint_day: 0

---

## Description

**As a** developer
**I need** Firebase backend services configured (Authentication, Firestore, Storage, Cloud Messaging)
**So that** I can use backend services for user authentication, real-time database, file storage, and push notifications

This story sets up the complete Firebase backend infrastructure for Sorted, including creating the Firebase project, configuring all required services, downloading configuration files, and initializing Firebase in the iOS app.

---

## Acceptance Criteria

**This story is complete when:**

- [ ] Firebase project created with name `sorted-dev`
- [ ] iOS app registered in Firebase with bundle ID `com.sorted.app.dev`
- [ ] GoogleService-Info.plist downloaded and added to Xcode project
- [ ] Firebase initialized in SortedApp.swift
- [ ] Firestore database created in test mode
- [ ] Firebase Storage bucket created with default rules
- [ ] Firebase Authentication enabled (Email/Password provider)
- [ ] Firebase Cloud Messaging configured
- [ ] App builds and initializes Firebase without errors (verified in console logs)

---

## Technical Tasks

**Implementation steps:**

1. **Create Firebase Project**
   - Go to https://console.firebase.google.com
   - Click "Add project"
   - Project name: `sorted-dev`
   - Disable Google Analytics for now (can enable later)
   - Click "Create project"
   - Wait for project provisioning to complete

2. **Register iOS App**
   - In Firebase Console, click "Add app" → iOS
   - Bundle ID: `com.sorted.app.dev` (must match Xcode project)
   - App nickname: `Sorted iOS Dev`
   - Skip App Store ID (will add later)
   - Click "Register app"

3. **Download GoogleService-Info.plist**
   - Download `GoogleService-Info.plist` from Firebase Console
   - Add file to Xcode project:
     - Drag file into `Sorted/Resources/` folder
     - **CRITICAL**: Check "Copy items if needed"
     - **CRITICAL**: Ensure file is added to Sorted target
     - Verify file appears in Project Navigator

4. **Initialize Firebase in App**
   - Open `SortedApp.swift`
   - Import Firebase at top of file
   - Add Firebase initialization in `init()`:
     ```swift
     init() {
         FirebaseApp.configure()
     }
     ```
   - Build and run to verify initialization (check console for Firebase logs)

5. **Enable Firebase Authentication**
   - In Firebase Console: Build → Authentication → Get started
   - Go to "Sign-in method" tab
   - Enable "Email/Password" provider
   - Leave "Email link (passwordless sign-in)" disabled for now
   - Save changes

6. **Create Firestore Database**
   - In Firebase Console: Build → Firestore Database → Create database
   - Location: `us-central` (or closest to target users)
   - Start in **Test Mode** (for development)
     - Note: Will secure with rules in Day 1
   - Click "Enable"
   - Wait for database provisioning

7. **Create Storage Bucket**
   - In Firebase Console: Build → Storage → Get started
   - Start in **Test Mode** (for development)
     - Note: Will secure with rules in Day 1
   - Default location: `us-central` (same as Firestore)
   - Click "Done"
   - Bucket URL will be: `gs://sorted-dev.appspot.com`

8. **Enable Cloud Messaging**
   - In Firebase Console: Build → Cloud Messaging
   - Note: APNs certificate upload can be deferred to Day 1
   - For now, just verify Cloud Messaging is enabled

9. **Enable Analytics & Crashlytics** (Optional but Recommended)
   - In Firebase Console: Build → Analytics
   - Enable Analytics
   - In Firebase Console: Build → Crashlytics
   - Enable Crashlytics
   - Note: These will start collecting data once app is deployed

---

## Technical Specifications

### Files to Create/Modify

```
Sorted/
├── Resources/
│   └── GoogleService-Info.plist (add - downloaded from Firebase)
└── SortedApp.swift (modify - initialize Firebase)
```

### Firebase Configuration

**Project Details:**
- Project ID: `sorted-dev`
- Project Name: `sorted-dev`
- Bundle ID: `com.sorted.app.dev`
- Storage Bucket: `sorted-dev.appspot.com`

**Enabled Services:**
- Authentication (Email/Password)
- Firestore Database (Test Mode)
- Cloud Storage (Test Mode)
- Cloud Messaging
- Analytics (Optional)
- Crashlytics (Optional)

### Code Examples

**SortedApp.swift (with Firebase initialization):**
```swift
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import FirebaseStorage

@main
struct SortedApp: App {

    // MARK: - Initialization

    init() {
        // Initialize Firebase
        FirebaseApp.configure()

        print("✅ Firebase initialized successfully")
        print("   Project ID: \(FirebaseApp.app()?.options.projectID ?? "unknown")")
        print("   Bundle ID: \(FirebaseApp.app()?.options.bundleID ?? "unknown")")
    }

    // MARK: - App Body

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Firestore Security Rules (Test Mode - Initial):**
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2025, 11, 1);
    }
  }
}
```

**Storage Security Rules (Test Mode - Initial):**
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.time < timestamp.date(2025, 11, 1);
    }
  }
}
```

### Dependencies

**Required:**
- STORY-0.1 (Xcode Project) complete
- STORY-0.2 (SPM Dependencies) complete
- Firebase account (free tier OK)
- Google account

**Blocks:**
- STORY-0.4 (Configure SwiftData)
- All Day 1 stories (authentication, chat, etc.)

**External:**
- Firebase Console access
- Internet connection

---

## Testing & Validation

### Test Procedure

1. **Firebase Console Verification**
   - Open Firebase Console at https://console.firebase.google.com
   - Verify project `sorted-dev` exists
   - Check each service is enabled:
     - Authentication → Email/Password enabled
     - Firestore → Database created
     - Storage → Bucket created
     - Cloud Messaging → Enabled

2. **GoogleService-Info.plist Verification**
   - In Xcode Project Navigator, locate GoogleService-Info.plist
   - Click file and verify it's in Sorted target (Target Membership checked)
   - Open file and verify Bundle ID matches: `com.sorted.app.dev`

3. **Firebase Initialization Test**
   - Clean build (⇧⌘K)
   - Run app on simulator (⌘R)
   - Check Xcode console output for Firebase logs:
     ```
     ✅ Firebase initialized successfully
        Project ID: sorted-dev
        Bundle ID: com.sorted.app.dev
     ```
   - Verify no Firebase errors in console

4. **Service Connectivity Test**
   - In SortedApp.swift, add test code in init():
     ```swift
     // Test Firestore connectivity
     let db = Firestore.firestore()
     print("✅ Firestore connected: \(db.app.name)")

     // Test Auth connectivity
     let auth = Auth.auth()
     print("✅ Auth connected: \(auth.app?.name ?? "unknown")")

     // Test Storage connectivity
     let storage = Storage.storage()
     print("✅ Storage connected: \(storage.app.name)")
     ```
   - Run app and verify all services print successfully

### Success Criteria

- [ ] Firebase project visible in Firebase Console
- [ ] All required services enabled and configured
- [ ] GoogleService-Info.plist correctly added to Xcode project
- [ ] App builds without Firebase-related errors
- [ ] Console logs show successful Firebase initialization
- [ ] Console logs show successful connection to Firestore, Auth, and Storage
- [ ] No error messages in Xcode console related to Firebase

---

## References

**Architecture Docs:**
- [Technology Stack](../architecture/technology-stack.md#22-backend-services)
- [System Architecture](../architecture/system-architecture.md)

**PRD Sections:**
- Not applicable (scaffolding story)

**Implementation Guides:**
- Firebase iOS Setup: https://firebase.google.com/docs/ios/setup

**Epic:**
- [Epic 0: Project Scaffolding](../epics/epic-0-project-scaffolding.md#story-03-set-up-firebase-backend)

**Related Stories:**
- STORY-0.1: Initialize Xcode Project (prerequisite)
- STORY-0.2: Install SPM Dependencies (prerequisite)
- STORY-0.4: Configure SwiftData (blocked by this)

---

## Notes & Considerations

### Implementation Notes

- **CRITICAL**: GoogleService-Info.plist MUST be added to the Xcode target
  - Verify by clicking file → File Inspector → Target Membership
- Use test mode for Firestore and Storage during development
  - Will add security rules in Day 1 stories
- APNs certificate for push notifications can be deferred to Day 1
- Firebase initialization should happen in `init()`, before SwiftUI body is rendered

### Edge Cases

- **Missing GoogleService-Info.plist**: App will crash with error
  - Solution: Verify file is in project and added to target
- **Wrong Bundle ID**: Firebase won't initialize correctly
  - Solution: Ensure Bundle ID in Xcode matches Firebase Console
- **Firestore Region Mismatch**: Can't change region after creation
  - Choose closest region to target users upfront

### Performance Considerations

- Firebase initialization is fast (~100ms) - no noticeable impact on app launch
- Firestore and Storage are lazy-loaded - no overhead until first use
- Consider using Firebase Emulators for faster local development (Story 0.6)

### Security Considerations

- **Test Mode Rules**: Allow unrestricted access - ONLY for development
  - Must replace with proper security rules before production
  - Set expiration date to 30 days from now
- **GoogleService-Info.plist**: Contains API keys - but these are OK to commit
  - Firebase API keys are safe to expose (Firebase security is server-side)
  - Do NOT commit service account JSON files (those are private keys)

---

## Metadata

**Created by:** SM Agent (Bob)
**Created date:** 2025-10-20
**Last updated:** 2025-10-20
**Sprint:** Day 0 of 7-day sprint
**Epic:** Epic 0: Project Scaffolding
**Story points:** 3
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
