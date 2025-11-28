//
//  ModelDetailView.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/20/25.
//

import SwiftUI
import SceneKit
import UIKit
import SwiftData
import ARKit

struct ModelDetailView: View {
    let model: ScanModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            if model.filePath.hasSuffix(".arobject") {
                Text("파일 유형: AR Reference Object (.arobject)")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.orange)
                
                Text("이 파일은 AR 세션에서 물체를 인식하기 위한 메타데이터 파일입니다. 3D 모델(.obj) 파일이 아니므로, 현재 앱에서는 3D 뷰어로 직접 표시할 수 없습니다.")
                    .font(.body)
                    .padding(.bottom)
                
                Divider()
                
            } else {
                SceneKitView(modelPath: model.filePath)
                    .frame(height: 300)
                    .cornerRadius(10)
                    .padding()
            }
            
            // 모델 정보 표시
            HStack {
                Text("파일 이름:")
                    .bold()
                Spacer()
                Text(model.fileName)
            }
            HStack {
                Text("경로:")
                    .bold()
                Spacer()
                Text(model.filePath)
                    .lineLimit(1)
            }
            HStack {
                Text("생성일:")
                    .bold()
                Spacer()
                Text(model.createdAt.formatted(date: .abbreviated, time: .shortened))
            }
            HStack {
                Text("저장된 앵커/메쉬:")
                    .bold()
                Spacer()
                Text("\(model.meshCount) 개")
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle(model.fileName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: shareModel) {
                    Image(systemName: "square.and.arrow.up")
                }
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
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true, completion: nil)
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
