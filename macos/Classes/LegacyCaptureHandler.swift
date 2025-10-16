import Cocoa
import Foundation

class LegacyCaptureHandler {

    enum LegacyCaptureError: Error {
        case invalidWindowId
        case windowMinimized
        case captureNotSupported
        case captureFailed(String)
        case noImageData
        case screenRecordingPermissionDenied
    }

    // Window capture using CGWindowListCreateImage (macOS 10.5+)
    static func captureWindow(
        windowId: Int, excludeTitlebar: Bool = false, customTitlebarHeight: CGFloat? = nil,
        targetWidth: Int? = nil, targetHeight: Int? = nil, preserveAspectRatio: Bool = false
    ) throws -> Data {
        // Check Screen Recording permission (macOS 10.15+)
        if #available(macOS 10.15, *) {
            let permissionHandler = PermissionHandler()
            guard permissionHandler.hasScreenRecordingPermission() else {
                throw LegacyCaptureError.screenRecordingPermissionDenied
            }
        }
        
        // Convert to CGWindowID
        let cgWindowId = CGWindowID(windowId)

        // Check window existence and minimized state before capture
        if !isWindowExists(windowId: windowId) {
            throw LegacyCaptureError.invalidWindowId
        } else if isWindowMinimized(windowId: windowId) {
            throw LegacyCaptureError.windowMinimized
        }

        // Set window capture options
        let imageOption: CGWindowImageOption = [
            .nominalResolution,  // 표준 해상도
            .boundsIgnoreFraming,  // 프레임 무시하고 내용만
            .shouldBeOpaque,  // 불투명하게
        ]

        // 리스트 옵션 (특정 윈도우만)
        let listOption: CGWindowListOption = [
            .optionIncludingWindow  // 지정된 윈도우 포함
        ]

        // 윈도우 캡쳐 실행
        guard
            let cgImage = CGWindowListCreateImage(
                CGRect.null,  // 전체 윈도우 영역
                listOption,
                cgWindowId,
                imageOption
            )
        else {
            throw LegacyCaptureError.captureFailed("Failed to create window image")
        }

        // Titlebar 제외가 요청된 경우 이미지를 crop
        let finalImage: CGImage
        if excludeTitlebar {
            // 윈도우 정보 가져와서 frame 얻기
            guard let windowFrame = getWindowFrame(windowId: windowId) else {
                throw LegacyCaptureError.captureFailed("Failed to get window frame information")
            }

            // 전체화면에서는 타이틀바가 없으므로 항상 0으로 설정
            let titlebarHeight: CGFloat
            if isFullscreenWindow(windowFrame) {
                titlebarHeight = 0.0
            } else {
                // 일반 윈도우에서는 custom 값 또는 기본값(28px) 사용
                let requestedHeight = customTitlebarHeight ?? 28.0
                titlebarHeight = max(0, min(requestedHeight, windowFrame.height))
            }

            let cropRect = CGRect(
                x: 0,
                y: titlebarHeight,
                width: CGFloat(cgImage.width),
                height: CGFloat(cgImage.height) - titlebarHeight
            )

            guard let croppedImage = cgImage.cropping(to: cropRect) else {
                throw LegacyCaptureError.captureFailed("Failed to crop titlebar from image")
            }
            finalImage = croppedImage
        } else {
            finalImage = cgImage
        }

