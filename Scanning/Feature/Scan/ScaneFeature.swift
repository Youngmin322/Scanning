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
        var meshCount = 0 // 스캔된 메쉬 개수
        var shouldSave = false
        var statusMessage: String = "AR 세션 준비 중"
    }
    
    enum Action: Equatable {
        case scanButtonTapped
        case toggleScanning
        case completeScan
        case updateMeshCount(Int)
        case updateStatusMessage(String)
    }
    
    // Action이 들어오면 State 변경을 담당하는 함수
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
           switch action {
           case .scanButtonTapped:
               return .send(.toggleScanning)
               
           case .toggleScanning:
               state.isScanning.toggle()
               
               // 스캔 시작하면 shouldSave 초기화
               if state.isScanning {
                   state.shouldSave = false
                   state.statusMessage = "물체를 중심으로 움직이며 천천히 스캔하세요."
               } else {
                   state.statusMessage = "스캔 일시정지"
               }
               
               print("스캔 상태: \(state.isScanning)")
               return .none
               
           case .completeScan:
               state.isScanning = false
               state.shouldSave = true
               print("스캔 완료")
               return .none
               
           case .updateMeshCount(let count):
               state.meshCount = count
               return .none
               
           case .updateStatusMessage(let message):
               state.statusMessage = message
               return .none
           }
       }
   }
