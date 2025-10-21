# Project Structure

## Xcode Project
- **Project File**: `sorted.xcodeproj`
- **Bundle ID**: `com.sorted.app.dev`
- **Firebase Project ID**: `sorted-dev`

## Directory Layout

```
sorted/
├── App/                      # Application entry point and lifecycle
│   ├── SortedApp.swift       # App entry point (@main)
│   ├── AppDelegate.swift     # Firebase initialization, push notifications
│   ├── RootView.swift        # Root navigation view
│   └── AppContainer.swift    # Dependency injection container
│
├── Features/                 # Feature modules (feature-based architecture)
│   ├── Auth/                 # Authentication feature
│   │   ├── Views/            # Login, SignUp, ForgotPassword views
│   │   ├── ViewModels/       # AuthViewModel
│   │   ├── Services/         # AuthService, DisplayNameService
│   │   └── Models/           # User, AuthError
│   │
│   ├── Chat/                 # Messaging feature
│   │   ├── Views/            # ConversationList, MessageThread, RecipientPicker
│   │   │   └── Components/   # MessageBubble, MessageComposer, TypingIndicator
│   │   ├── ViewModels/       # ConversationViewModel, MessageThreadViewModel
│   │   └── Repositories/     # Data access layer
│   │
│   ├── AI/                   # AI features (categorization, smart replies)
│   │   ├── Views/
│   │   │   └── Components/
│   │   ├── ViewModels/
│   │   └── Services/
│   │
│   └── Settings/             # Settings and profile management
│       ├── Views/            # ProfileView
│       └── ViewModels/
│
├── Core/                     # Shared code across features
│   ├── Models/               # SwiftData entities
│   │   ├── ConversationEntity.swift
│   │   ├── MessageEntity.swift
│   │   ├── UserEntity.swift
│   │   ├── AttachmentEntity.swift
│   │   └── FAQEntity.swift
│   │
│   ├── Services/             # Shared services
│   │   ├── ConversationService.swift
│   │   ├── MessageService.swift
│   │   ├── StorageService.swift
│   │   ├── KeychainService.swift
│   │   ├── NetworkMonitor.swift
│   │   ├── SyncCoordinator.swift
│   │   └── TypingIndicatorService.swift
│   │
│   ├── Utilities/            # Helpers, extensions, validators
│   │   ├── MessageValidator.swift
│   │   └── PreviewContainer.swift
│   │
│   ├── Networking/           # Firebase and API clients
│   ├── Persistence/          # SwiftData and sync logic
│   └── Theme/                # Colors, typography, design tokens
│
└── Resources/                # Assets and configuration files
    ├── Assets.xcassets/      # App icons, images, colors
    └── GoogleService-Info.plist  # Firebase configuration

## Root Configuration Files
- `firebase.json` - Firebase project configuration
- `firestore.rules` - Firestore security rules
- `database.rules.json` - Realtime Database rules
- `storage.rules` - Cloud Storage security rules
- `.swiftlint.yml` - SwiftLint configuration
- `claude.md` - AI agent instructions (CLAUDE.md)
- `README.md` - Project documentation

## Test Directories
- `sortedTests/` - Unit tests
- `sortedUITests/` - UI automation tests (AuthenticationUITests)

## Firebase Functions
- `functions/` - Cloud Functions (Node.js 20)
  - Runtime: nodejs20
  - Predeploy: lint and build
