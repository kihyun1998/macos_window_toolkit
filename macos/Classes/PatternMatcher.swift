import Foundation

/// Matches a window's title or owner name against a caller's pattern
enum PatternMatcher {
    /// Whether `text` matches `pattern`: whole or contained, with or without case, and
    /// with `*` (any characters) and `?` (one character) when `wildcard` holds, which
    /// takes priority over `exactMatch`
    static func matches(_ text: String, pattern: String, exactMatch: Bool, caseSensitive: Bool, wildcard: Bool = false) -> Bool {
        let compareText = caseSensitive ? text : text.lowercased()
        let comparePattern = caseSensitive ? pattern : pattern.lowercased()

        // Wildcard matching takes priority
        if wildcard {
            return matchWildcard(compareText, pattern: comparePattern)
        }

        if exactMatch {
            return compareText == comparePattern
        } else {
            return compareText.contains(comparePattern)
        }
    }

    /// Wildcard matching implementation
    /// Supports * (0 or more characters) and ? (exactly 1 character)
    private static func matchWildcard(_ text: String, pattern: String) -> Bool {
        // Split pattern by * to get parts
        let parts = pattern.components(separatedBy: "*")

        // Handle edge case: pattern is just "*"
        if parts.count == 2 && parts[0].isEmpty && parts[1].isEmpty {
            return true
        }

        var currentIndex = text.startIndex

        for (index, part) in parts.enumerated() {
            let isFirst = index == 0
            let isLast = index == parts.count - 1

            // Skip empty parts (except when they're meaningful)
            if part.isEmpty {
                // Empty part at start means pattern starts with *
                if isFirst && !pattern.hasPrefix("*") {
                    return false
                }
                // Empty part at end means pattern ends with *
                if isLast && !pattern.hasSuffix("*") {
                    return false
                }
                continue
            }

            // Match this part considering ? wildcards
            if let matchedRange = findPartMatch(in: text, from: currentIndex, part: part, isFirst: isFirst && !pattern.hasPrefix("*"), isLast: isLast && !pattern.hasSuffix("*")) {
                currentIndex = matchedRange.upperBound
            } else {
                return false
            }
        }

        // If pattern doesn't end with *, we must be at the end of text
        if !pattern.hasSuffix("*") && currentIndex != text.endIndex {
            return false
        }

        return true
    }

    /// Helper function to find a part match with ? wildcard support
    private static func findPartMatch(in text: String, from startIndex: String.Index, part: String, isFirst: Bool, isLast: Bool) -> Range<String.Index>? {
        // If part contains ?, we need character-by-character matching
        if part.contains("?") {
            return findPartMatchWithQuestionMark(in: text, from: startIndex, part: part, isFirst: isFirst, isLast: isLast)
        }

        // No ? in part, use simple string search
        let searchRange = startIndex..<text.endIndex

        if isFirst {
            // Must match at the start
            if text[searchRange].hasPrefix(part) {
                return startIndex..<text.index(startIndex, offsetBy: part.count)
            }
            return nil
        } else if isLast {
            // Must match at the end
            if text[searchRange].hasSuffix(part) {
                let endIndex = text.endIndex
                let startOfMatch = text.index(endIndex, offsetBy: -part.count)
                if startOfMatch >= startIndex {
                    return startOfMatch..<endIndex
                }
            }
            return nil
        } else {
            // Can match anywhere in remaining text
            if let range = text.range(of: part, range: searchRange) {
                return range
            }
            return nil
        }
    }

    /// Find match with ? wildcard support
    private static func findPartMatchWithQuestionMark(in text: String, from startIndex: String.Index, part: String, isFirst: Bool, isLast: Bool) -> Range<String.Index>? {
        let remainingText = String(text[startIndex...])

        // For each possible starting position
        let maxOffset = isLast ? (remainingText.count - part.count) : remainingText.count

        for offset in 0...max(0, maxOffset) {
            if offset + part.count > remainingText.count {
                break
            }

            let testStartIndex = remainingText.index(remainingText.startIndex, offsetBy: offset)
            let testEndIndex = remainingText.index(testStartIndex, offsetBy: part.count)
            let testSubstring = String(remainingText[testStartIndex..<testEndIndex])

            // Check if this substring matches the pattern with ?
            var matches = true
            for (patternChar, testChar) in zip(part, testSubstring) {
                if patternChar != "?" && patternChar != testChar {
                    matches = false
                    break
                }
            }

            if matches {
                // For isFirst, must start at offset 0
                if isFirst && offset != 0 {
                    continue
                }

                // For isLast, must end at the end of remaining text
                if isLast && testEndIndex != remainingText.endIndex {
                    continue
                }

                let actualStartIndex = text.index(startIndex, offsetBy: offset)
                let actualEndIndex = text.index(actualStartIndex, offsetBy: part.count)
                return actualStartIndex..<actualEndIndex
            }

            // If isFirst, we can only check offset 0
            if isFirst {
                break
            }
        }

        return nil
    }
}
