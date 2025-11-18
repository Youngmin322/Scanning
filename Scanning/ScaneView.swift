//
//  ContentView.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/15/25.
//

import SwiftUI
import RealityKit
import ARKit
import ComposableArchitecture

struct ScaneView: View {
    let store: StoreOf<ScaneFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                ARViewContainer(isScanning: viewStore.isScanning)
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    HStack(spacing: 40) {
                        Button(action: {
                            store.send(.scanButtonTapped)
                        }) {
                            Image(systemName: viewStore.isScanning ? "stop.fill" : "viewfinder")
                                .font(.system(size: 35))
                                .foregroundColor(viewStore.isScanning ? .red : .gray)
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                                .glassEffect(in: Circle())
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    let isScanning: Bool
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = .meshWithClassification
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            print("LiDAR 지원됨(Scene Reconstruction 활성화)")
            config.sceneReconstruction = .meshWithClassification
        } else {
            print("LiDAR 지원 안 됨")
        }
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            print("Scene Depth 지원됨")
            config.frameSemantics.insert(.sceneDepth)
        } else {
            print("scene Depth 지원 안 됨")
        }
        
        arView.debugOptions = [.showSceneUnderstanding]
        
        arView.session.delegate = context.coordinator
        arView.session.run(config)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        print("ARview 업데이트: isScanning = \(isScanning)")
        
        context.coordinator.isScanning = isScanning
        
        if isScanning {
            print("스캔 시작")
        } else {
            print("스캔 정지")
        }
    }
    
    func dismantleUIView(_ uiView: ARView, coordinator: ()) {
        uiView.session.pause()
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var isScanning = false
        var meshAnchors: [ARMeshAnchor] = [] // 수집한 메쉬 데이터를 담는 배열
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard isScanning else { return }
            
            let newMeshAnchors = anchors.compactMap { $0 as? ARMeshAnchor }
            meshAnchors.append(contentsOf: newMeshAnchors)
            print("새 메쉬 추가: \(newMeshAnchors.count), 총: \(meshAnchors.count)개")
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            guard isScanning else { return }
            
            let updatedMeshAnchors = anchors.compactMap { $0 as? ARMeshAnchor }
            print("메쉬 업데이트: \(updatedMeshAnchors.count)")
        }
    }
}

#Preview {
    ContentView()
}
