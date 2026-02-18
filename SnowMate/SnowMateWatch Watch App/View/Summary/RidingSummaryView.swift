//
//  RidingSummaryView.swift
//  SnowMateWatch Watch App
//
//  Created by 이혜빈 on 11/9/25.
//

import SwiftUI

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
                slopeLevelSection
                
                // 주요 통계
                statisticsSection
                
                Button {
                    dismiss()
                } label: {
                    Text("확인")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .tint(.blue)
            }
            .padding()
        }
    }
    
    // MARK: - 슬로프 레벨 섹션
    private var slopeLevelSection: some View {
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
    }
    
    // MARK: - 통계 섹션
    private var statisticsSection: some View {
        VStack(spacing: 12) {
            StatRow(
                icon: "speedometer",
                title: "최고 속도",
                value: "\(Int(session.maxSpeed)) km/h"
            )
            
            StatRow(
                icon: "speedometer",
                title: "평균 속도",
                value: "\(Int(session.avgSpeed)) km/h"
            )
            
            StatRow(
                icon: "arrow.up.circle.fill",
                title: "고도 상승",
                value: "\(Int(session.elevationGain)) m"
            )
            
            StatRow(
                icon: "clock.fill",
                title: "라이딩 시간",
                value: TimeFormatter.formatDuration(session.activeRidingTime)
            )
            
            if let avgHR = session.avgHeartRate {
                StatRow(
                    icon: "heart.fill",
                    title: "평균 심박수",
                    value: "\(Int(avgHR)) bpm",
                    color: .red
                )
            }
        }
    }
}
