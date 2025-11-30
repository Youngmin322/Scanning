//
//  ContentView.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/15/25.
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }
    
    var body: some View {
        
        TabView {
            Tab("스캔", systemImage: "camera.viewfinder") {
                NavigationStack {
                    AppView(store: store)
                }
            }
            
            Tab("모델", systemImage: "cube.fill") {
                NavigationStack {
                    EmptyView()
                }
            }
        }
    }
}
