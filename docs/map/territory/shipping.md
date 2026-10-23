# Shipping

## What it is
Publishing the package to pub.dev and building the macOS pod: version and constraints, what goes in the archive, the CocoaPods spec and privacy manifest, the changelog, and dependency upkeep.

## Governing decisions
**None.**

## Design model
From reading the files:
- **Version and constraints.** `pubspec.yaml` holds `version: 1.9.0`, `sdk >=3.0.0 <4.0.0` and `flutter >=3.10.0`, with one runtime dependency, `plugin_platform_interface: ^2.0.2`. `flutter.plugin.platforms.macos.pluginClass: MacosWindowToolkitPlugin` must name the Swift class in `MacosWindowToolkitPlugin.swift`.
- **The version string has two hand-kept sites** (`git grep -n '1\.9\.0' -- ':!CHANGELOG.md' ':!example/pubspec.lock'`): `pubspec.yaml` and the README install snippet. CHANGELOG adds a heading per release. Release commits are named `chore: release X.Y.Z` (1888f54).
- **What is published.** `.pubignore` excludes `CLAUDE.md` and `docs/`, so this map and the agent docs are not published. `documentations/`, `cli.md` and `example/` are.
- **Pod.** `macos/macos_window_toolkit.podspec` sets the platform `osx 10.15` and `swift_version 5.0`. Its version, summary, description, homepage and author are still template placeholders. The `resource_bundles` line for `Resources/PrivacyInfo.xcprivacy` is commented out.
- **No CI.** No `.github/` directory exists.

## Code
- `pubspec.yaml`, `.pubignore`, `CHANGELOG.md`, `LICENSE`, `analysis_options.yaml`
- `macos/macos_window_toolkit.podspec`, `macos/Resources/PrivacyInfo.xcprivacy`

## Reference behaviour
**None.**

## Cross-cutting invariants
**None.**

## Blast radius
- [user-docs](user-docs.md): the README install snippet repeats the version, and the CHANGELOG makes behaviour claims that notes have found false (CHANGELOG 1.8.3, see [window-control](window-control.md)).
- [channel-bridge](channel-bridge.md): `pluginClass` must match the Swift class registered there.
- [example-app](example-app.md): it resolves the package through `path: ../`, so a constraint change here changes its resolution.

## Known holes / open
- Tracked: #5. Dependabot is not set up. The plan on #5: root pub weekly with `increase-if-necessary`, one PR per dependency; `/example` monthly, grouped; no `github-actions` entry.
- Whether the podspec placeholders and the unbundled privacy manifest are deliberate is unknown. The maintainer did not know (maintainer, 2026-10-23).
- `cli.md` (a `tccutil reset` tip) sits at the root and is published.
