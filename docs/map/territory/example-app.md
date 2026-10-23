# Example app

## What it is
The demo Flutter macOS app in `example/`. It exercises nearly the whole public API: window list, search and advanced filters, a window detail sheet with capture/close/focus/scroll, installed applications, permission setup and monitoring, and the memory harness. It depends on the plugin by `path: ../`.

## Governing decisions
**None.**

## Design model
From reading the source:
- **Routing.** `initialRoute` is `/permission` until the permissions are granted, then `/main` (`example/lib/main.dart`). The other routes are `/applications`, `/test-monitoring` and `/memory-harness`.
- **Sandbox off.** `DebugProfile.entitlements` sets `com.apple.security.app-sandbox` to `false`, which the README's setup section asks consumers to do as well.
- **Dependencies.** Extra dependencies are `file_selector` and `cupertino_icons`. Open backlog #5 plans a grouped monthly Dependabot PR for them.
- **Largest consumer.** `example/lib/widgets/window_detail_sheet.dart` (about 2.3k lines) is the biggest single consumer of the API.

## Code
- `example/lib/main.dart — WindowDemoPage`
- `example/lib/widgets/window_detail_sheet.dart`, `windows_list.dart`, `window_card.dart`, `advanced_filter_section.dart`, `search_controls.dart`, `version_info_card.dart`
- `example/lib/page/applications/applications_page.dart`, `example/lib/page/permission/`
- `example/lib/services/window_service.dart`, `permission_service.dart`, `notification_service.dart`, `version_service.dart`
- `example/lib/test_permission_monitoring.dart — TestPermissionMonitoring`
- `example/macos/Runner/DebugProfile.entitlements`, `Release.entitlements`

## Reference behaviour
**None.**

## Cross-cutting invariants
**None.**

## Blast radius
- [memory-measurement](memory-measurement.md): the harness lives inside this app and its build.
- [shipping](shipping.md): the example's dependency constraints are what #5's `/example` Dependabot entry would update.

## Known holes / open
- `example/test/widget_test.dart` holds no assertions (8 lines).
