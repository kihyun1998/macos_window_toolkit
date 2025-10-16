# String Filter Matching Options Implementation Plan

## Overview
Add matching options for String filters (name, ownerName) in `getWindowsAdvanced()` to support:
- Exact match vs Contains (substring) match
- Case sensitive vs Case insensitive matching

## New Parameters

### For each String filter, add 2 boolean parameters:

**name filter:**
- `nameExactMatch: Bool?` - default: `false` (contains match)
- `nameCaseSensitive: Bool?` - default: `true` (case sensitive)

**ownerName filter:**
- `ownerNameExactMatch: Bool?` - default: `false` (contains match)
- `ownerNameCaseSensitive: Bool?` - default: `true` (case sensitive)

### Matching Logic Combinations:

| exactMatch | caseSensitive | Behavior                              | Example                                    |
|------------|---------------|---------------------------------------|-------------------------------------------|
| false      | true          | Contains + Case Sensitive (DEFAULT)   | "Chrome" matches "Google Chrome" ✓        |
| false      | false         | Contains + Case Insensitive           | "chrome" matches "Google Chrome" ✓        |
| true       | true          | Exact + Case Sensitive                | "Chrome" matches "Chrome" only ✓          |
| true       | false         | Exact + Case Insensitive              | "chrome" matches "Chrome" ✓               |

## Files to Modify

### 1. Swift Native Layer

#### `macos/Classes/WindowHandler.swift`

**Function Signature Update:**
```swift
func getWindowsAdvanced(
    windowId: Int? = nil,
    name: String? = nil,
    nameExactMatch: Bool? = nil,          // NEW
    nameCaseSensitive: Bool? = nil,       // NEW
    ownerName: String? = nil,
    ownerNameExactMatch: Bool? = nil,     // NEW
    ownerNameCaseSensitive: Bool? = nil,  // NEW
    processId: Int? = nil,
    isOnScreen: Bool? = nil,
    layer: Int? = nil,
    x: Double? = nil,
    y: Double? = nil,
    width: Double? = nil,
    height: Double? = nil
) -> Result<[[String: Any]], WindowError>
```

**Implementation Changes:**
```swift
// Current (line ~198-203):
if let name = name {
    let windowName = windowInfo[kCGWindowName as String] as? String ?? ""
    if !windowName.contains(name) {
        return false
    }
}

// New:
if let name = name {
    let windowName = windowInfo[kCGWindowName as String] as? String ?? ""
    let exactMatch = nameExactMatch ?? false
    let caseSensitive = nameCaseSensitive ?? true

    if !matchString(windowName, pattern: name, exactMatch: exactMatch, caseSensitive: caseSensitive) {
        return false
    }
}

// Same for ownerName (line ~206-211)
```

**Add Helper Function:**
```swift
private func matchString(_ text: String, pattern: String, exactMatch: Bool, caseSensitive: Bool) -> Bool {
    let compareText = caseSensitive ? text : text.lowercased()
    let comparePattern = caseSensitive ? pattern : pattern.lowercased()

    if exactMatch {
        return compareText == comparePattern
    } else {
        return compareText.contains(comparePattern)
    }
}
```

#### `macos/Classes/MacosWindowToolkitPlugin.swift`

**Update Handler (line ~214-241):**
```swift
private func getWindowsAdvanced(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any] ?? [:]

    let windowId = arguments["windowId"] as? Int
    let name = arguments["name"] as? String
    let nameExactMatch = arguments["nameExactMatch"] as? Bool        // NEW
    let nameCaseSensitive = arguments["nameCaseSensitive"] as? Bool  // NEW
    let ownerName = arguments["ownerName"] as? String
    let ownerNameExactMatch = arguments["ownerNameExactMatch"] as? Bool        // NEW
    let ownerNameCaseSensitive = arguments["ownerNameCaseSensitive"] as? Bool  // NEW
    // ... rest

    let windowResult = windowHandler.getWindowsAdvanced(
      windowId: windowId,
      name: name,
      nameExactMatch: nameExactMatch,              // NEW
      nameCaseSensitive: nameCaseSensitive,        // NEW
      ownerName: ownerName,
      ownerNameExactMatch: ownerNameExactMatch,    // NEW
      ownerNameCaseSensitive: ownerNameCaseSensitive, // NEW
      // ... rest
    )
}
```

### 2. Dart Platform Interface & Channel

#### `lib/src/platform_interface/window_operations_interface.dart`

