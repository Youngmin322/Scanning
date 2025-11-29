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
            
            SceneKitView(modelPath: model.filePath)
                .frame(height: 300)
                .cornerRadius(10)
                .padding()
            
            Divider()
            
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
                Text("특징점 수 (스캔 품질):")
                    .bold()
                Spacer()
                Text("\(model.vertextCount)")
            }
            
            // .arobject 파일임을 안내하는 메시지
            if model.filePath.hasSuffix(".arobject") {
                Text("⚠️ 이 뷰는 저장된 AR Reference Object(.arobject)의 **경계 상자(Bounding Box)**를 나타냅니다. 실제 3D 메쉬 모델이 아닙니다.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 10)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("모델 상세 정보")
    }
}

// ARReferenceObject의 Extent를 시각화하는 SceneKit 뷰
struct SceneKitView: UIViewRepresentable {
    let modelPath: String
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.backgroundColor = UIColor.systemBackground

        let scene = SCNScene()
        
        // MARK: - .arobject 파일 처리 로직 (스캔 결과 시각화)
        if modelPath.hasSuffix(".arobject"),
           let modelURL = URL(string: "file://\(modelPath)"),
           let referenceObject = try? ARReferenceObject(archiveURL: modelURL)
        {
            print("ARReferenceObject 파일 로드 성공: \(modelURL.lastPathComponent)")

            let extent = referenceObject.extent
            
            // Extent를 사용하여 박스 노드 생성 (와이어프레임 시각화)
            let boxGeometry = SCNBox(
                width: CGFloat(extent.x),
                height: CGFloat(extent.y),
                length: CGFloat(extent.z),
                chamferRadius: 0.0
            )
            
            let boxNode = SCNNode(geometry: boxGeometry)
            boxNode.geometry?.firstMaterial?.fillMode = .lines
            boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue // 색상
            boxNode.position = SCNVector3(0, 0, 0) // 중심에 배치
            scene.rootNode.addChildNode(boxNode)
            
            // 카메라 설정 (물체 크기에 맞게)
            let maxSize = Swift.max(extent.x, Swift.max(extent.y, extent.z))
            
            let cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            cameraNode.position = SCNVector3(0, maxSize * 0.5, maxSize * 2.0)
            cameraNode.look(at: SCNVector3(0, 0, 0))
            scene.rootNode.addChildNode(cameraNode)
            
        }
        // MARK: - 일반 3D 모델 파일 처리 로직
        else if let modelURL = URL(string: "file://\(modelPath)"),
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
            print("모델 파일 로드 실패: 지원하지 않는 형식 또는 파일 없음 (\(modelPath))")
        }
        
        scnView.scene = scene
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}
