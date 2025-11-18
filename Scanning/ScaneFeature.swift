//
//  ScaneFeature.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/17/25.
//

import ComposableArchitecture

struct ScaneFeature: Reducer {
    struct State: Equatable {
        var isScanning = false // 스캔 중인지 아닌지 확인하는 상태 변수
    }
    
    enum Action: Equatable {
        case scanButtonTapped
        case toggleScanning
    }
    
    // Action이 들어오면 State 변경을 담당하는 함수
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .scanButtonTapped:
            return .send(.toggleScanning)
            
        case .toggleScanning:
            state.isScanning.toggle()
            print("스캔 상태: \(state.isScanning)")
            return .none
        }
    }
}
