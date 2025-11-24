//
//  ModelDetailView.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/20/25.
//

import SwiftUI
import SceneKit

struct ModelDetailView: View {
    let model: ScanModel
    @State private var isLoading = true
    @State private var loadError: String?
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("모델 로딩 중...")
            } else if let error = loadError {
                ContentUnavailableView(
                    "로딩 실패",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                SceneKitView(objPath: model.filePath)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .navigationTitle(model.fileName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: shareModel) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .task {
            // 파일 존재 확인
            if FileManager.default.fileExists(atPath: model.filePath) {
                isLoading = false
            } else {
                loadError = "파일을 찾을 수 없습니다"
                isLoading = false
            }
        }
    }
    
    private func shareModel() {
        let fileURL = URL(fileURLWithPath: model.filePath)
        let activityVC = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// 🆕 SceneKit으로 OBJ 파일 표시
struct SceneKitView: UIViewRepresentable {
    let objPath: String
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .black
        scnView.allowsCameraControl = true  // 손가락으로 회전/확대/축소
        scnView.autoenablesDefaultLighting = true  // 자동 조명
        scnView.showsStatistics = true  // FPS 등 통계 표시
        
        // Scene 생성
        let scene = SCNScene()
        
        // OBJ 파일 로드
        if let objURL = URL(string: "file://\(objPath)"),
           let objScene = try? SCNScene(url: objURL, options: nil) {
            
            // OBJ의 모든 노드를 메인 씬에 추가
            if let rootNode = objScene.rootNode.childNodes.first {
                scene.rootNode.addChildNode(rootNode)
                
                // 모델 중심으로 카메라 배치
                let (minVec, maxVec) = rootNode.boundingBox
                let center = SCNVector3(
                    (minVec.x + maxVec.x) / 2,
                    (minVec.y + maxVec.y) / 2,
                    (minVec.z + maxVec.z) / 2
                )

                let size = SCNVector3(
                    maxVec.x - minVec.x,
                    maxVec.y - minVec.y,
                    maxVec.z - minVec.z
                )
                let maxSize = Swift.max(size.x, Swift.max(size.y, size.z))
                
                // 카메라 노드
                let cameraNode = SCNNode()
                cameraNode.camera = SCNCamera()
                cameraNode.position = SCNVector3(
                    center.x,
                    center.y,
                    center.z + maxSize * 2
                )
                cameraNode.look(at: center)
                scene.rootNode.addChildNode(cameraNode)
                
                // Material 설정 (회색)
                rootNode.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
                rootNode.geometry?.firstMaterial?.lightingModel = .physicallyBased
            }
            
            print("✅ OBJ 파일 로드 성공")
        } else {
            print("❌ OBJ 파일 로드 실패: \(objPath)")
        }
        
        scnView.scene = scene
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // 업데이트 필요 없음
    }
}

//#Preview {
//    NavigationStack {
//        ModelDetailView(
//            model: ScanModel(
//                fileName: "test.obj",
//                filePath: "/path/to/test.obj",
//                meshCount: 5,
//                vertexCount: 1000
//            )
//        )
//    }
//}
