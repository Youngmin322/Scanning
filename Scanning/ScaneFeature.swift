//
//  ScaneFeature.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/17/25.
//

import ComposableArchitecture

struct ScaneFeature: Reducer {
    struct State: Equatable {

    }
    
    enum Action: Equatable {
        case scanButtonTapped
    }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .scanButtonTapped:
            print("스캔 버튼 눌림!")
            return .none
        }
    }
}
