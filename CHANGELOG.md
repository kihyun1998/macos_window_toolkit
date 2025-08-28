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