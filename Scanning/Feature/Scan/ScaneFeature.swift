//
//  ScaneFeature.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/17/25.
//

import ComposableArchitecture
import RealityKit // RealityKit import 추가
import SwiftUI
import Combine

struct ScaneFeature: Reducer {
    
    // MARK: - State
    struct State: Equatable {
        var isScanning = false
        var session: ObjectCaptureSession? // RealityKit 세션
        var folderManager: CaptureFolderManager? // 파일 매니저
        var userCompletedScanPass = false // 한 바퀴 스캔 완료 여부
        var statusMessage: String = "세션 준비 중..."
        var numberOfShotsTaken: Int = 0 // 캡처된 이미지 수 (Object Capture용)
        
        // TCA Equatable 요구 사항 충족을 위해 ObjectCaptureSession 비교 무시
        static func == (lhs: ScaneFeature.State, rhs: ScaneFeature.State) -> Bool {
            return lhs.isScanning == rhs.isScanning &&
                   lhs.userCompletedScanPass == rhs.userCompletedScanPass &&
                   lhs.statusMessage == rhs.statusMessage &&
                   lhs.numberOfShotsTaken == rhs.numberOfShotsTaken
        }
    }
    
    // MARK: - Action
    enum Action: Equatable {
        case onAppear
        case startSession // 세션 초기화 및 시작 로직
        case startCapture // 감지 모드 시작 또는 캡처 시작
        case finishCapture // 캡처 종료 및 모델링 준비
        case sessionUpdated(ObjectCaptureSession.CaptureState) // 세션 상태 변화 감지
        case updateStatusMessage(String)
        case saveModelToSwiftData(URL) // 최종 저장
        case cleanup
        
        // TCA Equatable 요구 사항 충족을 위해 sessionUpdated의 연관 값 비교 무시
        static func == (lhs: ScaneFeature.Action, rhs: ScaneFeature.Action) -> Bool {
            switch (lhs, rhs) {
            case (.onAppear, .onAppear): return true
            case (.startSession, .startSession): return true
            case (.startCapture, .startCapture): return true
            case (.finishCapture, .finishCapture): return true
            // CaptureState는 enum이므로 Equatable 비교 가능
            case (.sessionUpdated(let lhsState), .sessionUpdated(let rhsState)):
                return lhsState == rhsState
            case (.updateStatusMessage(let lhsMsg), .updateStatusMessage(let rhsMsg)):
                return lhsMsg == rhsMsg
            case (.saveModelToSwiftData(let lhsURL), .saveModelToSwiftData(let rhsURL)):
                return lhsURL == rhsURL
            case (.cleanup, .cleanup): return true
            default: return false
            }
        }
    }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        return .none
    }
}
