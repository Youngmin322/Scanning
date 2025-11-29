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
                            Text(viewStore.statusMessage)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(.black.opacity(0.6))
                                .cornerRadius(8)
                            
                            HStack {
                                Text("메쉬 카운트 \(viewStore.meshCount)")
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
        let coordinator = Coordinator()
        coordinator.pointCloudCoordinator = PointCloudCoordinator()
        return coordinator
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARObjectScanningConfiguration()
        config.planeDetection = .horizontal
        
        arView.debugOptions = [
            .showFeaturePoints,
            .showWorldOrigin,
            .showSceneUnderstanding
        ]
        
        arView.session.delegate = context.coordinator
        
        context.coordinator.modelContext = modelContext
        context.coordinator.arSession = arView.session
        context.coordinator.arView = arView
        
        arView.session.run(config)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        print("ARview 업데이트: isScanning = \(isScanning)")
        
        let wasScanning = context.coordinator.isScanning
        context.coordinator.isScanning = isScanning
        context.coordinator.store = store
        
        // 스캔 시작/정지 시 초기화
        if isScanning && !wasScanning {
            context.coordinator.hasSaved = false
            print("스캔 시작")
        }
        
        if !isScanning && wasScanning {
            print("스캔 정지")
        }
        
        // 저장 트리거
        if shouldSave && !context.coordinator.hasSaved {
            context.coordinator.saveMeshToOBJ()
            context.coordinator.hasSaved = true
        }
    }
    
    func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var isScanning = false
        var currentFrame: ARFrame?
        var store: StoreOf<ScaneFeature>?
        var hasSaved = false
        var modelContext: ModelContext?
        var arSession: ARSession?
        var arView: ARView?
        var pointCloudCoordinator: PointCloudCoordinator?
        
        // ARFrame 업데이트를 통해 스캔 진행 상황 추적
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard isScanning, let store = self.store else { return }
            
            currentFrame = frame
            
            pointCloudCoordinator?.updatePointCloud(newFrame: frame)
            
            // 스캔 품질 피드백: ARKit이 제공하는 trackingState와 특징점 개수를 활용
            let trackingState = frame.camera.trackingState
            let featurePointsCount = frame.rawFeaturePoints?.points.count ?? 0
            let qualityMessage: String

            switch trackingState {
            case .notAvailable:
                qualityMessage = "트래킹 불가: 밝은 환경에서 다시 시도하세요."
            case .limited(let reason):
                switch reason {
                case .initializing:
                    qualityMessage = "초기화 중: 기기를 천천히 움직여주세요."
                case .relocalizing:
                    qualityMessage = "위치 재탐색 중: 이전 위치로 돌아가거나 주변을 더 스캔하세요."
                case .excessiveMotion:
                    qualityMessage = "과도한 움직임: 기기를 천천히 움직이세요."
                case .insufficientFeatures:
                    qualityMessage = "특징점 부족: 텍스처가 있는 물체와 밝은 환경에서 스캔하세요."
                @unknown default:
                    qualityMessage = "트래킹 제한: 주변을 더 스캔하세요."
                }
            case .normal:
                if featurePointsCount < 200 {
                    qualityMessage = "특징점 적음: 물체에 가까이 다가가고 다양한 각도에서 스캔하세요."
                } else if featurePointsCount < 800 {
                    qualityMessage = "중간 품질: 더 다양한 각도에서 스캔하여 메쉬를 채우세요."
                } else {
                    qualityMessage = "고품질: 스캔 완료 가능. 정지하고 '완료' 버튼을 누르세요."
                }
            }

            Task { @MainActor in
                store.send(.updateStatusMessage(qualityMessage))
                store.send(.updateMeshCount(featurePointsCount))
            }
        }
        
        // 실제 ARObjectAnchor가 추가될 때 (스캔 완료 후 감지 시)
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            let objectAnchors = anchors.compactMap { $0 as? ARObjectAnchor }
            if !objectAnchors.isEmpty {
                print("ARObjectAnchor 감지됨: \(objectAnchors.count)개")
            }
        }
        
        func saveMeshToOBJ() {
            guard let arSession = arSession, let currentFrame = currentFrame else {
                print("저장할 ARFrame이 없습니다")
                Task { @MainActor in
                    store?.send(.updateStatusMessage("저장할 데이터 없음"))
                }
                return
            }
            
            print("스캔 데이터 저장 시작")
            
            //  카메라 위치를 중심으로 일정 영역의 reference object 생성
            let cameraTransform = currentFrame.camera.transform
            let centerSimd4 = cameraTransform.columns.3
            let centerSimd3 = SIMD3<Float>(centerSimd4.x, centerSimd4.y, centerSimd4.z)
            
            // 스캔할 물체의 크기 설정 (필요에 따라 조정)
            let extent: SIMD3<Float> = SIMD3<Float>(0.3, 0.3, 0.3) // 30cm x 30cm x 30cm
            
            // CreateReferenceObject 호출
            arSession.createReferenceObject(
                transform: cameraTransform,
                center: centerSimd3,
                extent: extent,
                completionHandler: { [weak self] (refObject, error) in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("ARReferenceObject 생성 실패: \(error.localizedDescription)")
                        Task { @MainActor in
                            self.store?.send(.updateStatusMessage("ARReferenceObject 생성 실패: \(error.localizedDescription)"))
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
                    
                    // .arobject 파일로 저장
                    let fileName = "scan_\(Date().timeIntervalSince1970).arobject"
                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fileURL = documentsPath.appendingPathComponent(fileName)
                    
                    do {
                        try refObject.export(to: fileURL, previewImage: nil)
                        print(".arobject 파일 저장 완료: \(fileURL.path)")
                        
                        Task { @MainActor in
                            self.saveToSwiftData(
                                fileURL: fileURL,
                                featurePointsCount: currentFrame.rawFeaturePoints?.points.count ?? 0
                            )
                            self.currentFrame = nil
                            self.store?.send(.updateStatusMessage("저장 완료."))
                        }
                        
                    } catch {
                        print("ARObject 저장 실패: \(error)")
                        Task { @MainActor in
                            self.store?.send(.updateStatusMessage("ARObject 저장 실패: \(error.localizedDescription)"))
                        }
                    }
                }
            )
        }
        
        private func saveToSwiftData(fileURL: URL, featurePointsCount: Int) {
            guard let modelContext = modelContext else { return }
            
            let dateString = Date().formatted(date: .numeric, time: .shortened)
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "")
                .replacingOccurrences(of: " ", with: "_")
            
            let fileName = "Scan_\(dateString).arobject"
            
            let newModel = ScanModel(
                fileName: fileName,
                filePath: fileURL.path,
                meshCount: 1,
                vertextCount: featurePointsCount
            )
            
            Task { @MainActor in
                modelContext.insert(newModel)
                try? modelContext.save()
                print("SwiftData 저장 완료: \(newModel.fileName)")
            }
        }
    }
}
