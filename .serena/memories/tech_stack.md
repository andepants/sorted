# Tech Stack

## Platform
- **iOS**: 17+ (minimum target)
- **Language**: Swift 6 (strict concurrency enabled)
- **UI Framework**: SwiftUI

## Concurrency & Architecture
- **Concurrency**: Swift Concurrency (async/await, actors)
- **UI Threading**: `@MainActor` for all UI code
- **Pattern**: Protocol-oriented programming, prefer structs over classes

## Networking & Backend
- **Networking**: URLSession (native only, no third-party libraries)
- **Backend**: Firebase
  - Auth (Email/Password authentication)
  - Firestore (real-time database)
  - Cloud Functions (Node.js 20)
  - Storage (media attachments)
  - FCM (push notifications)

## Storage & Persistence
- **Local Storage**: SwiftData for offline messages and conversations
- **Secure Storage**: Keychain for auth tokens
- **Offline-First**: Background sync with SyncCoordinator

## AI Integration
- **AI Models**: OpenAI GPT-4
- **RAG**: Supermemory RAG for FAQ detection

## Package Management
- **SPM**: Swift Package Manager (integrated with Xcode)
- **Firebase iOS SDK**: Managed via SPM
- **Other Dependencies**: Kingfisher (image caching)

## Development Tools
- **IDE**: Xcode 15.0+
- **macOS**: 14.0+ (Sonoma or later)
- **Linting**: SwiftLint
- **Firebase CLI**: Node.js 18+ required
