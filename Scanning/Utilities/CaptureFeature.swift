//
//  CaptureFeature.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/29/25.
//

import ComposableArchitecture
import RealityKit
import SwiftUI

enum AppPhase {
    case ready // 준비
    case capturing // 촬영
    case prepareToReconstruct // 촬영 완료 및 복원 대기
    case reconstructing // 복원 중
    case viewing // 결과 보기
}

@Reducer
struct CaptureFeature {
    @ObservableState
    struct State: Equatable {
        var phase: AppPhase = .ready
        var objectCaptureSession: ObjectCaptureSession?
        var folderManager: CaptureFolderManager?
        
        static func == (lhs: State, rhs: State) -> Bool {
            return lhs.phase == rhs.phase && (lhs.objectCaptureSession === rhs.objectCaptureSession)
        }
    }
    
    enum Action {
        case startCaptureButtonTapped
        case finishCaptureButtonTapped
    }
    
    var body: some Reducer<State, Action> {
            Reduce { state, action in
                switch action {
                case .startCaptureButtonTapped:
                    // 폴더 매니저 생성
                    let folderManager = CaptureFolderManager()
                    state.folderManager = folderManager
                    
                    // 세션 설정 및 생성
                    var configuration = ObjectCaptureSession.Configuration()
                    configuration.checkpointDirectory = folderManager.captureFolder.appendingPathComponent("Snapshots")
                    configuration.isOverCaptureEnabled = true
                    
                    let session = ObjectCaptureSession()
                    
                    // 세션 시작
                    session.start(imagesDirectory: folderManager.imagesFolder,
                                  configuration: configuration)
                    
                    // State 업데이트
                    state.objectCaptureSession = session
                    state.phase = .capturing
                    return .none
                    
                case .finishCaptureButtonTapped:
                    // 세션 종료 요청
                    state.objectCaptureSession?.finish()
                    state.phase = .prepareToReconstruct
                    return .none
                }
            }
    }
}
