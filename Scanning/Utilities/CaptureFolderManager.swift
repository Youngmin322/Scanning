import Foundation

class CaptureFolderManager {
    // 캡처와 관련된 모든 데이터가 저장될 최상위 폴더
    let captureFolder: URL
    // 이미지가 저장될 폴더
    let imagesFolder: URL
    // 모델링 결과물이 저장될 폴더
    let modelsFolder: URL

    init() {
        // 문서 디렉토리에 'Scans'라는 폴더를 생성
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let scanBase = documents.appendingPathComponent("Scans")
        
        // 현재 시간을 이름으로 하는 폴더를 만듦
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: Date())
        captureFolder = scanBase.appendingPathComponent(timestamp)
        
        imagesFolder = captureFolder.appendingPathComponent("Images")
        modelsFolder = captureFolder.appendingPathComponent("Models")
        
        // 실제 폴더 생성
        do {
            try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: modelsFolder, withIntermediateDirectories: true)
            print("저장 경로 생성 완료: \(captureFolder.path)")
        } catch {
            print("폴더 생성 실패: \(error)")
        }
    }
}
