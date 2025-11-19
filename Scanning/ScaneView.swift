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
                ARViewContainer(
                    isScanning: viewStore.isScanning,
                    store: store,
                    shouldSave: viewStore.shouldSave
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    if viewStore.isScanning {
                        HStack {
                            Text("스캔된 메쉬: \(viewStore.meshCount)")
                                .font(.headline)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                        }
                        .padding(.top, 50)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 40) {
                        Button(action: {
                            viewStore.send(.scanButtonTapped)
                        }) {
                            Image(systemName: viewStore.isScanning ? "stop.fill" : "viewfinder")
                                .font(.system(size: 35))
                                .foregroundColor(viewStore.isScanning ? .red : .gray)
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                                .glassEffect(in: Circle())
                        }
                        
                        if viewStore.isScanning {
                            Button(action: {
                                viewStore.send(.completeScan)
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.green)
                                    .frame(width: 70, height: 70)
                                    .clipShape(Circle())
                                    .glassEffect(in: Circle())
                            }
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    let isScanning: Bool
    let store: StoreOf<ScaneFeature>
    let shouldSave: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
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
        context.coordinator.store = store
        
        if isScanning {
            print("스캔 시작")
        } else {
            print("스캔 정지")
        }
        
        if shouldSave && !context.coordinator.hasSaved {
            context.coordinator.saveMeshToOBJ()
            context.coordinator.hasSaved = true
        }
    }
    
    func dismantleUIView(_ uiView: ARView, coordinator: ()) {
        uiView.session.pause()
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var isScanning = false
        var meshAnchors: [ARMeshAnchor] = [] // 수집한 메쉬 데이터를 담는 배열
        var store: StoreOf<ScaneFeature>?
        var hasSaved = false
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard isScanning else { return }
            
            let newMeshAnchors = anchors.compactMap { $0 as? ARMeshAnchor }
            meshAnchors.append(contentsOf: newMeshAnchors)
            print("새 메쉬 추가: \(newMeshAnchors.count), 총: \(meshAnchors.count)개")
            
            store?.send(.updateMeshCount(meshAnchors.count))
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            guard isScanning else { return }
            
            let updatedMeshAnchors = anchors.compactMap { $0 as? ARMeshAnchor }
            print("메쉬 업데이트: \(updatedMeshAnchors.count)")
        }
        
        func saveMeshToOBJ() {
            guard !meshAnchors.isEmpty else {
                print("저장할 메쉬 없음")
                return
            }
            
            if let fileURL = MeshExporter.exportToOBJ(meshAnchors: meshAnchors) {
                print("저장 완료: \(fileURL.lastPathComponent)")
            }
        }
    }
}

#Preview {
    ContentView()
}
