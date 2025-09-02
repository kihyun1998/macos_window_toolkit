## 1.2.0

### Added
- **FEAT**: App Store integration - `openAppStoreSearch(String searchTerm)` method
- **FEAT**: ApplicationHandler.swift for dedicated application operations  
- **FEAT**: Example app integration with App Store search buttons when apps not found

### Changed
- **REFACTOR**: Moved application logic from WindowHandler to ApplicationHandler

## 1.1.6

### Added
- **FEAT**: Application Discovery API
  - `getAllInstalledApplications()` method to retrieve all installed applications
  - `getApplicationByName(String name)` method for case-insensitive application search
  - `MacosApplicationInfo` model class with name, bundleId, version, path, and iconPath properties
  - `ApplicationResult` sealed class with `ApplicationSuccess`/`ApplicationFailure` states for type-safe error handling
  - Comprehensive search across multiple system directories (/Applications, /System/Applications, etc.)
- **FEAT**: Type-safe application metadata access with structured error handling and user-friendly failure messages

## 1.1.5

### Added
- **DOCS**: Comprehensive API Reference restructure with modular documentation
- **DOCS**: Complete API documentation for all 27 methods and properties
- **DOCS**: New modular documentation structure in `documentations/api/`:
  - `window_management.md` - Window discovery, filtering, and management (7 methods)
  - `permission_management.md` - Permission handling and real-time monitoring (10 methods/properties)
  - `window_capture.md` - ScreenCaptureKit and legacy capture methods (6 methods)
  - `process_management.md` - Application process control and management (3 methods)
  - `system_info.md` - macOS version detection and capabilities (2 methods)
  - `error_handling.md` - Exception codes and error patterns reference
- **DOCS**: Updated main `api_reference.md` as comprehensive index with navigation
- **DOCS**: Added practical examples, performance notes, and integration patterns
- **DOCS**: Complete error code reference with resolution strategies

### Changed
- **DOCS**: Restructured API documentation from single file to organized category-based files
- **DOCS**: Enhanced documentation with real-world usage examples and best practices

## 1.1.4

### Added
- Permission error detection for all capture methods (ScreenCaptureKit, Legacy, Smart)
- New error codes: `SCREEN_RECORDING_PERMISSION_DENIED`, `REQUIRES_MACOS_14`, `ACCESSIBILITY_PERMISSION_DENIED`
- Permission error dialogs with direct navigation to settings page
- Automatic permission settings navigation on capture failures

### Fixed
- Capture operations now properly detect Screen Recording permission issues
- Enhanced error messages with actionable user guidance

## 1.1.3

### Added
- **DOCS**: Comprehensive sandbox configuration documentation
- **DOCS**: Detailed explanation of API requirements for sandbox disable (CGWindowListCopyWindowInfo, Accessibility API, Process Control, etc.)
- **DOCS**: App Store distribution guidelines and security considerations

### Changed
- **DOCS**: Enhanced README with sandbox requirements and configuration steps
- **DOCS**: Added new sandbox_configuration.md guide to documentations/

## 1.1.2

- **DOCS**: Update package description for pub.dev search optimization.

## 1.1.1

- **DOCS**: Added new topics to pubspec.yaml to help users find the package more easily.

## 1.1.0

- **FEAT**: Add permission monitoring that automatically checks screen recording and accessibility permissions at configurable intervals.
- **FEAT**: Add PermissionStatus model that provides structured permission data with timestamp and change detection.
- **FEAT**: Add stream-based permission updates that emit when permissions change or at regular intervals.
- **FEAT**: Add manual start/stop controls for permission monitoring.
- **FEAT**: Add support for two monitoring modes: emit only on changes (efficient) or emit regularly (heartbeat).
- **FEAT**: Add timer management that prevents multiple timers from running simultaneously.
- **IMPROVEMENT**: Update example application to demonstrate permission monitoring features.
- **DOCS**: Update documentation with permission monitoring examples and integration patterns.
- **BREAKING**: Export PermissionStatus and PermissionWatcher classes in main library.

## 1.0.0

- **FEAT**: Initial release of macOS Window Toolkit with window enumeration functionality.
- **FEAT**: Add `getAllWindows()` method to retrieve all open window information.
- **FEAT**: Implement comprehensive window data structure with ID, name, owner, bounds, layer, visibility, and process ID.
- **FEAT**: Add native Swift implementation using Core Graphics APIs (`CGWindowListCopyWindowInfo`).
- **FEAT**: Implement Flutter method channel integration for cross-platform communication.
- **FEAT**: Add privacy-compliant implementation with included privacy manifest for App Store distribution.
- **FEAT**: Create comprehensive example application demonstrating all plugin features.
- **FEAT**: Add error handling with proper `PlatformException` types.
- **FEAT**: Support macOS 10.11 and later versions.
- **FEAT**: Implement plugin platform interface pattern for future extensibility.
- **FEAT**: Add memory-efficient window data serialization and proper resource cleanup.
- **DOCS**: Add comprehensive README with installation and usage examples.
- **DOCS**: Create detailed API documentation with parameter specifications.
- **DOCS**: Add advanced usage guide with performance optimization techniques.
- **DOCS**: Create troubleshooting guide for common issues.
- **DOCS**: Add contributing guidelines for developers.
- **TEST**: Add unit tests for method channel functionality.
- **TEST**: Implement integration tests for real system interaction.
- **CHORE**: Add code analysis compliance with `flutter_lints`.
- **CHORE**: Implement performance optimization for large window lists.
- **CHORE**: Add memory leak prevention mechanisms.