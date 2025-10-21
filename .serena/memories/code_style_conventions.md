# Code Style & Conventions

## File Organization
- **Maximum File Length**: 500 lines (hard limit for AI compatibility)
- **Documentation**: All files must have header documentation explaining purpose
- **MARK Comments**: Use `// MARK: -` to organize code sections
- **Folder Depth**: Maximum 3 levels of nesting
- **Feature-Based Structure**: Organize by feature, not by layer

## Naming Conventions
- **Types**: `UpperCamelCase` (classes, structs, enums, protocols)
- **Properties/Functions**: `lowerCamelCase`
- **Booleans**: Prefix with `is`, `has`, `can`, or `should`
- **Descriptive Names**: Use full words (e.g., `isLoading`, `hasError`, `canSend`)

## Swift Documentation
- **Public APIs**: Document all public functions/properties with `///` doc comments
- **File Headers**: Include purpose, dependencies, and usage at top of each file
- **Complex Logic**: Add inline comments explaining non-obvious implementations

## Swift 6 Concurrency
- **Always use**: `async/await` pattern (no completion handlers)
- **UI Code**: Mark with `@MainActor` to ensure main thread execution
- **Error Handling**: Throw errors explicitly; avoid silent failures
- **Type Safety**: Leverage Swift's type system for compile-time safety

## SwiftUI Best Practices
- **State Management**:
  - `@State` for view-local state
  - `@StateObject` for view-owned observable objects
  - `@ObservedObject` for objects passed from parent
  - `@EnvironmentObject` for app-wide shared state
- **View Lifecycle**: Use `.task` modifier for async work tied to view lifecycle
- **View Extraction**: Extract complex SwiftUI views into separate structs

## Design Patterns
- **Protocol-Oriented**: Prefer protocols over inheritance
- **Structs over Classes**: Use structs for value types
- **Avoid Duplication**: Prefer iteration and modularization
- **Follow Apple Guidelines**: Adhere to Apple's API Design Guidelines

## SwiftLint Rules
- **Line Length**: Warning at 120, error at 150 characters
- **File Length**: Warning at 400, error at 500 lines
- **Function Length**: Warning at 50, error at 100 lines
- **Cyclomatic Complexity**: Warning at 10, error at 20
- **Enabled Opt-in Rules**: empty_count, empty_string, force_unwrapping, sorted_imports, unused_import