        // Resize if targetWidth and targetHeight are provided
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
                // Force exact size (may distort image)
                resized = resizeImageToExactSize(
                    finalImage,
                    targetWidth: width,
                    targetHeight: height
                )
            }

            guard let finalResized = resized else {
                throw LegacyCaptureError.captureFailed("Failed to resize image")
            }
            imageToConvert = finalResized
        } else {
            imageToConvert = finalImage
        }

        // CGImage를 PNG 데이터로 변환
        guard let pngData = convertCGImageToPNG(imageToConvert) else {
            throw LegacyCaptureError.noImageData
        }

        return pngData
    }

    // 윈도우 존재 여부 확인
    private static func isWindowExists(windowId: Int) -> Bool {
        let windowList = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]]

        return windowList?.contains { window in
            guard let wid = window[kCGWindowNumber as String] as? Int else { return false }
            return wid == windowId
        } ?? false
    }

    // 윈도우 최소화 상태 확인
    private static func isWindowMinimized(windowId: Int) -> Bool {
        // optionOnScreenOnly 옵션으로 화면에 보이는 윈도우만 가져오기
        let onScreenWindows =
            CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]]
            ?? []

        // 해당 윈도우 ID가 화면에 보이는 윈도우 목록에 없으면 최소화된 것
        let isOnScreenList = onScreenWindows.contains { window in
            guard let wid = window[kCGWindowNumber as String] as? Int else { return false }
            return wid == windowId
        }

        // 화면에 보이는 윈도우 목록에 없으면 최소화된 것으로 간주
        return !isOnScreenList
    }

    // 윈도우 정보를 가져와서 frame 반환
    private static func getWindowFrame(windowId: Int) -> CGRect? {
        let windowList = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]]

        guard
            let windowInfo = windowList?.first(where: { window in
                guard let wid = window[kCGWindowNumber as String] as? Int else { return false }
                return wid == windowId
            })
        else {
            return nil
        }

        guard let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: Any],
            let x = boundsDict["X"] as? Double,
            let y = boundsDict["Y"] as? Double,
            let width = boundsDict["Width"] as? Double,
            let height = boundsDict["Height"] as? Double
        else {
            return nil
        }

        return CGRect(x: x, y: y, width: width, height: height)
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

    // CGImage를 PNG 데이터로 변환
    private static func convertCGImageToPNG(_ cgImage: CGImage) -> Data? {
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .png, properties: [:])
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

    // 캡쳐 가능한 윈도우 목록 반환 (CGWindowListCopyWindowInfo 사용)
    static func getCapturableWindows() -> [[String: Any]] {
        // Check Screen Recording permission (macOS 10.15+)
        if #available(macOS 10.15, *) {
            let permissionHandler = PermissionHandler()
            guard permissionHandler.hasScreenRecordingPermission() else {
                return [] // 권한 없으면 빈 배열 반환
            }
        }
        
        guard
            let windowList = CGWindowListCopyWindowInfo(
                [.optionOnScreenOnly, .excludeDesktopElements],
                kCGNullWindowID
            ) as? [[String: Any]]
        else {
            return []
        }

        return windowList.compactMap { window in
            // 필수 정보 추출
            guard
                let windowId = window[kCGWindowNumber as String] as? Int,
                let ownerName = window[kCGWindowOwnerName as String] as? String,
                let boundsDict = window[kCGWindowBounds as String] as? [String: Any],
                let x = boundsDict["X"] as? Double,
                let y = boundsDict["Y"] as? Double,
                let width = boundsDict["Width"] as? Double,
                let height = boundsDict["Height"] as? Double
            else {
                return nil
            }

            // 윈도우 이름 (없을 수 있음)
            let title = window[kCGWindowName as String] as? String ?? ""

            // 최소 크기 필터 (너무 작은 윈도우 제외)
            guard width > 50 && height > 50 else { return nil }

            return [
                "windowId": windowId,
                "title": title,
                "ownerName": ownerName,
                "bundleIdentifier": "",  // CGWindowListCopyWindowInfo에서는 번들 ID 제공 안함
                "frame": [
                    "x": x,
                    "y": y,
                    "width": width,
                    "height": height,
                ],
                "isOnScreen": true,  // optionOnScreenOnly로 필터링했으므로 항상 true
            ]
        }
    }

    // 에러를 Flutter에 전달하기 위한 헬퍼 메서드
    static func handleLegacyCaptureError(_ error: LegacyCaptureError) -> [String: Any] {
        switch error {
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
        case .noImageData:
            return [
                "code": "CAPTURE_FAILED",
                "message": "Failed to convert captured image to PNG data",
                "details": NSNull(),
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
