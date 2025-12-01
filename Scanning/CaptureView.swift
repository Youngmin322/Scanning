//
//  CaptureView.swift
//  Scanning
//
//  Created by Youngmin Cho on 12/1/25.
//

import SwiftUI
import ComposableArchitecture

struct CaptureView: View {
    let store: StoreOf<CaptureFeature>
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                TopButton(store: store)
                
                Spacer()
            }
        }
    }
}

struct TopButton: View {
    let store: StoreOf<CaptureFeature>
    
    var body: some View {
        HStack {
            Button("취소") {
                store.send(.cancelCapture)
            }
            .foregroundColor(.white)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            
            Spacer()
            
            if store.sessionState == .capturing {
                Button("완료") {
                    store.send(.finishCapture)
                }
                .foregroundColor(.white)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(10)
            }
        }
    }
}
