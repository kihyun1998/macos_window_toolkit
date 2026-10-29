# Shipping

## What it is
Publishing the package to pub.dev and building it for macOS apps, through Swift Package Manager or CocoaPods: version and constraints, what goes in the archive, the CocoaPods spec and privacy manifest, the changelog, and dependency upkeep.

## Governing decisions
**None.**

## Design model
From reading the files:
- **Version and constraints.** `pubspec.yaml` holds `version: 1.9.0`, `sdk >=3.0.0 <4.0.0` and `flutter >=3.10.0`, with one runtime dependency, `plugin_platform_interface: ^2.0.2`. `flutter.plugin.platforms.macos.pluginClass: MacosWindowToolkitPlugin` must name the Swift class in `MacosWindowToolkitPlugin.swift`.
- **The version string has two hand-kept sites** (`git grep -n '1\.9\.0' -- ':!CHANGELOG.md' ':!example/pubspec.lock'`): `pubspec.yaml` and the README install snippet. CHANGELOG adds a heading per release. Release commits are named `chore: release X.Y.Z` (1888f54).
- **What is published.** `.pubignore` excludes `CLAUDE.md` and `docs/`, so this map and the agent docs are not published. `documentations/`, `cli.md` and `example/` are.
- **Two ways in, one source tree.** `macos/macos_window_toolkit/Package.swift` makes the plugin a Swift package: Flutter treats a plugin as supporting SPM when `macos/<name>/Package.swift` exists (`flutter_tools/lib/src/plugins.dart — supportSwiftPackageManagerForPlatform`, Flutter 3.47.1). Its product is `macos-window-toolkit`, the plugin name with hyphens, which is the name Flutter's generated package depends on (`macos/swift_package_manager.dart`). An app with SPM on (the default on stable since 3.44) builds it as a package and skips the pod; an app with SPM off, or on a Flutter without SPM, builds the pod. Both compile `macos/macos_window_toolkit/Sources/macos_window_toolkit/`; the podspec's `source_files` is `**/*.swift` there (#18).
- **Package platform 10.15, no FlutterFramework dependency** (maintainer, 2026-10-29, #18). Read from the Flutter 3.47.1 source: Flutter's generated package targets `FlutterDarwinPlatform.macos.deploymentTarget()`, 12.0 since 3.47.0 (commit 45a5979476f) and 10.15 before, and SwiftPM rejects a dependency whose minimum is above its dependent's, so `.macOS("12.0")` would break SPM apps on 3.44–3.46. The `../FlutterFramework` package the template depends on exists from 3.44 only. Without it, Flutter prints "missing a dependency on FlutterFramework" when building this plugin's own example, and only there (`darwin_dependency_management.dart — validatePluginSupportsSwiftPackageManager` runs for a plugin's example app). `url_launcher_macos` 3.2.5 has the same shape (10.15, no dependencies). Checked by building the example with SPM on and with `FLUTTER_SWIFT_PACKAGE_MANAGER=false` on Flutter 3.47.1; Flutter 3.24–3.46 were not built.
- **Pod.** `macos/macos_window_toolkit.podspec` sets the platform `osx 10.15` and `swift_version 5.0`. Its version, summary, description, homepage and author are still template placeholders. The `resource_bundles` line for `Resources/PrivacyInfo.xcprivacy` is commented out.
- **No CI.** `.github/` holds only `dependabot.yml`; no workflow runs on a push or a PR.
- **Dependabot** (`.github/dependabot.yml`, maintainer's plan on #5). The root's pub dependencies are checked weekly with `increase-if-necessary`, one PR per dependency. The root has no committed lockfile (`/pubspec.lock` is in `.gitignore`), so a PR opens only when a release falls outside a caret constraint, which raises the floor consumers resolve against. `/example` is checked monthly, every dependency in one grouped PR, since nothing ships from it. PRs get `needs-triage`. There is no `github-actions` entry, because there is no workflow. The file validates against SchemaStore's `dependabot-2.0.json` (ajv, 2026-10-29); whether it runs cleanly shows only on GitHub's Dependabot page.

## Code
- `.github/dependabot.yml`
- `pubspec.yaml`, `.pubignore`, `CHANGELOG.md`, `LICENSE`, `analysis_options.yaml`
- `macos/macos_window_toolkit/Package.swift`, `macos/macos_window_toolkit.podspec`, `macos/Resources/PrivacyInfo.xcprivacy` (outside the package, bundled by neither)

## Reference behaviour
**None.**

## Cross-cutting invariants
**None.**

## Blast radius
- [user-docs](user-docs.md): the README install snippet repeats the version,, and CHANGELOG entries make behaviour claims a later change can falsify.
- [channel-bridge](channel-bridge.md): `pluginClass` must match the Swift class registered there.
- [example-app](example-app.md): it resolves the package through `path: ../`, so a constraint change here changes its resolution.

## Known holes / open
- Whether the podspec placeholders and the unbundled privacy manifest are deliberate is unknown. The maintainer did not know (maintainer, 2026-10-23).
- `cli.md` (a `tccutil reset` tip) sits at the root and is published.
