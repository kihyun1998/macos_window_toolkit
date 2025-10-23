## 1.4.10

### Fixed
- **FIX**: Removed unnecessary macOS 10.15 availability checks in SmartCaptureHandler (functions already marked with @available)
- **FIX**: Changed mutable `var` to immutable `let` for `mainValue` constant in WindowHandler

## 1.4.9

### Fixed
- **FIX**: Update minimum macOS version to 10.15 to support async/await in SmartCaptureHandler

## 1.4.8

### Fixed
- **FIX**: Swift compiler warning in `focusWindow()` - changed mutable variable to immutable constant

## 1.4.7

### Fixed
- **FIX**: `focusWindow()` now properly brings windows to front by setting kAXMainAttribute before app activation

## 1.4.6

### Added
- **FEAT**: `focusWindow(int windowId)` method to bring windows to front using Accessibility API

## 1.4.5

### Added
- **FEAT**: Wildcard pattern matching support for `getWindowsAdvanced()` - `nameWildcard` and `ownerNameWildcard` parameters enable `*` (any chars) and `?` (single char) patterns

## 1.4.4

### Changed
- **BREAKING**: `closeWindow()`, `terminateApplicationByPID()`, and `terminateApplicationTree()` now return `WindowOperationResult` instead of `bool`
  - Added `WindowOperationResult` sealed class with `OperationSuccess` and `OperationFailure` variants
  - Consistent with `CaptureResult` pattern used by capture methods
  - Use pattern matching to handle results (see updated examples)

## 1.4.3

### Changed
- **ENHANCEMENT**: Improved error handling for `closeWindow()`, `terminateApplicationByPID()`, and `terminateApplicationTree()`
  - State errors (permission denied, window/process not found) now return structured failure responses instead of throwing exceptions
  - Error handling pattern now consistent with screenshot/capture functions
  - Better error messages with actionable recovery suggestions

## 1.4.2

### Changed
- **REFACTOR**: Example app error handling now uses enum-based approach instead of string comparison
  - Updated window_service.dart, window_detail_sheet.dart, and notification_service.dart to use `PlatformErrorCode` enum
  - Uses `errorCode` extension property and `userMessage` for type-safe error handling
  - Reduced code duplication and improved maintainability
- **DOCS**: Updated documentation examples to demonstrate enum-based error handling
  - Updated error_handling.md, process_management.md, and troubleshooting.md with enum-based patterns
  - Added recommended enum-based examples alongside legacy string-based approaches

## 1.4.1

### Added
- **FEAT**: Add optional `expectedName` parameter to `isWindowAlive()` method for safer window existence verification
  - Prevents false positives when window IDs are reused by the system
  - Verifies both window ID and window name match when `expectedName` is provided
  - Backward compatible - existing code works without changes

## 1.4.0

### Added
- **FEAT**: Window capture resize functionality with aspect ratio control
  - Added `targetWidth` and `targetHeight` parameters to `captureWindow()` for custom output dimensions
  - Added `preserveAspectRatio` parameter to control resize behavior
  - `preserveAspectRatio=true`: Maintains aspect ratio with black letterboxing (resizeImagePreservingAspectRatio)
  - `preserveAspectRatio=false`: Exact size resize that may distort image (resizeImageToExactSize)
  - Resize is applied after titlebar cropping for consistent results
- **FEAT**: String matching options for advanced window filters
  - Added `nameExactMatch` and `nameCaseSensitive` parameters for window title filtering
  - Added `ownerNameExactMatch` and `ownerNameCaseSensitive` parameters for owner name filtering
  - Supports 4 matching modes: exact/contains × case-sensitive/case-insensitive
  - Default behavior: contains match with case sensitivity (backward compatible)
- **FEAT**: Advanced window filtering with `getWindowsAdvanced()` method
  - Supports 14 optional filter parameters: windowId, name, nameExactMatch, nameCaseSensitive, ownerName, ownerNameExactMatch, ownerNameCaseSensitive, processId, isOnScreen, layer, x, y, width, height
  - All parameters are optional and combined with AND logic
  - String filters (name, ownerName) support flexible matching with exact/contains and case-sensitive/insensitive options
  - Numeric filters use exact matching
- **UI**: Advanced filter section in example app with expandable UI and matching option checkboxes for testing new filtering methods

### Changed
- **REFACTOR**: SCStreamConfiguration now captures at original window size with manual resize applied afterward for better control

## 1.3.0

### Added
- **FEAT**: Window role and subrole information using Accessibility API
  - Added `role` property to `MacosWindowInfo` (e.g., "AXWindow", "AXDialog", "AXSheet")
  - Added `subrole` property to `MacosWindowInfo` (e.g., "AXStandardWindow", "AXDialog", "AXFloatingWindow")
  - Enables differentiation between window types similar to Windows Window Class
  - Requires Accessibility permission for full functionality
- **FEAT**: New `getWindowRole()` helper method in WindowHandler.swift for retrieving window role/subrole via Accessibility API
- **UI**: Updated example app to display role and subrole information in window cards and detail sheets

### Changed
- **ENHANCEMENT**: Window information now includes Accessibility API data for better window type identification
- **MODEL**: Extended `MacosWindowInfo` model with optional `role` and `subrole` fields

## 1.2.1

### Changed
- **REFACTOR**: Split platform interface and method channel into modular files by operation type
- **REFACTOR**: Organized code into `platform_interface/` and `method_channel/` directories with separate files for permissions, windows, captures, applications, and system info

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