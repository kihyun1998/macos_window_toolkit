# A window action's success means the request was accepted, unless the caller asks to confirm it

`closeWindow` and `focusWindow` succeed by default once macOS has accepted the request: the close button is pressed, or the window is made main and raised. That is a requested outcome, not proof that the window closed or came to the front. A caller that needs the confirmed outcome passes a wait (`waitUntilClosed`, `waitUntilFocused`). The call then succeeds only once the window is seen in that state, and fails with its own reason (`windowStillOpen`, `windowNotFocused`) when the wait runs out. We chose this over confirming every call because confirmation costs a wait, can misread a slow app as a failure, and would turn existing successes into failures for every consumer. We chose it over documenting the gap alone because macOS can refuse an activation (since macOS 14 activation is cooperative, and a caller that is not frontmost is refused), and a caller that must know has no other way to find out (#25, #29).

## Considered Options

- Documentation only: `focusWindow` keeps returning success when activation is refused, and the caller cannot tell.
- Always confirm: every call waits and checks, so a refused or slow activation becomes a failure for all callers.
