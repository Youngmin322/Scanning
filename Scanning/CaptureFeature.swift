//
//  CaptureFeature.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/30/25.
//

import ComposableArchitecture

@Reducer
struct CaptureFeature {
    @ObservableState
    struct State: Equatable {
        var sessionState: SessionState = .ready
        var numberOfShots: Int = 0
        var maxShots: Int = 100
        var feedbackMessage: String = ""
        
        enum SessionState: Equatable {
            case ready // 준비
            case detecting // 물체 감지 중
            case capturing // 캡처 중
            case finishing // 완료 처리 중
        }
    }
    
    enum Action {
        case startDetecting         // 물체 감지 시작
          case startCapturing         // 캡처 시작
          case captureImage           // 이미지 캡처
          case updateShotCount(Int)   // 촬영 수 업데이트
          case finishCapture          // 캡처 완료
          case cancelCapture          // 캡처 취소
          case delegate(Delegate)
        
        enum Delegate {
            case captureCompleted // 부모에게 완료 알림
            case captureCancelled // 부모에게 취소 알림
        }
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .startDetecting:
                state.sessionState = .detecting
                state.feedbackMessage = "물체를 화면 중앙에 맞춰주세요"
                return .none
                
            case .startCapturing:
                state.sessionState = .capturing
                state.feedbackMessage = "천천히 물체 주위를 이동하세요"
                return .none
                
            case .captureImage:
                state.numberOfShots += 1
                return .none
                
            case .updateShotCount(let count):
                state.numberOfShots = count
                return .none
                
            case .finishCapture:
                state.sessionState = .finishing
                return .send(.delegate(.captureCompleted))
                
            case .cancelCapture:
                return .send(.delegate(.captureCancelled))
                
            case .delegate:
                return .none
            }
        }
    }
}
