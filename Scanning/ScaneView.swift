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
                        print("Press")
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
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

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

#Preview {
    ContentView()
}
