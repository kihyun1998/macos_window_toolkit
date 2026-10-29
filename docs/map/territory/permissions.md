# Permissions

## What it is
This area checks, requests and opens settings for the two TCC permissions the plugin depends on: Screen Recording and Accessibility.

## Governing decisions
**None.**

## Design model
From reading the source:
- **Screen Recording.** The check is `CGPreflightScreenCaptureAccess`. A source comment says it is "a cached value from app launch", which is not verified here. The request is `CGRequestScreenCaptureAccess`, hopped onto the main queue when called off it.
- **Accessibility.** The check is `AXIsProcessTrusted`. The request is `AXIsProcessTrustedWithOptions` with the prompt option, which returns the *current* state rather than the user's answer.
- **Settings.** Each "open settings" call tries the specific Privacy pane URL, then Privacy & Security, then System Settings.
- **Pre-10.15 branches** return `true`. The podspec floor is `osx 10.15`, so those branches never run.
- **Prechecks.** Capture, close, focus and scroll check through `PermissionChecking`, the protocol `PermissionHandler` conforms to. The dispatcher passes its own `PermissionHandler` to `AXWindowActions` and to each `CaptureHandler` call; a test can pass a fake. Each check calls the system again: nothing caches the state.
- **Who gets the grant.** When the host is launched from a terminal, TCC attributes both permissions to the terminal app, the responsible process (issue #1 comment, 2026-06-12).

## Code
- `macos/Classes/PermissionHandler.swift — PermissionChecking`, `PermissionHandler` (all six methods)
- `macos/Classes/MacosWindowToolkitPlugin.swift — hasScreenRecordingPermission`, `requestScreenRecordingPermission`, `openScreenRecordingSettings`, `hasAccessibilityPermission`, `requestAccessibilityPermission`, `openAccessibilitySettings`
- `lib/src/method_channel/permission_operations_channel.dart — PermissionOperationsChannel`
- `lib/src/platform_interface/permission_operations_interface.dart — PermissionOperationsInterface`

## Reference behaviour
**None.** `docs/agents/thegraph.md` names Apple's docs as binding. The "cached value" comment is the claim most worth confirming there.

## Cross-cutting invariants
**None.**

## Blast radius
- [permission-watching](permission-watching.md): it polls `hasScreenRecordingPermission` and `hasAccessibilityPermission` on a timer. A slower or prompting check changes its cost and its events.
- [window-capture](window-capture.md): the Screen Recording precheck gates every capture and fullscreen check.
- [window-control](window-control.md) and [scroll-inspection](scroll-inspection.md): the Accessibility precheck gates them.
- [window-listing](window-listing.md): whether `role`/`subrole` (Accessibility) and titles (Screen Recording, per docs) appear depends on these grants.
- [example-app](example-app.md): its initial route and permission guard read these calls.

## Known holes / open
- If `CGPreflightScreenCaptureAccess` really is cached at launch, a grant made while the app runs is not seen until restart. That would also make [permission-watching](permission-watching.md) blind to it. Not confirmed.
- `PrivacyInfo.xcprivacy` declares no API usage and is not bundled. See [shipping](shipping.md).
