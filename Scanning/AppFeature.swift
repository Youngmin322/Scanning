//
//  AppFeature.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/30/25.
//

import ComposableArchitecture

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var currentScreen: Screen = .ready
        
        enum Screen: Equatable {
            case ready // 시작 화면
            case capturing // 캡처 중
            case processing // 처리 중
        }
    }
    
    enum Action {
        case startCaptureButtonTapped // 시작 버튼 터치
        case captureCompleted // 챕처 완료
        case processingCompleted // 처리 완료
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .startCaptureButtonTapped:
                state.currentScreen = .capturing
                return .none
                
            case .captureCompleted:
                state.currentScreen = .processing
                return .none
                
            case .processingCompleted:
                state.currentScreen = .ready
                return .none
            }
        }
    }
}
