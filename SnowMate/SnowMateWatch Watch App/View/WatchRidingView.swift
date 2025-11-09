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
            if !tracker.isTracking {
                // 시작 화면
                startView
            } else if tracker.isPaused {
                // 일시정지 화면
                pausedView
            } else {
                // 라이딩 중 화면
                trackingView
            }
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
    
    // MARK: - 시작 화면
    private var startView: some View {
        VStack(spacing: 20) {
            Text("🏂")
                .font(.system(size: 60))
            
            Text("SnowMate")
                .font(.title3)
                .fontWeight(.bold)
            
            Button {
                tracker.startRiding()
            } label: {
                Text("라이딩 시작")
                    .font(.headline)
<<<<<<< HEAD
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
=======
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
>>>>>>> dev
            .tint(.blue)
        }
        .padding()
    }
    
    // MARK: - 라이딩 중 화면
    private var trackingView: some View {
        VStack(spacing: 8) {
            // 속도 (가장 크게)
            VStack(spacing: 4) {
                Text("\(Int(tracker.currentSpeed))")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue.gradient)
                    .contentTransition(.numericText())
                Text("km/h")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // 고도
            HStack {
                Image(systemName: "mountain.2.fill")
                    .foregroundStyle(.green.gradient)
                    .symbolRenderingMode(.hierarchical)
                Text("\(Int(tracker.currentAltitude))m")
                    .font(.headline)
                    .contentTransition(.numericText())
            }
            
            // 심박수
            if tracker.currentHeartRate > 0 {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red.gradient)
                        .symbolRenderingMode(.hierarchical)
                        .symbolEffect(.pulse)
                    Text("\(Int(tracker.currentHeartRate)) bpm")
                        .font(.headline)
                        .contentTransition(.numericText())
                }
            }
            
            Spacer()
            
            // 컨트롤 버튼
            HStack(spacing: 16) {
                Button {
                    tracker.pauseRiding()
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                }
<<<<<<< HEAD
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .tint(.orange)
=======
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .buttonBorderShape(.circle)
>>>>>>> dev
                
                Button {
                    tracker.stopRiding()
                    showSummary = true
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                }
<<<<<<< HEAD
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .tint(.red)
=======
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .buttonBorderShape(.circle)
>>>>>>> dev
            }
        }
        .padding()
    }
    
    // MARK: - 일시정지 화면
    private var pausedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange.gradient)
                .symbolRenderingMode(.hierarchical)
            
            Text("일시정지")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                if let session = tracker.currentSession {
                    Text("최고 속도: \(Int(session.maxSpeed)) km/h")
                        .font(.caption)
                    Text("고도 상승: \(Int(session.elevationGain)) m")
                        .font(.caption)
                }
            }
            .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Button {
                    tracker.resumeRiding()
                } label: {
                    Text("계속하기")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
<<<<<<< HEAD
                }
                .buttonStyle(.glass)
=======
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
>>>>>>> dev
                .tint(.blue)
                
                Button {
                    tracker.stopRiding()
                    showSummary = true
                } label: {
                    Text("종료")
                        .font(.subheadline)
<<<<<<< HEAD
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
=======
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
>>>>>>> dev
                .tint(.red)
            }
        }
        .padding()
    }
}

// MARK: - 라이딩 결과 요약 화면
struct RidingSummaryView: View {
    let session: RidingSession
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("🏁 라이딩 완료!")
                    .font(.title3)
                    .fontWeight(.bold)
                
                // 슬로프 레벨
                VStack(spacing: 4) {
                    Text(session.slopeLevel.emoji)
                        .font(.system(size: 40))
                    Text(session.slopeLevel.description)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // 주요 통계
                VStack(spacing: 12) {
                    StatRow(icon: "speedometer", title: "최고 속도", value: "\(Int(session.maxSpeed)) km/h")
                    StatRow(icon: "speedometer", title: "평균 속도", value: "\(Int(session.avgSpeed)) km/h")
                    StatRow(icon: "arrow.up.circle.fill", title: "고도 상승", value: "\(Int(session.elevationGain)) m")
                    StatRow(icon: "clock.fill", title: "라이딩 시간", value: formatDuration(session.activeRidingTime))
                    
                    if let avgHR = session.avgHeartRate {
                        StatRow(icon: "heart.fill", title: "평균 심박수", value: "\(Int(avgHR)) bpm", color: .red)
                    }
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("확인")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
<<<<<<< HEAD
                }
                .buttonStyle(.glass)
=======
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
>>>>>>> dev
                .tint(.blue)
            }
            .padding()
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else {
            return "\(minutes)분"
        }
    }
}

// MARK: - Helper Views
struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    var color: Color = .blue
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color.gradient)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 24)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}