**Update Method (line ~107-120):**
```dart
Future<List<Map<String, dynamic>>> getWindowsAdvanced({
  int? windowId,
  String? name,
  bool? nameExactMatch,        // NEW
  bool? nameCaseSensitive,     // NEW
  String? ownerName,
  bool? ownerNameExactMatch,   // NEW
  bool? ownerNameCaseSensitive, // NEW
  int? processId,
  bool? isOnScreen,
  int? layer,
  double? x,
  double? y,
  double? width,
  double? height,
})
```

**Update Documentation:**
```dart
/// - [nameExactMatch]: If true, name must match exactly. If false (default), uses substring matching.
/// - [nameCaseSensitive]: If true (default), name matching is case sensitive.
/// - [ownerNameExactMatch]: If true, ownerName must match exactly. If false (default), uses substring matching.
/// - [ownerNameCaseSensitive]: If true (default), ownerName matching is case sensitive.
```

#### `lib/src/method_channel/window_operations_channel.dart`

**Update Implementation (line ~79-114):**
```dart
Future<List<Map<String, dynamic>>> getWindowsAdvanced({
  int? windowId,
  String? name,
  bool? nameExactMatch,        // NEW
  bool? nameCaseSensitive,     // NEW
  String? ownerName,
  bool? ownerNameExactMatch,   // NEW
  bool? ownerNameCaseSensitive, // NEW
  // ... rest
}) async {
  final args = <String, dynamic>{};

  if (windowId != null) args['windowId'] = windowId;
  if (name != null) args['name'] = name;
  if (nameExactMatch != null) args['nameExactMatch'] = nameExactMatch;           // NEW
  if (nameCaseSensitive != null) args['nameCaseSensitive'] = nameCaseSensitive;  // NEW
  if (ownerName != null) args['ownerName'] = ownerName;
  if (ownerNameExactMatch != null) args['ownerNameExactMatch'] = ownerNameExactMatch;        // NEW
  if (ownerNameCaseSensitive != null) args['ownerNameCaseSensitive'] = ownerNameCaseSensitive; // NEW
  // ... rest
}
```

### 3. Main API

#### `lib/src/macos_window_toolkit.dart`

**Update Method (line ~392-418):**
```dart
Future<List<MacosWindowInfo>> getWindowsAdvanced({
  int? windowId,
  String? name,
  bool? nameExactMatch,        // NEW
  bool? nameCaseSensitive,     // NEW
  String? ownerName,
  bool? ownerNameExactMatch,   // NEW
  bool? ownerNameCaseSensitive, // NEW
  // ... rest
}) async {
  final List<Map<String, dynamic>> windowMaps =
      await MacosWindowToolkitPlatform.instance.getWindowsAdvanced(
    windowId: windowId,
    name: name,
    nameExactMatch: nameExactMatch,              // NEW
    nameCaseSensitive: nameCaseSensitive,        // NEW
    ownerName: ownerName,
    ownerNameExactMatch: ownerNameExactMatch,    // NEW
    ownerNameCaseSensitive: ownerNameCaseSensitive, // NEW
    // ... rest
  );
}
```

**Update Documentation:**
Add examples showing matching options.

### 4. Example App

#### `example/lib/widgets/advanced_filter_section.dart`

**Add State Variables:**
```dart
// Add after line 47
bool _nameExactMatch = false;
bool _nameCaseSensitive = true;
bool _ownerNameExactMatch = false;
bool _ownerNameCaseSensitive = true;
```

**Update Widget Signature (line 4-16):**
```dart
final Function({
  int? windowId,
  String? name,
  bool? nameExactMatch,        // NEW
  bool? nameCaseSensitive,     // NEW
  String? ownerName,
  bool? ownerNameExactMatch,   // NEW
  bool? ownerNameCaseSensitive, // NEW
  // ... rest
}) onApplyFilters;
```

**Add UI Controls in Basic Filters Section:**

For Window Title field (after line ~173):
```dart
_buildTextField(
  controller: _nameController,
  label: 'Window Title',
  hint: 'e.g., Gmail, Document1',
  icon: Icons.title,
  colorScheme: colorScheme,
),
const SizedBox(height: 8),
Row(
  children: [
    Expanded(
      child: CheckboxListTile(
        title: const Text('Exact Match', style: TextStyle(fontSize: 13)),
        value: _nameExactMatch,
        onChanged: widget.isLoading ? null : (value) {
          setState(() => _nameExactMatch = value ?? false);
        },
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
    ),
    Expanded(
      child: CheckboxListTile(
        title: const Text('Case Sensitive', style: TextStyle(fontSize: 13)),
        value: _nameCaseSensitive,
        onChanged: widget.isLoading ? null : (value) {
          setState(() => _nameCaseSensitive = value ?? true);
        },
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
    ),
  ],
),
```

Same for Owner Name field (after line ~186).

