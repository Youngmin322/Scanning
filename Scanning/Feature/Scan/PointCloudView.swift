//
//  PointCloudView.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/28/25.
//

import SwiftUI
import SceneKit
import ARKit

// 스캔된 점 구름을 시각적으로 표시하는 3D 뷰
struct PointCloudView: UIViewRepresentable {
    
    // ARViewContainer의 Coordinator를 통해 ARSessionDelegate가 이 뷰의 Coordinator를 업데이트
    let coordinator: PointCloudCoordinator

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = SCNScene()
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = true // 사용자가 3D 모델을 돌려볼 수 있게 허용
        scnView.backgroundColor = UIColor.clear // ARView가 아래에 보이도록 배경 투명 설정
        
        // 카메라 설정
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0.2, 0.5) // 카메라 위치 조정
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scnView.scene?.rootNode.addChildNode(cameraNode)
        
        // Coordinator에 SCNView 레퍼런스 전달
        context.coordinator.scnView = scnView
        
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
    }
    
    func makeCoordinator() -> PointCloudCoordinator {
        coordinator
    }
}

// PointCloudView의 SCNView를 관리하고 점 구름 데이터를 렌더링하는 클래스
class PointCloudCoordinator: NSObject {
    var accumulatedPoints: [SIMD3<Float>] = []
    var scnView: SCNView?
    var pointCloudNode: SCNNode?

    // ScaneView.Coordinator의 ARSessionDelegate에서 호출될 함수
    func updatePointCloud(newFrame: ARFrame) {
        guard let points = newFrame.rawFeaturePoints?.points else { return }
        
        // 새 특징점을 누적된 점 구름에 추가합니다.
        for point in points {
            self.accumulatedPoints.append(point)
        }
        
        // 렌더링은 메인 스레드에서 처리
        DispatchQueue.main.async {
            self.renderPoints()
        }
    }
    
    private func renderPoints() {
        guard let scnView = scnView, !accumulatedPoints.isEmpty else { return }
        
        // 이전 노드를 제거하고 새로운 노드를 생성
        self.pointCloudNode?.removeFromParentNode()
        
        let parentNode = SCNNode()
        
        // SIMD3<Float> 배열을 SCNVector3 배열로 변환
        let positions = accumulatedPoints.map { point in
            SCNVector3(point.x, point.y, point.z)
        }
        
        // SCNGeometrySource를 생성하여 위치 데이터 제공
        let vertexSource = SCNGeometrySource(vertices: positions)
        
        // 인덱스 배열 생성
        var indices: [Int32] = Array(0..<Int32(positions.count))
        let element = SCNGeometryElement(indices: indices, primitiveType: .point) // 점으로 렌더링
        
        let pointCloudGeometry = SCNGeometry(sources: [vertexSource], elements: [element])
        
        // 점 구름 시각화 설정
        let material = SCNMaterial()
        // 스캔된 부분을 시각적으로 채워 보이게 하기 위해 흰색 또는 밝은 색 사용
        material.diffuse.contents = UIColor.white
        pointCloudGeometry.materials = [material]
        
        parentNode.geometry = pointCloudGeometry
    }
}
