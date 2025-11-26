//
//  ScaneView.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/15/25.
//

import SwiftUI
import RealityKit
import ARKit
import ComposableArchitecture
import SwiftData

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
    @Environment(\.modelContext) private var modelContext
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
            print("Scene Reconstruction (.mesh) 지원됨")
        } else {
            print("Scene Reconstruction (.mesh) 지원 안 됨")
        }
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            print("Scene Depth 지원됨")
            config.frameSemantics.insert(.sceneDepth)
        } else {
            print("Scene Depth 지원 안 됨")
        }
        
        arView.debugOptions = [.showFeaturePoints, .showSceneUnderstanding]
        
        arView.session.delegate = context.coordinator
        
        context.coordinator.modelContext = modelContext
        context.coordinator.arSession = arView.session
        
        arView.session.run(config)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        print("ARview 업데이트: isScanning = \(isScanning)")
        
        context.coordinator.isScanning = isScanning
        context.coordinator.store = store
        
        if isScanning {
            print("스캔 중. 메쉬 수집 활성화.")
        } else {
            print("스캔 정지. 메쉬 수집 비활성화.")
        }
        
        if shouldSave && !context.coordinator.hasSaved {
            context.coordinator.saveMeshToOBJ()
            context.coordinator.hasSaved = true
            // 저장 후 앵커 데이터 및 TCA 상태 초기화
            context.coordinator.meshAnchors.removeAll()
            context.coordinator.store?.send(.updateMeshCount(0))
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
        var modelContext: ModelContext?
        var arSession: ARSession? // ARSession 참조 추가
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard isScanning else { return }
            
            let newMeshAnchors = anchors.compactMap { $0 as? ARMeshAnchor }
            
            if !newMeshAnchors.isEmpty {
                meshAnchors.append(contentsOf: newMeshAnchors)
                print("새 메쉬 추가: \(newMeshAnchors.count), 총: \(meshAnchors.count)개")
                store?.send(.updateMeshCount(meshAnchors.count))
            }
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            guard isScanning else { return }
            
            let updatedMeshAnchors = anchors.compactMap { $0 as? ARMeshAnchor }
            
            for updatedAnchor in updatedMeshAnchors {
                if let index = meshAnchors.firstIndex(where: { $0.identifier == updatedAnchor.identifier }) {
                    meshAnchors[index] = updatedAnchor
                } else {
                    meshAnchors.append(updatedAnchor)
                }
            }
            
            if !updatedMeshAnchors.isEmpty {
            }
            
            store?.send(.updateMeshCount(meshAnchors.count))
        }
        
        func saveMeshToOBJ() {
            guard !meshAnchors.isEmpty else {
                print("저장할 메쉬 없음")
                return
            }
            
            if let result = MeshExporter.exportToOBJ(meshAnchors: meshAnchors) {
                let fileURL = result.url
                let vertexCount = result.vertextCount
                
                print("파일 저장됨: \(fileURL.lastPathComponent)")
                
                // SwiftData에 저장
                saveToSwiftData(fileURL: fileURL, vertextCount: vertexCount)
            }
        }
        
        private func saveToSwiftData(fileURL: URL, vertextCount: Int) {
            guard let modelContext = modelContext else { return }
            
            let dateString = Date().formatted(date: .numeric, time: .shortened)
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "")
                .replacingOccurrences(of: " ", with: "_")
            let fileName = "Scan_\(dateString)"
            
            let newModel = ScanModel(
                fileName: fileName,
                filePath: fileURL.path,
                meshCount: meshAnchors.count,
                vertextCount: vertextCount
            )
            
            Task { @MainActor in
                modelContext.insert(newModel)
                try? modelContext.save()
                print("SwiftData 저장 완료: \(newModel.fileName)")
            }
        }
    }
}
