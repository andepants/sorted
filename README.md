# Sorted - AI-Powered Messaging App

**Platform:** iOS 17+
**Language:** Swift 6
**UI Framework:** SwiftUI
**Backend:** Firebase (Auth, Firestore, Storage, FCM)
**Local Persistence:** SwiftData
**Timeline:** 7-Day Sprint

---

## Overview

Sorted is an AI-first iOS messaging application that automatically categorizes conversations, generates smart reply drafts, and provides intelligent conversation insights. Built with Swift 6, SwiftUI, and Firebase, featuring offline-first architecture with SwiftData.

## Features

- **Smart Categorization**: AI categorizes messages (Fan, Business, Spam, Urgent)
- **Smart Replies**: AI-generated reply drafts for quick responses
- **FAQ Auto-Responder**: Detects FAQs and suggests pre-written answers
- **Offline-First**: Full offline support with background sync
- **Real-Time Messaging**: Firebase Firestore for instant message delivery
- **Media Attachments**: Send images, videos, and files

## Tech Stack

- **iOS**: Swift 6, SwiftUI (iOS 17+)
- **Concurrency**: Swift Concurrency (async/await, actors)
- **Storage**: SwiftData (local), Keychain (auth tokens)
- **Backend**: Firebase (Firestore, Auth, FCM, Storage)
- **AI**: OpenAI GPT-4, Supermemory RAG
- **Package Manager**: Swift Package Manager (SPM)

## Setup Instructions

### Prerequisites

- Xcode 15.0+ with iOS 17 SDK
- macOS 14.0+ (Sonoma or later)
- Node.js 18+ (for Firebase CLI)
- Firebase account (free tier OK)

### Installation

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd sorted
   ```

2. **Open in Xcode**
   ```bash
   open sorted.xcodeproj
   ```

3. **Resolve SPM Dependencies**
   - Xcode will automatically resolve packages
   - Wait for Firebase iOS SDK and Kingfisher to download

4. **Configure Firebase**
   - Ensure `GoogleService-Info.plist` is in `sorted/Resources/`
   - Verify file is added to Sorted target

5. **Build & Run**
   - Select iOS 17+ Simulator (iPhone 15 Pro recommended)
   - Press ⌘R to build and run

### Firebase Configuration

- **Project ID**: `sorted-dev`
- **Bundle ID**: `com.sorted.app.dev`
- **Services**: Auth (Email/Password), Firestore, Storage, FCM

## Project Structure

```
sorted/
├── App/                  # App entry point and lifecycle
│   ├── SortedApp.swift
│   └── AppDelegate.swift
│
├── Features/             # Feature modules organized by domain
│   ├── Auth/            # Authentication feature
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Services/
│   │
│   ├── Chat/            # Chat/messaging feature
│   │   ├── Views/
│   │   │   └── Components/
│   │   ├── ViewModels/
│   │   └── Repositories/
│   │
│   ├── AI/              # AI features (categorization, smart reply)
│   │   ├── Views/
│   │   │   └── Components/
│   │   ├── ViewModels/
│   │   └── Services/
│   │
│   └── Settings/        # Settings and profile
│       ├── Views/
│       └── ViewModels/
│
├── Core/                # Shared models, services, utilities
│   ├── Models/          # SwiftData models (Message, Conversation, User)
│   ├── Services/        # Shared services
│   ├── Persistence/     # SwiftData and sync logic
│   ├── Networking/      # Firebase and API clients
│   ├── Theme/           # Colors, typography, design tokens
│   └── Utilities/       # Extensions, helpers, constants
│
└── Resources/           # Assets and configuration
    └── Assets.xcassets/
```

## Development Guidelines

### AI-First Codebase Philosophy

This project is architected for maximum AI tool compatibility:

- **Modular Design**: Every file under 500 lines for optimal AI context windows
- **Clear Naming**: Descriptive file and function names
- **Comprehensive Documentation**: Every file has a header explaining its purpose
- **Standard Comments**: All functions documented with `///` Swift doc comments

### Code Standards

- Follow Swift 6 strict concurrency rules
- Use `@MainActor` for UI code
- Keep files under 500 lines (split for AI compatibility)
- Document all public APIs with `///` comments
- Use descriptive variable names (e.g., `isLoading`, `hasError`)

### Swift Naming Conventions

- **Properties/Functions**: `lowerCamelCase`
- **Types**: `UpperCamelCase`
- **Booleans**: Prefix with `is`, `has`, `can`, or `should`

### File Organization

- Use `// MARK: -` to organize code sections
- Extract complex SwiftUI views into separate structs
- Follow feature-based folder structure (not layer-based)
- Maximum 3 levels of folder depth

## Testing

```bash
# Run unit tests
⌘U in Xcode
```

## Deployment

- **Development**: Firebase Emulators (local)
- **Staging**: TestFlight (Firebase staging project)
- **Production**: App Store (Firebase production project)

---

**Created:** 2025-10-20
**Version:** 1.0
**License:** MIT
