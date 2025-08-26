
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