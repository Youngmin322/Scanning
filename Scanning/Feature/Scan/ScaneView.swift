//
//  ScaneView.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/15/25.
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
                        VStack(spacing: 8) {
                            Text("물체를 중심으로 천천히 움직이며 스캔하세요.")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(.black.opacity(0.6))
                                .cornerRadius(8)
                            
                            HStack {
                                Text("스캔된 앵커: \(viewStore.meshCount)")
                                    .font(.headline)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(10)
                            }
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
        
        // 🛠️ 수정 1: ARObjectScanningConfiguration으로 오타 수정
        let config = ARObjectScanningConfiguration()
        
        arView.debugOptions = []
        
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
            print("스캔 중. ARObjectAnchor 수집 활성화.")
        } else {
            print("스캔 정지. ARObjectAnchor 수집 비활성화.")
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
        var currentObjectAnchor: ARObjectAnchor? // 수집된 물체 앵커
        var store: StoreOf<ScaneFeature>?
        var hasSaved = false
        var modelContext: ModelContext?
        var arSession: ARSession?
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard isScanning else { return }
            
            let newObjectAnchors = anchors.compactMap { $0 as? ARObjectAnchor }
            
            if let firstAnchor = newObjectAnchors.first {
                currentObjectAnchor = firstAnchor
                print("물체 앵커 감지 및 추가됨: \(firstAnchor.identifier)")
                store?.send(.updateMeshCount(1))
            }
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            guard isScanning else { return }
            
            let updatedObjectAnchors = anchors.compactMap { $0 as? ARObjectAnchor }
            
            if let updatedAnchor = updatedObjectAnchors.first, updatedAnchor.identifier == currentObjectAnchor?.identifier {
                currentObjectAnchor = updatedAnchor
            }
            
            if currentObjectAnchor != nil {
                store?.send(.updateMeshCount(1))
            } else {
                store?.send(.updateMeshCount(0))
            }
        }
        
        func saveMeshToOBJ() {
            guard let arSession = arSession, let currentAnchor = currentObjectAnchor else {
                print("저장할 ARObjectAnchor가 없거나 ARSession에 접근 불가")
                
                Task { @MainActor in
                    self.store?.send(.updateMeshCount(0))
                }
                return
            }
            
            let centerSimd4 = currentAnchor.transform.columns.3
            let centerSimd3 = SIMD3<Float>(centerSimd4.x, centerSimd4.y, centerSimd4.z)
            
            let transform = currentAnchor.transform
            
            let defaultExtent: SIMD3<Float> = SIMD3<Float>(0.4, 0.4, 0.4)
            
            arSession.createReferenceObject(
                transform: transform,
                center: centerSimd3,
                extent: defaultExtent,
                completionHandler: { [weak self] (refObject, error) in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("ARReferenceObject 생성 실패: \(error.localizedDescription)")
                        
                        Task { @MainActor in
                            self.store?.send(.updateMeshCount(0))
                        }
                        return
                    }
                    
                    guard let refObject = refObject else {
                        print("ARReferenceObject 생성 실패: 결과 없음")
                        
                        Task { @MainActor in
                            self.store?.send(.updateMeshCount(0))
                        }
                        return
                    }
                    
                    let fileName = "scan_\(Date().timeIntervalSince1970).arobject"
                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fileURL = documentsPath.appendingPathComponent(fileName)
                    
                    do {
                        try refObject.export(to: fileURL, previewImage: nil)
                        print(".arobject 파일 저장 완료: \(fileURL.path)")
                        
                        Task { @MainActor in
                            self.saveToSwiftData(
                                fileURL: fileURL,
                                vertextCount: 0
                            )
                            self.currentObjectAnchor = nil
                            self.store?.send(.updateMeshCount(0))
                        }
                        
                    } catch {
                        print("ARObject 저장 실패: \(error)")
                        
                        Task { @MainActor in
                            self.store?.send(.updateMeshCount(0))
                        }
                    }
                }
            )
        }
        
        
        private func saveToSwiftData(fileURL: URL, vertextCount: Int) {
            guard let modelContext = modelContext else { return }
            
            let dateString = Date().formatted(date: .numeric, time: .shortened)
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "")
                .replacingOccurrences(of: " ", with: "_")
            
            let fileName = "Scan_\(dateString).arobject"
            
            let newModel = ScanModel(
                fileName: fileName,
                filePath: fileURL.path,
                meshCount: 1, // ARObject 앵커가 존재함을 나타내는 1로 설정
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

