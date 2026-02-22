import Cocoa
import Foundation
import ScreenCaptureKit

@available(macOS 12.3, *)
class CaptureHandler {

    enum CaptureError: Error {
        case screenCaptureKitNotAvailable(code: Int?, domain: String?, message: String)
        case invalidWindowId(code: Int?, domain: String?, message: String)
        case windowMinimized(code: Int?, domain: String?, message: String)
        case captureNotSupported(code: Int?, domain: String?, message: String)
        case captureFailed(code: Int?, domain: String?, message: String)
        case unsupportedMacOSVersion(code: Int?, domain: String?, message: String)
        case requiresMacOS14(code: Int?, domain: String?, message: String)
        case screenRecordingPermissionDenied(code: Int?, domain: String?, message: String)
    }

    static func captureWindow(
        windowId: Int, excludeTitlebar: Bool = false, customTitlebarHeight: CGFloat? = nil,
        targetWidth: Int? = nil, targetHeight: Int? = nil, preserveAspectRatio: Bool = false,
        cropContentWidth: Int? = nil, cropContentHeight: Int? = nil,
        cropX: Int? = nil, cropY: Int? = nil, cropWidth: Int? = nil, cropHeight: Int? = nil,
        resizeCroppedToWindowSize: Bool = true
    ) async throws -> Data {
        // Check Screen Recording permission
        let permissionHandler = PermissionHandler()
        guard permissionHandler.hasScreenRecordingPermission() else {
            throw CaptureError.screenRecordingPermissionDenied(
                code: nil,
                domain: nil,
                message: "Screen recording permission is required for window capture"
            )
        }

        // Check macOS version - SCScreenshotManager is only available on macOS 14.0+
        guard #available(macOS 14.0, *) else {
            throw CaptureError.requiresMacOS14(
                code: nil,
                domain: nil,
                message: "Window capture requires macOS 14.0 or later"
            )
        }

        guard VersionUtil.isScreenCaptureKitAvailable() else {
            throw CaptureError.unsupportedMacOSVersion(
                code: nil,
                domain: nil,
                message: "macOS version does not support ScreenCaptureKit"
            )
        }

