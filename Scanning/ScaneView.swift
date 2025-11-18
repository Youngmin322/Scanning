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
                ARViewContainer()
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
        
        arView.session.run(config)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func dismantleUIView(_ uiView: ARView, coordinator: ()) {
        uiView.session.pause()
    }
}

#Preview {
    ContentView()
}
