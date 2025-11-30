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
        var captureState: CaptureFeature.State?
        
        enum Screen: Equatable {
            case ready // 시작 화면
            case capturing // 캡처 중
            case processing // 처리 중
        }
    }
    
    enum Action {
        case startCaptureButtonTapped // 시작 버튼 터치
        case processingCompleted // 처리 완료
        case captureAction(CaptureFeature.Action)
    }
    
    var body: some Reducer<State, Action> {
          Reduce { state, action in
              switch action {
              case .startCaptureButtonTapped:
                  state.currentScreen = .capturing
                  state.captureState = CaptureFeature.State()  // State 생성
                  return .none
                  
              case .captureAction(.delegate(.captureCompleted)):  // 자식이 완료 알림
                  state.currentScreen = .processing
                  state.captureState = nil
                  return .none
                  
              case .captureAction(.delegate(.captureCancelled)):  // 자식이 취소 알림
                  state.currentScreen = .ready
                  state.captureState = nil
                  return .none
                  
              case .captureAction:  // 나머지는 자식이 처리
                  return .none
                  
              case .processingCompleted:
                  state.currentScreen = .ready
                  return .none
              }
          }
          .ifLet(\.captureState, action: \.captureAction) {  // 자식 Reducer 연결
              CaptureFeature()
          }
      }
  }
