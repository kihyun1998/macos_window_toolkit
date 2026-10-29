# macos_window_toolkit

A Flutter plugin that lists, inspects, captures and acts on the macOS windows of other applications.

## Language

### Window actions

**Requested outcome**:
What an action's success means by default: macOS accepted the request (a close button pressed, a window raised), not that the window reached the state asked for.
_Avoid_: done, completed

**Confirmed outcome**:
What an action's success means when the caller asks to wait for it: the window was seen in the state asked for (closed, focused) before the wait ran out.
_Avoid_: verified, guaranteed

**Activation**:
An application becoming the frontmost application. macOS decides whether to grant it, and refuses one requested by an application that is not frontmost itself.
_Avoid_: focus (for an application), bring to front

**Focused window**:
The window that the frontmost application reports as its focused window. A window can be raised without being focused, and its application can be frontmost while another of its windows is focused.
_Avoid_: active window, front window, key window
