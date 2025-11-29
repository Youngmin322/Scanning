//
//  ContentView.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/15/25.
//

import SwiftUI
import ComposableArchitecture
import RealityKit

struct ContentView: View {
    
    let store: StoreOf<CaptureFeature>
    
    var body: some View {
        TabView {
            Tab("스캔", systemImage: "camera.viewfinder") {
                NavigationStack {
                    ScaneView(store: store)
                }
            }
            
            Tab("모델", systemImage: "cube.fill") {
                NavigationStack {
                ModelListView()
                }
            }
        }
    }
}
