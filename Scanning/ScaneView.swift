//
//  ContentView.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/15/25.
//

import SwiftUI
import RealityKit
import ARKit

struct ScaneView: View {
    var body: some View {
        ZStack {
            ARViewContainer()
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                HStack(spacing: 40) {
                    Button(action: {
                        
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

#Preview {
    ScaneView()
}
