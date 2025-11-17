//
//  ContentView.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/15/25.
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("스캔", systemImage: "camera.viewfinder") {
                NavigationStack {
                    ScaneView(store: Store(initialState: ScaneFeature.State()) {
                        ScaneFeature()
                    })
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
