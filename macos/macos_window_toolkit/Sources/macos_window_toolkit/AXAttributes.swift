import ApplicationServices

extension AXUIElement {
    /// The value of `attribute`, or nil when it cannot be read
    func attributeValue(_ attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(self, attribute as CFString, &value) == .success else {
            return nil
        }
        return value
    }

    /// The value of `attribute` as `T`, or nil when it cannot be read or is not a `T`
    func attribute<T>(_ attribute: String) -> T? {
        return attributeValue(attribute) as? T
    }

    /// The value of `attribute` when it is an Accessibility element, or nil
    func elementAttribute(_ attribute: String) -> AXUIElement? {
        return attributeValue(attribute).flatMap(AXUIElement.element(from:))
    }

    /// `value` when it is an Accessibility element, or nil
    static func element(from value: CFTypeRef) -> AXUIElement? {
        guard CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return unsafeBitCast(value, to: AXUIElement.self)
    }

    /// The windows of the application with this process ID, or nil when they cannot be read
    static func windows(ofProcess processId: pid_t) -> [AXUIElement]? {
        return AXUIElementCreateApplication(processId).attribute(kAXWindowsAttribute)
    }
}
