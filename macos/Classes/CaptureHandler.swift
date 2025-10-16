import Cocoa
import Foundation
import ScreenCaptureKit

@available(macOS 12.3, *)
class CaptureHandler {

    enum CaptureError: Error {
        case screenCaptureKitNotAvailable
        case invalidWindowId
        case windowMinimized
        case captureNotSupported
        case captureFailed(String)
        case unsupportedMacOSVersion
        case requiresMacOS14
        case screenRecordingPermissionDenied
    }

    static func captureWindow(
        windowId: Int, excludeTitlebar: Bool = false, customTitlebarHeight: CGFloat? = nil,
        targetWidth: Int? = nil, targetHeight: Int? = nil, preserveAspectRatio: Bool = false
    ) async throws -> Data {
        // Check Screen Recording permission
        let permissionHandler = PermissionHandler()
        guard permissionHandler.hasScreenRecordingPermission() else {
            throw CaptureError.screenRecordingPermissionDenied
        }
        
        // Check macOS version - SCScreenshotManager is only available on macOS 14.0+
        guard #available(macOS 14.0, *) else {
            throw CaptureError.requiresMacOS14
        }

        guard VersionUtil.isScreenCaptureKitAvailable() else {
            throw CaptureError.unsupportedMacOSVersion
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
                throw CaptureError.invalidWindowId
            }
            
            // Re-check minimized state in SCWindow (prevent ScreenCaptureKit from waiting)
            if !targetWindow.isOnScreen {
                throw CaptureError.windowMinimized
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
                    throw CaptureError.captureFailed("Failed to crop titlebar from image")
                }
                finalImage = croppedImage
            } else {
                finalImage = screenshot
            }

            // Resize if needed
            let imageToConvert: CGImage
            if let width = targetWidth, let height = targetHeight {
                let resized: CGImage?
                if preserveAspectRatio {
                    // Preserve aspect ratio, fill extra space with black
                    resized = resizeImagePreservingAspectRatio(
                        finalImage,
                        targetWidth: width,
                        targetHeight: height
                    )
                } else {
                    // Force exact size resize (may distort image)
                    resized = resizeImageToExactSize(
                        finalImage,
                        targetWidth: width,
                        targetHeight: height
                    )
                }

                guard let finalResized = resized else {
                    throw CaptureError.captureFailed("Failed to resize image")
                }
                imageToConvert = finalResized
            } else {
                imageToConvert = finalImage
            }

            // CGImage를 PNG 데이터로 변환
            guard let pngData = convertCGImageToPNG(imageToConvert) else {
                throw CaptureError.captureFailed("Failed to convert image to PNG")
            }

            return pngData

        } catch let error as CaptureError {
            throw error
        } catch {
            throw CaptureError.captureFailed(error.localizedDescription)
        }
    }

    // Resize CGImage to exact target size (ignoring aspect ratio)
    private static func resizeImageToExactSize(
        _ image: CGImage,
        targetWidth: Int,
        targetHeight: Int
    ) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: nil,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
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

        guard let context = CGContext(
            data: nil,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
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
            throw CaptureError.screenRecordingPermissionDenied
        }
        
        guard VersionUtil.isScreenCaptureKitAvailable() else {
            throw CaptureError.unsupportedMacOSVersion
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
            throw CaptureError.captureFailed(error.localizedDescription)
        }
    }

    // Helper method to pass errors to Flutter
    static func handleCaptureError(_ error: CaptureError) -> [String: Any] {
        switch error {
        case .screenCaptureKitNotAvailable:
            return [
                "code": "SCREENCAPTUREKIT_NOT_AVAILABLE",
                "message": "ScreenCaptureKit is not available on this macOS version",
                "details": "Requires macOS 12.3 or later",
            ]
        case .invalidWindowId:
            return [
                "code": "INVALID_WINDOW_ID",
                "message": "Window with the specified ID was not found",
                "details": NSNull(),
            ]
        case .windowMinimized:
            return [
                "code": "WINDOW_MINIMIZED",
                "message": "Window is minimized and cannot be captured",
                "details":
                    "The window is currently minimized. Please restore the window to capture it.",
            ]
        case .captureNotSupported:
            return [
                "code": "CAPTURE_NOT_SUPPORTED",
                "message": "Window capture is not supported for this window",
                "details": NSNull(),
            ]
        case .captureFailed(let description):
            return [
                "code": "CAPTURE_FAILED",
                "message": "Window capture failed",
                "details": description,
            ]
        case .unsupportedMacOSVersion:
            return [
                "code": "UNSUPPORTED_MACOS_VERSION",
                "message": "macOS version does not support ScreenCaptureKit",
                "details": "Current version: \(VersionUtil.getMacOSVersion()), Required: 12.3+",
            ]
        case .requiresMacOS14:
            return [
                "code": "REQUIRES_MACOS_14",
                "message": "Window capture requires macOS 14.0 or later",
                "details": "Current version: \(VersionUtil.getMacOSVersion()), Required: 14.0+",
            ]
        case .screenRecordingPermissionDenied:
            return [
                "code": "SCREEN_RECORDING_PERMISSION_DENIED",
                "message": "Screen recording permission is required for window capture",
                "details": "Please grant screen recording permission in System Settings > Privacy & Security > Screen Recording",
            ]
        }
    }
}
