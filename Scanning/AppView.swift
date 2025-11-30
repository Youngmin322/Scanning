//
//  AppView.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/30/25.
//

import SwiftUI
import ComposableArchitecture

struct AppView: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        switch store.currentScreen {
        case .ready:
            ReadyScreen(store: store)
            
        case .capturing:
            Text("캡처 화면")
            
        case .processing:
            Text("처리 중 화면")
        }
    }
}

struct ReadyScreen: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        
    }
}
