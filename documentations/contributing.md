# Contributing

Thank you for considering contributing to macOS Window Toolkit! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)
- [Testing](#testing)
- [Coding Standards](#coding-standards)
- [Documentation](#documentation)
- [Pull Request Process](#pull-request-process)
- [Release Process](#release-process)

## Code of Conduct

This project adheres to a code of conduct adapted from the [Contributor Covenant](https://www.contributor-covenant.org/). By participating, you are expected to uphold this code.

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, education, socioeconomic status, nationality, personal appearance, race, religion, or sexual identity and orientation.

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check the [issue tracker](https://github.com/kihyun/macos_window_toolkit/issues) to see if the issue already exists. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples to demonstrate the steps**
- **Describe the behavior you observed after following the steps**
- **Explain which behavior you expected to see instead and why**
- **Include screenshots if applicable**
- **Include system information**: macOS version, Flutter version, plugin version

#### Bug Report Template

```markdown
## Bug Description
A clear and concise description of what the bug is.

## Steps to Reproduce
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

## Expected Behavior
A clear and concise description of what you expected to happen.

## Screenshots
If applicable, add screenshots to help explain your problem.

## Environment
- macOS version: [e.g. 12.0]
- Flutter version: [e.g. 3.3.0]
- Plugin version: [e.g. 1.0.0]
- Dart version: [e.g. 3.8.1]

## Additional Context
Add any other context about the problem here.
```

### Suggesting Features

Feature requests are welcome! Please provide:

- **Use a clear and descriptive title**
- **Provide a step-by-step description of the suggested feature**
- **Provide specific examples to demonstrate the feature**
- **Explain why this feature would be useful**
- **Consider the scope and impact of the change**

### Contributing Code

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes**
4. **Add tests** for your changes
5. **Ensure tests pass**
6. **Update documentation** as needed
7. **Commit your changes** (`git commit -m 'Add amazing feature'`)
8. **Push to the branch** (`git push origin feature/amazing-feature`)
9. **Open a Pull Request**

## Development Setup

### Prerequisites

- macOS 10.11 or later
- Xcode with Swift 5.0 support
- Flutter 3.3.0 or later
- Dart 3.8.1 or later
- Git

### Setting up the Development Environment

1. **Clone the repository:**
   ```bash
   git clone https://github.com/kihyun/macos_window_toolkit.git
   cd macos_window_toolkit
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Set up the example app:**
   ```bash
   cd example
   flutter pub get
   ```

4. **Run the example app:**
   ```bash
   flutter run -d macos
   ```

5. **Verify your setup:**
   ```bash
   flutter test
   cd example
   flutter test integration_test/
   ```

### IDE Setup

#### VS Code
Recommended extensions:
- Flutter
- Dart
- GitLens
- Swift

#### Android Studio/IntelliJ
- Flutter plugin
- Dart plugin

## Project Structure

Understanding the project structure is essential for effective contributions:

```
macos_window_toolkit/
├── lib/                                    # Flutter Dart code
│   ├── macos_window_toolkit.dart          # Main export file
│   └── src/
│       ├── macos_window_toolkit.dart      # Main API class
│       ├── macos_window_toolkit_platform_interface.dart
│       └── macos_window_toolkit_method_channel.dart
├── macos/                                  # macOS native implementation
│   ├── Classes/
│   │   ├── MacosWindowToolkitPlugin.swift
│   │   └── WindowHandler.swift
│   └── macos_window_toolkit.podspec
├── example/                               # Example Flutter app
├── test/                                  # Unit tests
├── docs/                                  # Documentation
└── CONTRIBUTING.md                        # This file
```

### Key Files

- **`lib/src/macos_window_toolkit.dart`**: Main API implementation
- **`macos/Classes/WindowHandler.swift`**: Core window management logic
- **`macos/Classes/MacosWindowToolkitPlugin.swift`**: Flutter plugin integration
- **`example/lib/main.dart`**: Example application
- **`test/macos_window_toolkit_test.dart`**: Unit tests

## Development Workflow

### Branch Naming

- Feature branches: `feature/description-of-feature`
- Bug fixes: `bugfix/description-of-bug`
- Documentation: `docs/description-of-change`
- Hot fixes: `hotfix/description-of-fix`

### Commit Message Guidelines

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that don't affect the meaning of the code
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `test`: Adding missing tests or correcting existing tests
- `chore`: Changes to the build process or auxiliary tools

**Examples:**
```bash
feat: add window screenshot capture functionality
fix: handle windows with empty titles correctly
docs: update API reference with new methods
test: add integration tests for error handling
```

## Testing

### Running Tests

```bash
# Unit tests
flutter test

# Integration tests (requires macOS with UI)
cd example
flutter test integration_test/

# Example app tests
cd example
flutter test
```

### Test Coverage

Aim for high test coverage, especially for:
- Core API functionality
- Error handling
- Edge cases
- Platform-specific behavior

### Writing Tests

#### Unit Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

void main() {
  group('MacosWindowToolkit', () {
    test('should return list of windows', () async {
      // Test implementation
    });
  });
}
```

#### Integration Tests

```dart
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('window enumeration integration test', (tester) async {
    // Integration test implementation
  });
}
```

## Coding Standards

### Dart Code Style

Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style):

- Use `flutter_lints` for code analysis
- Format code with `dart format`
- Use meaningful variable and function names
- Add documentation comments for public APIs
- Keep functions small and focused

#### Example:

```dart
/// Retrieves information about all open windows on the macOS system.
///
/// Returns a [Future] that completes with a [List] of [WindowInfo] objects
/// representing all currently open windows.
///
/// Throws a [PlatformException] if the operation fails.
Future<List<WindowInfo>> getAllWindows() async {
  // Implementation
}
```

### Swift Code Style

Follow Swift conventions:

- Use camelCase for variables and functions
- Use PascalCase for types
- Use descriptive names
- Add documentation comments
- Handle errors appropriately

#### Example:

```swift
/// Retrieves information about all windows using Core Graphics APIs
/// - Returns: Array of window information dictionaries
/// - Throws: WindowError if the operation fails
public func getAllWindows() throws -> [[String: Any]] {
    // Implementation
}
```

### Code Formatting

```bash
# Format Dart code
dart format lib/ test/ example/lib/ example/test/

# Analyze Dart code
flutter analyze

# Check Swift code formatting in Xcode or with SwiftFormat
```

## Documentation

### API Documentation

- Document all public classes, methods, and properties
- Use dartdoc conventions
- Include usage examples
- Specify parameter types and return values
- Document thrown exceptions

### Updating Documentation

When making changes that affect the public API:

1. Update inline code documentation
2. Update relevant files in `docs/`
3. Update the main `README.md` if necessary
4. Update `CHANGELOG.md` with your changes

### Documentation Structure

- `README.md`: Main project documentation
- `docs/getting_started.md`: Basic usage guide
- `docs/api_reference.md`: Complete API documentation
- `docs/advanced_usage.md`: Advanced patterns and techniques
- `docs/examples.md`: Code examples
- `docs/troubleshooting.md`: Common issues and solutions

## Pull Request Process

### Before Submitting

1. **Ensure your code follows the coding standards**
2. **Add or update tests** for your changes
3. **Update documentation** as needed
4. **Run all tests** and ensure they pass
5. **Update CHANGELOG.md** if applicable
6. **Rebase your branch** on the latest main branch

### Pull Request Template

```markdown
## Description
Brief description of the changes.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] New tests added for new functionality

## Checklist
- [ ] Code follows the project's coding standards
- [ ] Self-review of the code has been performed
- [ ] Code is commented, particularly in hard-to-understand areas
- [ ] Documentation has been updated
- [ ] Changes have been added to CHANGELOG.md
```

### Review Process

1. **Automated checks** must pass (CI/CD pipeline)
2. **At least one maintainer** must approve the PR
3. **All conversations** must be resolved
4. **Branch must be up to date** with main

## Release Process

### Versioning

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** version: Incompatible API changes
- **MINOR** version: Backwards-compatible functionality additions
- **PATCH** version: Backwards-compatible bug fixes

### Release Checklist

1. Update version in `pubspec.yaml`
2. Update `CHANGELOG.md`
3. Update documentation if needed
4. Create and test release candidate
5. Create GitHub release
6. Publish to pub.dev
7. Announce release

### Maintaining Compatibility

- Avoid breaking changes in minor/patch releases
- Deprecate features before removing them
- Provide migration guides for breaking changes
- Support older Flutter/Dart versions when possible

## Getting Help

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and discussions
- **Code Reviews**: Feedback on pull requests

### Maintainer Response

- Issues are typically reviewed within 1-2 weeks
- Pull requests are typically reviewed within 1 week
- Critical bugs are prioritized for faster response

### Recognition

Contributors are recognized through:
- GitHub contributor lists
- Release notes acknowledgments
- Special thanks in major releases

Thank you for contributing to macOS Window Toolkit! Your efforts help make this plugin better for the entire Flutter community.