**Update _applyFilters Method (line ~495-524):**
```dart
void _applyFilters() {
  widget.onApplyFilters(
    windowId: _windowIdController.text.isNotEmpty
        ? int.tryParse(_windowIdController.text)
        : null,
    name: _nameController.text.isNotEmpty ? _nameController.text : null,
    nameExactMatch: _nameController.text.isNotEmpty ? _nameExactMatch : null,           // NEW
    nameCaseSensitive: _nameController.text.isNotEmpty ? _nameCaseSensitive : null,     // NEW
    ownerName: _ownerNameController.text.isNotEmpty
        ? _ownerNameController.text
        : null,
    ownerNameExactMatch: _ownerNameController.text.isNotEmpty ? _ownerNameExactMatch : null,        // NEW
    ownerNameCaseSensitive: _ownerNameController.text.isNotEmpty ? _ownerNameCaseSensitive : null,  // NEW
    // ... rest
  );
}
```

**Update _clearAllFilters Method (line ~526-537):**
```dart
void _clearAllFilters() {
  // ... existing clears
  setState(() {
    _isOnScreenValue = 'any';
    _nameExactMatch = false;           // NEW
    _nameCaseSensitive = true;         // NEW
    _ownerNameExactMatch = false;      // NEW
    _ownerNameCaseSensitive = true;    // NEW
  });
}
```

#### `example/lib/main.dart`

**Update _applyAdvancedFilters Method (line ~302-372):**
```dart
Future<void> _applyAdvancedFilters({
  int? windowId,
  String? name,
  bool? nameExactMatch,        // NEW
  bool? nameCaseSensitive,     // NEW
  String? ownerName,
  bool? ownerNameExactMatch,   // NEW
  bool? ownerNameCaseSensitive, // NEW
  // ... rest
}) async {
  // ...

  final windows = await plugin.getWindowsAdvanced(
    windowId: windowId,
    name: name,
    nameExactMatch: nameExactMatch,              // NEW
    nameCaseSensitive: nameCaseSensitive,        // NEW
    ownerName: ownerName,
    ownerNameExactMatch: ownerNameExactMatch,    // NEW
    ownerNameCaseSensitive: ownerNameCaseSensitive, // NEW
    // ... rest
  );

  // Update success message to show matching options
  if (name != null) {
    String nameFilter = 'Title: "$name"';
    if (nameExactMatch == true) nameFilter += ' (exact)';
    if (nameCaseSensitive == false) nameFilter += ' (case-insensitive)';
    filters.add(nameFilter);
  }
  // Same for ownerName
}
```

### 5. Documentation

#### `CHANGELOG.md`

Add to Unreleased section:
```markdown
- **FEAT**: String matching options for advanced filters
  - Added `nameExactMatch` and `nameCaseSensitive` parameters for window title filtering
  - Added `ownerNameExactMatch` and `ownerNameCaseSensitive` parameters for owner name filtering
  - Supports 4 matching modes: exact/contains × case-sensitive/case-insensitive
  - Default: contains match with case sensitivity (backward compatible)
```

## Implementation Order

1. ✅ Update Swift `WindowHandler.swift` - Add helper function and update filtering logic
2. ✅ Update Swift `MacosWindowToolkitPlugin.swift` - Add parameter handling
3. ✅ Update Dart `window_operations_interface.dart` - Add parameters and docs
4. ✅ Update Dart `window_operations_channel.dart` - Add parameter passing
5. ✅ Update Dart `macos_window_toolkit.dart` - Add parameters and examples
6. ✅ Update Example `advanced_filter_section.dart` - Add UI controls
7. ✅ Update Example `main.dart` - Handle new parameters
8. ✅ Update `CHANGELOG.md`
9. ✅ Test all matching combinations

## Testing Scenarios

1. **Contains + Case Sensitive (default)**
   - Input: name="Chrome", exactMatch=false, caseSensitive=true
   - Should match: "Google Chrome", "Chrome Browser"
   - Should NOT match: "chrome", "CHROME"

2. **Contains + Case Insensitive**
   - Input: name="chrome", exactMatch=false, caseSensitive=false
   - Should match: "Google Chrome", "CHROME", "chrome"

3. **Exact + Case Sensitive**
   - Input: name="Chrome", exactMatch=true, caseSensitive=true
   - Should match: "Chrome" only
   - Should NOT match: "chrome", "Google Chrome"

4. **Exact + Case Insensitive**
   - Input: name="chrome", exactMatch=true, caseSensitive=false
   - Should match: "Chrome", "CHROME", "chrome"
   - Should NOT match: "Google Chrome"

## Backward Compatibility

- All new parameters are optional (default: `nil`)
- Default behavior: contains match with case sensitivity (same as before)
- Existing code continues to work without changes
