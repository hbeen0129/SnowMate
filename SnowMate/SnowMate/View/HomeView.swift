//
//  HomeView.swift
//  SnowMate
//
//  Created by 이혜빈 on 11/8/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RidingSession.startTime, order: .reverse) private var sessions: [RidingSession]
    
    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyStateView
                } else {
                    sessionListView
                }
            }
            .navigationTitle("홈")
        }
    }
    
    // MARK: - 빈 화면
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Text("🏂")
                .font(.system(size: 80))
            
            Text("SnowMate")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Apple Watch에서 라이딩을 시작하세요!")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    // MARK: - 세션 리스트
    private var sessionListView: some View {
        List {
            Section {
                ForEach(sessions) { session in
                    NavigationLink {
                        SessionDetailView(session: session)
                    } label: {
                        SessionRowView(session: session)
                    }
                }
                .onDelete(perform: deleteSessions)
            } header: {
                Text("최근 라이딩 기록 (\(sessions.count))")
            }
        }
    }
    
    // MARK: - 세션 삭제
    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
    }
}

// MARK: - 세션 행 뷰
struct SessionRowView: View {
    let session: RidingSession
    
    var body: some View {
        HStack(spacing: 12) {
            // 슬로프 레벨 아이콘
            Text(session.slopeLevel.emoji)
                .font(.system(size: 40))
            
            VStack(alignment: .leading, spacing: 4) {
                // 날짜
                Text(session.startTime, style: .date)
                    .font(.headline)
                
                // 통계 요약
                HStack(spacing: 12) {
                    Label("\(Int(session.maxSpeed)) km/h", systemImage: "speedometer")
                    Label("\(Int(session.elevationGain)) m", systemImage: "arrow.up.circle.fill")
                    Label(TimeFormatter.formatDuration(session.activeRidingTime), systemImage: "clock.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 세션 상세 뷰
struct SessionDetailView: View {
    let session: RidingSession
    
    var body: some View {
        List {
            // 슬로프 레벨
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Text(session.slopeLevel.emoji)
                            .font(.system(size: 60))
                        Text(session.slopeLevel.description)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical)
            }
            
            // 기본 정보
            Section("기본 정보") {
                LabeledContent("날짜", value: session.startTime, format: .dateTime)
                LabeledContent("시작 시간", value: session.startTime, format: .dateTime.hour().minute())
                if let endTime = session.endTime {
                    LabeledContent("종료 시간", value: endTime, format: .dateTime.hour().minute())
                }
            }
            
            // 속도 통계
            Section("속도") {
                LabeledContent("최고 속도", value: "\(Int(session.maxSpeed)) km/h")
                LabeledContent("평균 속도", value: "\(Int(session.avgSpeed)) km/h")
            }
            
            // 고도 통계
            Section("고도") {
                LabeledContent("최대 고도", value: "\(Int(session.maxAltitude)) m")
                LabeledContent("최소 고도", value: "\(Int(session.minAltitude)) m")
                LabeledContent("총 상승", value: "\(Int(session.elevationGain)) m")
                LabeledContent("총 하강", value: "\(Int(session.elevationLoss)) m")
            }
            
            // 시간 & 거리
            Section("시간 & 거리") {
                LabeledContent("라이딩 시간", value: TimeFormatter.formatDuration(session.activeRidingTime))
                LabeledContent("전체 시간", value: TimeFormatter.formatDuration(session.totalTime))
                LabeledContent("총 거리", value: String(format: "%.2f km", session.totalDistance / 1000))
            }
            
            // 심박수 (있을 경우)
            if let avgHR = session.avgHeartRate, let maxHR = session.maxHeartRate {
                Section("심박수") {
                    LabeledContent("평균 심박수", value: "\(Int(avgHR)) bpm")
                    LabeledContent("최대 심박수", value: "\(Int(maxHR)) bpm")
                }
            }
            
            // 일시정지 이벤트
            if !session.pauseEvents.isEmpty {
                Section("일시정지 기록") {
                    ForEach(session.pauseEvents.indices, id: \.self) { index in
                        let pause = session.pauseEvents[index]
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pause.reason.displayName)
                                .font(.subheadline)
                            Text("\(pause.startTime, style: .time) - \(TimeFormatter.formatDuration(pause.duration))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("라이딩 상세")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 시간 포맷터
struct TimeFormatter {
    static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(ModelContainer.shared)
}
