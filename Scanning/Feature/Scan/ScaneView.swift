//
//  ScaneView.swift
//  Scanning
//
//  Created by Youngmin Cho on 11/29/25.
//

import SwiftUI
import ComposableArchitecture
import RealityKit

struct ScaneView: View {
    // TCA Store: 상태와 액션을 관리
    let store: StoreOf<CaptureFeature>
    
    var body: some View {
        ZStack {
            // 카메라 뷰
            if let session = store.objectCaptureSession {
                ObjectCaptureView(session: session)
                    .edgesIgnoringSafeArea(.all)
            } else {
                // 세션 준비 전 검은 화면
                Color.black.edgesIgnoringSafeArea(.all)
            }
            
            // UI 오버레이
            VStack {
                // 상태 메시지 (촬영 중이거나 완료 시에만 표시)
                if store.phase == .capturing {
                    HStack {
                        Text("사물 스캔 중...")
                            .font(.headline)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                    }
                    .padding(.top, 50)
                } else if store.phase == .prepareToReconstruct {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("스캔 완료! 저장되었습니다.")
                    }
                    .font(.headline)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                    .padding(.top, 50)
                }
                
                Spacer()
                
                // 컨트롤 버튼 영역
                HStack(spacing: 40) {
                    
                    // 촬영 시작/중지(상태 표시) 버튼
                    if store.phase == .ready {
                        // 시작 버튼
                        Button(action: {
                            store.send(.startCaptureButtonTapped)
                        }) {
                            Image(systemName: "viewfinder")
                                .font(.system(size: 35))
                                .foregroundColor(.gray)
                                .frame(width: 70, height: 70)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    } else if store.phase == .capturing {
                        // 녹화 중임을 알리는 아이콘
                        Image(systemName: "record.circle")
                            .font(.system(size: 35))
                            .foregroundColor(.red)
                            .frame(width: 70, height: 70)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(.red, lineWidth: 2)
                            )
                    }
                    
                    // 완료(저장) 버튼
                    if store.phase == .capturing {
                        Button(action: {
                            store.send(.finishCaptureButtonTapped)
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.green)
                                .frame(width: 70, height: 70)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }
}
