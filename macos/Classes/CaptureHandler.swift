import Cocoa
import Foundation
import ScreenCaptureKit

@available(macOS 12.3, *)
class CaptureHandler {

    enum CaptureError: Error {
        case screenCaptureKitNotAvailable
        case invalidWindowId
        case captureNotSupported
        case captureFailed(String)
        case unsupportedMacOSVersion
        case requiresMacOS14
    }

    static func captureWindow(windowId: Int, excludeTitlebar: Bool = false) async throws -> Data {
        // macOS 버전 확인 - SCScreenshotManager는 macOS 14.0+에서만 사용 가능
        guard #available(macOS 14.0, *) else {
            throw CaptureError.requiresMacOS14
        }

        guard VersionUtil.isScreenCaptureKitAvailable() else {
            throw CaptureError.unsupportedMacOSVersion
        }

        do {
            // 캡처 가능한 콘텐츠 가져오기
            let availableContent = try await SCShareableContent.current

            // 특정 window ID 찾기
            guard
                let targetWindow = availableContent.windows.first(where: { window in
                    window.windowID == CGWindowID(windowId)
                })
            else {
                throw CaptureError.invalidWindowId
            }

            // 캡처 설정
            let configuration = SCStreamConfiguration()
            configuration.width = Int(targetWindow.frame.width)
            configuration.height = Int(targetWindow.frame.height)
            configuration.capturesAudio = false  // macOS 14.0+에서는 문제없음
            configuration.showsCursor = false
            configuration.scalesToFit = false
            configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)

            // 캡처 필터 설정 (특정 창만 캡처)
            let filter = SCContentFilter(desktopIndependentWindow: targetWindow)

            // 캡처 실행 - macOS 14.0+에서 SCScreenshotManager 사용
            let screenshot = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: configuration
            )

            // Titlebar 제외가 요청된 경우 이미지를 crop
            let finalImage: CGImage
            if excludeTitlebar {
                // Get content bounds excluding titlebar
                let contentBounds =
                    CaptureUtil.getWindowContentBounds(
                        windowId: windowId,
                        windowBounds: targetWindow.frame
                    )
                    ?? CGRect(
                        x: targetWindow.frame.origin.x,
                        y: targetWindow.frame.origin.y + 28,
                        width: targetWindow.frame.width,
                        height: targetWindow.frame.height - 28
                    )

                // Calculate crop rectangle (titlebar height from top)
                let titlebarHeight = targetWindow.frame.height - contentBounds.height
                let cropRect = CGRect(
                    x: 0,
                    y: titlebarHeight,
                    width: targetWindow.frame.width,
                    height: contentBounds.height
                )

                guard let croppedImage = screenshot.cropping(to: cropRect) else {
                    throw CaptureError.captureFailed("Failed to crop titlebar from image")
                }
                finalImage = croppedImage
            } else {
                finalImage = screenshot
            }

            // CGImage를 PNG 데이터로 변환
            guard let pngData = convertCGImageToPNG(finalImage) else {
                throw CaptureError.captureFailed("Failed to convert image to PNG")
            }

            return pngData

        } catch let error as CaptureError {
            throw error
        } catch {
            throw CaptureError.captureFailed(error.localizedDescription)
        }
    }

    private static func convertCGImageToPNG(_ cgImage: CGImage) -> Data? {
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .png, properties: [:])
    }

    // 캡처 가능한 창 목록 반환
    static func getCapturableWindows() async throws -> [[String: Any]] {
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

    // 에러를 Flutter에 전달하기 위한 헬퍼 메서드
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
        }
    }
}