        do {
            // Get capturable content
            let availableContent = try await SCShareableContent.current

            // Find specific window ID
            guard
                let targetWindow = availableContent.windows.first(where: { window in
                    window.windowID == CGWindowID(windowId)
                })
            else {
                throw CaptureError.invalidWindowId(
                    code: nil,
                    domain: nil,
                    message: "Window with the specified ID was not found"
                )
            }

            // Check if window is minimized using Accessibility API
            // (isOnScreen is false for both minimized and other-Space windows,
            // but kAXMinimizedAttribute is only true for actually minimized windows)
            if let pid = targetWindow.owningApplication?.processID {
                let appElement = AXUIElementCreateApplication(pid)
                var windowsRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(
                    appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
                    let axWindows = windowsRef as? [AXUIElement]
                {
                    for axWindow in axWindows {
                        var minimizedRef: CFTypeRef?
                        if AXUIElementCopyAttributeValue(
                            axWindow, kAXMinimizedAttribute as CFString, &minimizedRef) == .success,
                            let isMinimized = minimizedRef as? Bool,
                            isMinimized
                        {
                            // Verify this is the same window by comparing titles
                            var titleRef: CFTypeRef?
                            let hasTitle =
                                AXUIElementCopyAttributeValue(
                                    axWindow, kAXTitleAttribute as CFString, &titleRef) == .success
                            let axTitle = hasTitle ? (titleRef as? String ?? "") : ""
                            let scTitle = targetWindow.title ?? ""

                            if axTitle == scTitle || scTitle.isEmpty {
                                throw CaptureError.windowMinimized(
                                    code: nil,
                                    domain: nil,
                                    message: "Window is minimized and cannot be captured"
                                )
                            }
                        }
                    }
                }
            }

            // Capture configuration
            let configuration = SCStreamConfiguration()

            // Always capture at original window size (resize will be done manually later)
            configuration.width = Int(targetWindow.frame.width)
            configuration.height = Int(targetWindow.frame.height)
            configuration.scalesToFit = false

            configuration.capturesAudio = false  // macOS 14.0+에서는 문제없음
            configuration.showsCursor = false
            configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)

            // Set capture filter (capture specific window only)
            let filter = SCContentFilter(desktopIndependentWindow: targetWindow)

            // Execute capture - use SCScreenshotManager on macOS 14.0+
            let screenshot = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: configuration
            )

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
                    throw CaptureError.captureFailed(
                        code: nil,
                        domain: nil,
                        message: "Failed to crop titlebar from image"
                    )
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
                    throw CaptureError.captureFailed(
                        code: nil,
                        domain: nil,
                        message: "Failed to resize image"
                    )
                }
                imageToConvert = finalResized
            } else {
                imageToConvert = customCroppedImage
            }

            // CGImage를 PNG 데이터로 변환
            guard let pngData = convertCGImageToPNG(imageToConvert) else {
                throw CaptureError.captureFailed(
                    code: nil,
                    domain: nil,
                    message: "Failed to convert image to PNG"
                )
            }

            return pngData

        } catch let error as CaptureError {
            throw error
        } catch {
            // Analyze NSError to provide more specific error information
            let nsError = error as NSError

            // Check known permission error codes first (regardless of domain)
            if nsError.code == -3801 || nsError.code == -3803 {
                throw CaptureError.screenRecordingPermissionDenied(
                    code: nsError.code,
                    domain: nsError.domain,
                    message: error.localizedDescription
                )
            }

            // Check for ScreenCaptureKit specific errors (domain contains screencapturekit)
            if nsError.domain.lowercased().contains("screencapturekit") {
                // Also check error description for permission-related keywords
                let errorMessage = error.localizedDescription.lowercased()
                if errorMessage.contains("permission") || errorMessage.contains("not permitted")
                    || errorMessage.contains("denied")
                {
                    throw CaptureError.screenRecordingPermissionDenied(
                        code: nsError.code,
                        domain: nsError.domain,
                        message: error.localizedDescription
                    )
                }

                // Other ScreenCaptureKit errors
                throw CaptureError.captureFailed(
                    code: nsError.code,
                    domain: nsError.domain,
                    message: error.localizedDescription
                )
            }

            // Check for CoreGraphics/System errors that might indicate permission issues
            if nsError.domain == NSCocoaErrorDomain || nsError.domain == NSOSStatusErrorDomain {
                let errorMessage = error.localizedDescription.lowercased()
                if errorMessage.contains("permission") || errorMessage.contains("not permitted")
                    || errorMessage.contains("denied")
                {
                    throw CaptureError.screenRecordingPermissionDenied(
                        code: nsError.code,
                        domain: nsError.domain,
                        message: error.localizedDescription
                    )
                }
            }

            throw CaptureError.captureFailed(
                code: nsError.code,
                domain: nsError.domain,
                message: error.localizedDescription
            )
        }
    }

    // Resize CGImage to exact target size (ignoring aspect ratio)
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

    // Resize CGImage while preserving aspect ratio (fills extra space with black)
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

    /// Checks if a window is fullscreen using SCShareableContent for accurate detection across Spaces
    static func isWindowFullScreen(windowId: Int) async throws -> Bool {
        // Check Screen Recording permission
        let permissionHandler = PermissionHandler()
        guard permissionHandler.hasScreenRecordingPermission() else {
            throw CaptureError.screenRecordingPermissionDenied(
                code: nil,
                domain: nil,
                message: "Screen recording permission is required for fullscreen detection"
            )
        }

        guard #available(macOS 14.0, *) else {
            throw CaptureError.requiresMacOS14(
                code: nil,
                domain: nil,
                message: "Fullscreen detection requires macOS 14.0 or later"
            )
        }

        guard VersionUtil.isScreenCaptureKitAvailable() else {
            throw CaptureError.unsupportedMacOSVersion(
                code: nil,
                domain: nil,
                message: "macOS version does not support ScreenCaptureKit"
            )
        }

        let availableContent = try await SCShareableContent.current

        guard
            let targetWindow = availableContent.windows.first(where: { window in
                window.windowID == CGWindowID(windowId)
            })
        else {
            throw CaptureError.invalidWindowId(
                code: nil,
                domain: nil,
                message: "Window with the specified ID was not found"
            )
        }

        return isFullscreenWindow(targetWindow.frame)
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

    /// 윈도우가 전체화면인지 확인
    private static func isFullscreenWindow(_ windowFrame: CGRect) -> Bool {
        // 메인 스크린과 비교
        if let mainScreen = NSScreen.main {
            let screenFrame = mainScreen.frame
            if windowFrame.size.width == screenFrame.size.width
                && windowFrame.size.height == screenFrame.size.height
                && windowFrame.origin.x == screenFrame.origin.x
                && windowFrame.origin.y == screenFrame.origin.y
            {
                return true
            }
        }

        // 멀티 디스플레이 환경에서 다른 스크린들과 비교
        for screen in NSScreen.screens {
            let screenFrame = screen.frame
            if windowFrame.size.width == screenFrame.size.width
                && windowFrame.size.height == screenFrame.size.height
                && windowFrame.origin.x == screenFrame.origin.x
                && windowFrame.origin.y == screenFrame.origin.y
            {
                return true
            }
        }

        return false
    }

    // 윈도우 정보를 가져오는 헬퍼 메서드
    private static func getWindowInfo(windowId: Int) -> [String: Any]? {
        guard
            let windowList = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID)
                as? [[String: Any]]
        else {
            return nil
        }

        return windowList.first { window in
            guard let wid = window[kCGWindowNumber as String] as? Int else { return false }
            return wid == windowId
        }
    }

    // Return list of capturable windows
    static func getCapturableWindows() async throws -> [[String: Any]] {
        // Check Screen Recording permission
        let permissionHandler = PermissionHandler()
        guard permissionHandler.hasScreenRecordingPermission() else {
            throw CaptureError.screenRecordingPermissionDenied(
                code: nil,
                domain: nil,
                message: "Screen recording permission is required for window capture"
            )
        }

        guard VersionUtil.isScreenCaptureKitAvailable() else {
            throw CaptureError.unsupportedMacOSVersion(
                code: nil,
                domain: nil,
                message: "macOS version does not support ScreenCaptureKit"
            )
        }

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
            // Analyze NSError to provide more specific error information
            let nsError = error as NSError

            // Check known permission error codes first (regardless of domain)
            if nsError.code == -3801 || nsError.code == -3803 {
                throw CaptureError.screenRecordingPermissionDenied(
                    code: nsError.code,
                    domain: nsError.domain,
                    message: error.localizedDescription
                )
            }

            // Check for ScreenCaptureKit specific errors (domain contains screencapturekit)
            if nsError.domain.lowercased().contains("screencapturekit") {
                // Also check error description for permission-related keywords
                let errorMessage = error.localizedDescription.lowercased()
                if errorMessage.contains("permission") || errorMessage.contains("not permitted")
                    || errorMessage.contains("denied")
                {
                    throw CaptureError.screenRecordingPermissionDenied(
                        code: nsError.code,
                        domain: nsError.domain,
                        message: error.localizedDescription
                    )
                }

                // Other ScreenCaptureKit errors
                throw CaptureError.captureFailed(
                    code: nsError.code,
                    domain: nsError.domain,
                    message: error.localizedDescription
                )
            }

            // Check for CoreGraphics/System errors that might indicate permission issues
            if nsError.domain == NSCocoaErrorDomain || nsError.domain == NSOSStatusErrorDomain {
                let errorMessage = error.localizedDescription.lowercased()
                if errorMessage.contains("permission") || errorMessage.contains("not permitted")
                    || errorMessage.contains("denied")
                {
                    throw CaptureError.screenRecordingPermissionDenied(
                        code: nsError.code,
                        domain: nsError.domain,
                        message: error.localizedDescription
                    )
                }
            }

            throw CaptureError.captureFailed(
                code: nsError.code,
                domain: nsError.domain,
                message: error.localizedDescription
            )
        }
    }

    // Helper method to pass errors to Flutter
    static func handleCaptureError(_ error: CaptureError) -> [String: Any] {
        switch error {
        case .screenCaptureKitNotAvailable(let code, let domain, let message):
            return [
                "code": "SCREENCAPTUREKIT_NOT_AVAILABLE",
                "message": message,
                "details": "Requires macOS 12.3 or later",
                "errorCode": code ?? NSNull(),
                "errorDomain": domain ?? NSNull(),
            ]
        case .invalidWindowId(let code, let domain, let message):
            return [
                "code": "INVALID_WINDOW_ID",
                "message": message,
                "details": NSNull(),
                "errorCode": code ?? NSNull(),
                "errorDomain": domain ?? NSNull(),
            ]
        case .windowMinimized(let code, let domain, let message):
            return [
                "code": "WINDOW_MINIMIZED",
                "message": message,
                "details":
                    "The window is currently minimized. Please restore the window to capture it.",
                "errorCode": code ?? NSNull(),
                "errorDomain": domain ?? NSNull(),
            ]
        case .captureNotSupported(let code, let domain, let message):
            return [
                "code": "CAPTURE_NOT_SUPPORTED",
                "message": message,
                "details": NSNull(),
                "errorCode": code ?? NSNull(),
                "errorDomain": domain ?? NSNull(),
            ]
        case .captureFailed(let code, let domain, let message):
            return [
                "code": "CAPTURE_FAILED",
                "message": message,
                "details": message,
                "errorCode": code ?? NSNull(),
                "errorDomain": domain ?? NSNull(),
            ]
        case .unsupportedMacOSVersion(let code, let domain, let message):
            return [
                "code": "UNSUPPORTED_MACOS_VERSION",
                "message": message,
                "details": "Current version: \(VersionUtil.getMacOSVersion()), Required: 12.3+",
                "errorCode": code ?? NSNull(),
                "errorDomain": domain ?? NSNull(),
            ]
        case .requiresMacOS14(let code, let domain, let message):
            return [
                "code": "REQUIRES_MACOS_14",
                "message": message,
                "details": "Current version: \(VersionUtil.getMacOSVersion()), Required: 14.0+",
                "errorCode": code ?? NSNull(),
                "errorDomain": domain ?? NSNull(),
            ]
        case .screenRecordingPermissionDenied(let code, let domain, let message):
            return [
                "code": "SCREEN_RECORDING_PERMISSION_DENIED",
                "message": message,
                "details":
                    "Please grant screen recording permission in System Settings > Privacy & Security > Screen Recording",
                "errorCode": code ?? NSNull(),
                "errorDomain": domain ?? NSNull(),
            ]
        }
    }
}
