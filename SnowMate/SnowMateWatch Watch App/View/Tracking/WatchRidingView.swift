//
//  WatchRidingView.swift
//  SnowMateWatch Watch App
//
//  Created by 이혜빈 on 11/8/25.
//

import SwiftUI

// MARK: - Apple Watch 메인 화면
struct WatchRidingView: View {
    @StateObject private var tracker = RidingTracker()
    @State private var showSummary = false
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ZStack {
            currentView
        }
        .onAppear {
            tracker.modelContext = modelContext
        }
        .alert("속도가 느려졌어요 🐢", isPresented: $tracker.showSlowSpeedAlert) {
            Button("일시정지") {
                tracker.pauseRiding()
            }
            Button("계속하기", role: .cancel) {
                tracker.showSlowSpeedAlert = false
            }
        } message: {
            Text("30초 동안 속도가 10km/h 미만이에요.\n넘어지셨나요?")
        }
        .sheet(isPresented: $showSummary) {
            if let session = tracker.currentSession {
                RidingSummaryView(session: session)
            }
        }
    }
    
    // MARK: - 현재 화면 결정
    @ViewBuilder
    private var currentView: some View {
        if !tracker.isTracking {
            RidingStartView(onStartRiding: {
                tracker.startRiding()
            })
        } else if tracker.isPaused {
            RidingPausedView(
                session: tracker.currentSession,
                onResume: {
                    tracker.resumeRiding()
                },
                onStop: {
                    tracker.stopRiding()
                    showSummary = true
                }
            )
        } else {
            RidingTrackingView(
                currentSpeed: tracker.currentSpeed,
                currentAltitude: tracker.currentAltitude,
                currentHeartRate: tracker.currentHeartRate,
                onPause: {
                    tracker.pauseRiding()
                },
                onStop: {
                    tracker.stopRiding()
                    showSummary = true
                }
            )
        }
    }
}
