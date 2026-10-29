import Cocoa
import Foundation
import ScreenCaptureKit

@available(macOS 12.3, *)
class CaptureHandler {

    /// Captures the window as PNG data: optionally without its titlebar, cropped and
    /// resized, always with transparent borders cropped
    static func captureWindow(
        windowId: Int, excludeTitlebar: Bool = false, customTitlebarHeight: CGFloat? = nil,
        targetWidth: Int? = nil, targetHeight: Int? = nil, preserveAspectRatio: Bool = false,
        cropContentWidth: Int? = nil, cropContentHeight: Int? = nil,
        cropX: Int? = nil, cropY: Int? = nil, cropWidth: Int? = nil, cropHeight: Int? = nil,
        resizeCroppedToWindowSize: Bool = true, permissions: PermissionChecking = PermissionHandler()
    ) async throws -> Data {
        try requireScreenRecording(
            permissions, "Screen recording permission is required for window capture")

        guard #available(macOS 14.0, *) else {
            throw CaptureError.requiresMacOS14(
                NativeFailure(message: "Window capture requires macOS 14.0 or later"))
        }

        do {
            let targetWindow = try window(windowId, in: try await SCShareableContent.current)

            if let pid = targetWindow.owningApplication?.processID,
                isMinimized(title: targetWindow.title ?? "", processId: pid)
            {
                throw CaptureError.windowMinimized(
                    NativeFailure(message: "Window is minimized and cannot be captured"))
            }

            // Capture configuration
            let configuration = SCStreamConfiguration()

            // Always capture at original window size (resize will be done manually later)
            configuration.width = Int(targetWindow.frame.width)
            configuration.height = Int(targetWindow.frame.height)
            configuration.scalesToFit = false

            configuration.capturesAudio = false
            configuration.showsCursor = false
            configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)

            // Set capture filter (capture specific window only)
            let filter = SCContentFilter(desktopIndependentWindow: targetWindow)

