# App discovery

## What it is
This area lists installed `.app` bundles with name, bundle ID, version, path and icon path. It also searches them by name and opens a Mac App Store search.

## Governing decisions
**None.**

## Design model
From reading the source:
- **Where it looks.** `getAllInstalledApplications` scans five directories **one level deep** (`skipsSubdirectoryDescendants`): `/Applications`, `/System/Applications`, `/System/Applications/Utilities`, `~/Applications` and `/System/Library/CoreServices`. It runs synchronously on the calling thread.
- **Fields.**
  - Name falls back from `CFBundleDisplayName` to `CFBundleName` to the file name.
  - The icon path comes only from `CFBundleIconFile`, tried with and without `.icns`.
- **Name search.** `getApplicationByName` rescans everything, then filters with `localizedCaseInsensitiveContains`.
- **App Store.** `openAppStoreSearch` percent-encodes the term into a `macappstores://` search URL.
- **Facade wrapping.** The facade turns a thrown error into `ApplicationFailure(systemError)` and an empty list into `ApplicationFailure(notFound)`. Swift always returns `.success` for the listings; `ApplicationError` has one case, `invalidURL`, for the App Store search.

## Code
- `macos/Classes/ApplicationHandler.swift — ApplicationHandler.getAllInstalledApplications`, `getApplicationByName`, `openAppStoreSearch`, `ApplicationError`
- `macos/Classes/MacosWindowToolkitPlugin.swift — getAllInstalledApplications`, `getApplicationByName`, `openAppStoreSearch`
- `lib/src/method_channel/application_operations_channel.dart — getAllInstalledApplications`, `getApplicationByName`, `openAppStoreSearch`
- `lib/src/macos_window_toolkit.dart — MacosWindowToolkit.getAllInstalledApplications`, `getApplicationByName`
- `lib/src/models/macos_application_info.dart — MacosApplicationInfo`, `ApplicationResult`, `ApplicationFailureReason`

## Reference behaviour
**None.**

## Cross-cutting invariants
**None.**

## Blast radius
- [example-app](example-app.md): `example/lib/page/applications/applications_page.dart` renders this list and its icons.
- [user-docs](user-docs.md): `documentations/api/application_discovery.md` lists the searched directories by hand.

## Known holes / open
- Apps in subfolders, such as `/Applications/Utilities` (not scanned) or vendor folders under `/Applications`, are missed.
- Apps that ship only an asset-catalog icon (`CFBundleIconName`) get an empty `iconPath`.
- The full scan runs on the platform thread.
