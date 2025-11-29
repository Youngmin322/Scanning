//
//  ScanningApp.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/15/25.
//

import SwiftUI
import ComposableArchitecture

@main
struct MyObjectCaptureApp: App {
    static let store = Store(initialState: CaptureFeature.State()) {
        CaptureFeature()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: MyObjectCaptureApp.store)
        }
    }
}