            // Execute capture - use SCScreenshotManager on macOS 14.0+
            let screenshot = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: configuration
            )

            // The conversion drains its temporaries in its own pool
            return try autoreleasepool { () throws -> Data in
                // Crop image if titlebar exclusion is requested
                let finalImage: CGImage
                if excludeTitlebar {
                    // Always set to 0 for fullscreen windows as they have no titlebar
                    let titlebarHeight: CGFloat
                    if isFullscreenWindow(targetWindow.frame) {
                        titlebarHeight = 0.0
                    } else {
                        // Use custom value or default (28px) for regular windows
                        let requestedHeight = customTitlebarHeight ?? 28.0
                        titlebarHeight = max(0, min(requestedHeight, targetWindow.frame.height))
                    }

                    let cropRect = CGRect(
                        x: 0,
                        y: titlebarHeight,
                        width: targetWindow.frame.width,
                        height: targetWindow.frame.height - titlebarHeight
                    )

                    guard let croppedImage = screenshot.cropping(to: cropRect) else {
                        throw CaptureError.captureFailed(NativeFailure(message: "Failed to crop titlebar from image"))
                    }
                    finalImage = croppedImage
                } else {
                    finalImage = screenshot
                }

                // Crop transparent borders (all windows)
                let croppedFinalImage: CGImage
                let frameW = Int(targetWindow.frame.width)
                let frameH = Int(targetWindow.frame.height)
                if let cropped = cropTransparentBorders(finalImage) {
                    if resizeCroppedToWindowSize,
                        let restored = resizeImageToExactSize(
                            cropped, targetWidth: frameW, targetHeight: frameH)
                    {
                        croppedFinalImage = restored
                    } else {
                        croppedFinalImage = cropped
                    }
                } else {
                    croppedFinalImage = finalImage
                }

                // Custom crop: center crop
                let customCroppedImage: CGImage
                if let cw = cropContentWidth, let ch = cropContentHeight {
                    let imgW = croppedFinalImage.width
                    let imgH = croppedFinalImage.height
                    let x = max(0, (imgW - cw) / 2)
                    let y = max(0, (imgH - ch) / 2)
                    let clampedW = min(cw, imgW - x)
                    let clampedH = min(ch, imgH - y)
                    if let cropped = croppedFinalImage.cropping(
                        to: CGRect(x: x, y: y, width: clampedW, height: clampedH))
                    {
                        customCroppedImage = cropped
                    } else {
                        customCroppedImage = croppedFinalImage
                    }
                    // Custom crop: rect crop
                } else if let cx = cropX, let cy = cropY, let cw = cropWidth, let ch = cropHeight {
                    let imgW = croppedFinalImage.width
                    let imgH = croppedFinalImage.height
                    let clampedX = max(0, min(cx, imgW - 1))
                    let clampedY = max(0, min(cy, imgH - 1))
                    let clampedW = min(cw, imgW - clampedX)
                    let clampedH = min(ch, imgH - clampedY)
                    if let cropped = croppedFinalImage.cropping(
                        to: CGRect(x: clampedX, y: clampedY, width: clampedW, height: clampedH))
                    {
                        customCroppedImage = cropped
                    } else {
                        customCroppedImage = croppedFinalImage
                    }
                } else {
                    customCroppedImage = croppedFinalImage
                }

                // Resize if needed
                let imageToConvert: CGImage
                if let width = targetWidth, let height = targetHeight {
                    let resized: CGImage?
                    if preserveAspectRatio {
                        // Preserve aspect ratio, fill extra space with black
                        resized = resizeImagePreservingAspectRatio(
                            customCroppedImage,
                            targetWidth: width,
                            targetHeight: height
                        )
                    } else {
                        // Force exact size resize (may distort image)
                        resized = resizeImageToExactSize(
                            customCroppedImage,
                            targetWidth: width,
                            targetHeight: height
                        )
                    }

                    guard let finalResized = resized else {
                        throw CaptureError.captureFailed(NativeFailure(message: "Failed to resize image"))
                    }
                    imageToConvert = finalResized
                } else {
                    imageToConvert = customCroppedImage
                }

                // Convert the CGImage to PNG data
                guard let pngData = convertCGImageToPNG(imageToConvert) else {
                    throw CaptureError.captureFailed(NativeFailure(message: "Failed to convert image to PNG"))
                }

                return pngData
            }

        } catch let error as CaptureError {
            throw error
        } catch {
            throw classify(error)
        }
    }

    /// The image drawn at exactly the target size, ignoring its aspect ratio
    private static func resizeImageToExactSize(
        _ image: CGImage,
        targetWidth: Int,
        targetHeight: Int
    ) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard
            let context = CGContext(
                data: nil,
                width: targetWidth,
                height: targetHeight,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            return nil
        }

        // High quality interpolation for smooth resizing
        context.interpolationQuality = .high

        // Draw the image at exact target size
        context.draw(
            image,
            in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
        )

        return context.makeImage()
    }

    /// The image scaled to fit the target size and centred on black
    private static func resizeImagePreservingAspectRatio(
        _ image: CGImage,
        targetWidth: Int,
        targetHeight: Int
    ) -> CGImage? {
        let sourceWidth = CGFloat(image.width)
        let sourceHeight = CGFloat(image.height)
        let targetW = CGFloat(targetWidth)
        let targetH = CGFloat(targetHeight)

        // Calculate aspect ratio scaling
        let widthRatio = targetW / sourceWidth
        let heightRatio = targetH / sourceHeight
        let scaleFactor = min(widthRatio, heightRatio)

        // Calculate scaled dimensions
        let scaledWidth = sourceWidth * scaleFactor
        let scaledHeight = sourceHeight * scaleFactor

        // Calculate offset to center the image
        let xOffset = (targetW - scaledWidth) / 2.0
        let yOffset = (targetH - scaledHeight) / 2.0

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard
            let context = CGContext(
                data: nil,
                width: targetWidth,
                height: targetHeight,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            return nil
        }

        // Fill background with black
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))

        // High quality interpolation for smooth resizing
        context.interpolationQuality = .high

        // Draw the image centered with preserved aspect ratio
        context.draw(
            image,
            in: CGRect(x: xOffset, y: yOffset, width: scaledWidth, height: scaledHeight)
        )

        return context.makeImage()
    }

    private static func convertCGImageToPNG(_ cgImage: CGImage) -> Data? {
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .png, properties: [:])
    }

    /// Whether the window fills a screen, read from ScreenCaptureKit so that a window on
    /// another Space is seen
    static func isWindowFullScreen(
        windowId: Int, permissions: PermissionChecking = PermissionHandler()
    ) async throws -> Bool {
        try requireScreenRecording(
            permissions, "Screen recording permission is required for fullscreen detection")

        guard #available(macOS 14.0, *) else {
            throw CaptureError.requiresMacOS14(
                NativeFailure(message: "Fullscreen detection requires macOS 14.0 or later"))
        }

        let targetWindow = try window(windowId, in: try await SCShareableContent.current)
        return isFullscreenWindow(targetWindow.frame)
    }

    /// Throws `screenRecordingPermissionDenied` with `message` unless permission is granted
    private static func requireScreenRecording(
        _ permissions: PermissionChecking, _ message: String
    ) throws {
        guard permissions.hasScreenRecordingPermission() else {
            throw CaptureError.screenRecordingPermissionDenied(NativeFailure(message: message))
        }
    }

    /// The window with this ID in `content`, or `invalidWindowId`
    private static func window(_ windowId: Int, in content: SCShareableContent) throws -> SCWindow {
        guard let window = content.windows.first(where: { $0.windowID == CGWindowID(windowId) })
        else {
            throw CaptureError.invalidWindowId(
                NativeFailure(message: "Window with the specified ID was not found"))
        }
        return window
    }

    /// Whether the app with this PID has a minimized AX window titled `title`, or any
    /// minimized window when `title` is empty
    private static func isMinimized(title: String, processId: pid_t) -> Bool {
        for axWindow in AXUIElement.windows(ofProcess: processId) ?? [] {
            let minimized: Bool? = axWindow.attribute(kAXMinimizedAttribute)
            guard minimized == true else { continue }
            let axTitle: String = axWindow.attribute(kAXTitleAttribute) ?? ""
            if axTitle == title || title.isEmpty {
                return true
            }
        }
        return false
    }

    /// The `CaptureError` for an error ScreenCaptureKit raised: a permission denial when
    /// its code or its description says so, otherwise `captureFailed`
    private static func classify(_ error: Error) -> CaptureError {
        let nsError = error as NSError
        let failure = NativeFailure(
            message: error.localizedDescription, code: nsError.code, domain: nsError.domain)

        if nsError.code == -3801 || nsError.code == -3803 {
            return .screenRecordingPermissionDenied(failure)
        }

        let description = error.localizedDescription.lowercased()
        let mentionsPermission =
            description.contains("permission") || description.contains("not permitted")
            || description.contains("denied")
        let permissionDomains = [NSCocoaErrorDomain, NSOSStatusErrorDomain]
        if mentionsPermission
            && (nsError.domain.lowercased().contains("screencapturekit")
                || permissionDomains.contains(nsError.domain))
        {
            return .screenRecordingPermissionDenied(failure)
        }

        return .captureFailed(failure)
    }

    /// Crops transparent border pixels from a CGImage
    private static func cropTransparentBorders(_ image: CGImage) -> CGImage? {
        guard
            image.alphaInfo != .none && image.alphaInfo != .noneSkipFirst
                && image.alphaInfo != .noneSkipLast
        else {
            return nil  // No alpha channel, nothing to crop
        }
        guard let dataProvider = image.dataProvider,
            let data = dataProvider.data,
            let ptr = CFDataGetBytePtr(data)
        else { return nil }

        let w = image.width
        let h = image.height
        let bytesPerRow = image.bytesPerRow
        let bpp = image.bitsPerPixel / 8
        // Alpha offset depends on both alphaInfo AND byte order
        // SCScreenshotManager typically uses premultipliedFirst + byteOrder32Little = BGRA in memory (alpha at offset 3)
        let byteOrderLittle = image.bitmapInfo.contains(.byteOrder32Little)
        let alphaOffset: Int
        switch image.alphaInfo {
        case .premultipliedFirst, .first:
            alphaOffset = byteOrderLittle ? bpp - 1 : 0
        case .premultipliedLast, .last:
            alphaOffset = byteOrderLittle ? 0 : bpp - 1
        default:
            return nil
        }

        func isTransparentRow(_ y: Int) -> Bool {
            for x in 0..<w {
                if ptr[y * bytesPerRow + x * bpp + alphaOffset] > 0 { return false }
            }
            return true
        }
        func isTransparentCol(_ x: Int) -> Bool {
            for y in 0..<h {
                if ptr[y * bytesPerRow + x * bpp + alphaOffset] > 0 { return false }
            }
            return true
        }

        var top = 0
        var bottom = h - 1
        var left = 0
        var right = w - 1
        while top <= bottom && isTransparentRow(top) { top += 1 }
        while bottom >= top && isTransparentRow(bottom) { bottom -= 1 }
        while left <= right && isTransparentCol(left) { left += 1 }
        while right >= left && isTransparentCol(right) { right -= 1 }

        guard top <= bottom && left <= right else { return nil }
        guard top > 0 || bottom < h - 1 || left > 0 || right < w - 1 else { return nil }

        let cropRect = CGRect(x: left, y: top, width: right - left + 1, height: bottom - top + 1)
        return image.cropping(to: cropRect)
    }

    /// Whether the frame equals the frame of one of the screens
    private static func isFullscreenWindow(_ windowFrame: CGRect) -> Bool {
        return NSScreen.screens.contains { screen in
            let screenFrame = screen.frame
            return windowFrame.size.width == screenFrame.size.width
                && windowFrame.size.height == screenFrame.size.height
                && windowFrame.origin.x == screenFrame.origin.x
                && windowFrame.origin.y == screenFrame.origin.y
        }
    }

    /// The titled windows ScreenCaptureKit can capture
    static func getCapturableWindows(
        permissions: PermissionChecking = PermissionHandler()
    ) async throws -> [[String: Any]] {
        try requireScreenRecording(
            permissions, "Screen recording permission is required for window capture")

        do {
            let availableContent = try await SCShareableContent.current

            return availableContent.windows.compactMap { window in
                guard let title = window.title, !title.isEmpty else { return nil }

                return [
                    "windowId": Int(window.windowID),
                    "title": title,
                    "ownerName": window.owningApplication?.applicationName ?? "Unknown",
                    "bundleIdentifier": window.owningApplication?.bundleIdentifier ?? "",
                    "frame": [
                        "x": window.frame.origin.x,
                        "y": window.frame.origin.y,
                        "width": window.frame.size.width,
                        "height": window.frame.size.height,
                    ],
                    "isOnScreen": window.isOnScreen,
                ]
            }
        } catch {
            throw classify(error)
        }
    }
}

