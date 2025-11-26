//
//  ModelDetailView.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/20/25.
//

import SwiftUI
import SceneKit
import UIKit

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
                SceneKitView(modelPath: model.filePath)
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
            if FileManager.default.fileExists(atPath: model.filePath) {
                isLoading = false
            } else {
                loadError = "파일을 찾을 수 없습니다: \(model.filePath)"
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

struct SceneKitView: UIViewRepresentable {
    let modelPath: String
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .black
        scnView.allowsCameraControl = true  // 손가락으로 회전/확대/축소
        scnView.autoenablesDefaultLighting = true  // 자동 조명
        scnView.showsStatistics = true  // FPS 등 통계 표시
        
        let scene = SCNScene()
        
        // OBJ/USDZ 파일 로드
        if let modelURL = URL(string: "file://\(modelPath)"),
           let loadedScene = try? SCNScene(url: modelURL, options: nil) {
            
            if let rootNode = loadedScene.rootNode.childNodes.first {
                scene.rootNode.addChildNode(rootNode)
                
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
            }
            
            print("모델 파일 로드 성공: \(modelURL.lastPathComponent)")
        } else {
            print("모델 파일 로드 실패: \(modelPath)")
        }
        
        scnView.scene = scene
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
    }
}
