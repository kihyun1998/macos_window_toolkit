import Cocoa
import Foundation

class LegacyCaptureHandler {
    
    enum LegacyCaptureError: Error {
        case invalidWindowId
        case captureNotSupported
        case captureFailed(String)
        case noImageData
    }
    
    // CGWindowListCreateImage를 사용한 윈도우 캡쳐 (macOS 10.5+)
    static func captureWindow(windowId: Int) throws -> Data {
        // CGWindowID로 변환
        let cgWindowId = CGWindowID(windowId)
        
        // 윈도우 캡쳐 옵션 설정
        let imageOption: CGWindowImageOption = [
            .nominalResolution,        // 표준 해상도
            .boundsIgnoreFraming,      // 프레임 무시하고 내용만
            .shouldBeOpaque            // 불투명하게
        ]
        
        // 리스트 옵션 (특정 윈도우만)
        let listOption: CGWindowListOption = [
            .optionIncludingWindow     // 지정된 윈도우 포함
        ]
        
        // 윈도우 캡쳐 실행
        guard let cgImage = CGWindowListCreateImage(
            CGRect.null,               // 전체 윈도우 영역
            listOption,
            cgWindowId,
            imageOption
        ) else {
            // 캡쳐 실패 시 윈도우 존재 여부 확인
            if !isWindowExists(windowId: windowId) {
                throw LegacyCaptureError.invalidWindowId
            } else {
                throw LegacyCaptureError.captureFailed("Failed to create window image")
            }
        }
        
        // CGImage를 PNG 데이터로 변환
        guard let pngData = convertCGImageToPNG(cgImage) else {
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
    
    // CGImage를 PNG 데이터로 변환
    private static func convertCGImageToPNG(_ cgImage: CGImage) -> Data? {
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .png, properties: [:])
    }
    
    // 캡쳐 가능한 윈도우 목록 반환 (CGWindowListCopyWindowInfo 사용)
    static func getCapturableWindows() -> [[String: Any]] {
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
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
                "bundleIdentifier": "", // CGWindowListCopyWindowInfo에서는 번들 ID 제공 안함
                "frame": [
                    "x": x,
                    "y": y,
                    "width": width,
                    "height": height,
                ],
                "isOnScreen": true, // optionOnScreenOnly로 필터링했으므로 항상 true
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
        }
    }
}