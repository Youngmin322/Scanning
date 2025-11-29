//
//  ContentView.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/15/25.
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    
    let store: StoreOf<CaptureFeature>
    
    var body: some View {
        TabView {
            Tab("스캔", systemImage: "camera.viewfinder") {
                NavigationStack {
                    EmptyView()
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