/// The message of a failure, and the `NSError` code and domain behind it when there is one
struct NativeFailure {
    let message: String
    var code: Int? = nil
    var domain: String? = nil
}

/// Screen capture errors
enum CaptureError: PluginError {
    case invalidWindowId(NativeFailure)
    case windowMinimized(NativeFailure)
    case captureFailed(NativeFailure)
    case unsupportedMacOSVersion(NativeFailure)
    case requiresMacOS14(NativeFailure)
    case screenRecordingPermissionDenied(NativeFailure)

    /// The failure every case carries
    var failure: NativeFailure {
        switch self {
        case .invalidWindowId(let failure), .windowMinimized(let failure),
            .captureFailed(let failure), .unsupportedMacOSVersion(let failure),
            .requiresMacOS14(let failure), .screenRecordingPermissionDenied(let failure):
            return failure
        }
    }

    var code: String {
        switch self {
        case .invalidWindowId: return "INVALID_WINDOW_ID"
        case .windowMinimized: return "WINDOW_MINIMIZED"
        case .captureFailed: return "CAPTURE_FAILED"
        case .unsupportedMacOSVersion: return "UNSUPPORTED_MACOS_VERSION"
        case .requiresMacOS14: return "REQUIRES_MACOS_14"
        case .screenRecordingPermissionDenied: return "SCREEN_RECORDING_PERMISSION_DENIED"
        }
    }

    var stateReason: String? {
        switch self {
        case .invalidWindowId: return "window_not_found"
        case .windowMinimized: return "window_minimized"
        case .unsupportedMacOSVersion, .requiresMacOS14: return "unsupported_version"
        case .screenRecordingPermissionDenied: return "permission_denied"
        case .captureFailed: return nil
        }
    }

    var message: String { failure.message }

    var details: String? {
        switch self {
        case .invalidWindowId:
            return nil
        case .windowMinimized:
            return "The window is currently minimized. Please restore the window to capture it."
        case .captureFailed(let failure):
            return failure.message
        case .unsupportedMacOSVersion:
            return "Current version: \(VersionUtil.getMacOSVersion()), Required: 12.3+"
        case .requiresMacOS14:
            return "Current version: \(VersionUtil.getMacOSVersion()), Required: 14.0+"
        case .screenRecordingPermissionDenied:
            return "Please grant screen recording permission in System Settings > Privacy & Security > Screen Recording"
        }
    }

    var nativeErrorCode: Int? { failure.code }
    var nativeErrorDomain: String? { failure.domain }
}
