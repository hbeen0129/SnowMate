//
//  RidingTrackingView.swift
//  SnowMateWatch Watch App
//
//  Created by 이혜빈 on 11/9/25.
//

import SwiftUI

// MARK: - 라이딩 중 화면
struct RidingTrackingView: View {
    let currentSpeed: Double
    let currentAltitude: Double
    let currentHeartRate: Double
    let onPause: () -> Void
    let onStop: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // 속도 (가장 크게)
            VStack(spacing: 4) {
                Text("\(Int(currentSpeed))")
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
                Text("\(Int(currentAltitude))m")
                    .font(.headline)
                    .contentTransition(.numericText())
            }
            
            // 심박수
            if currentHeartRate > 0 {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red.gradient)
                        .symbolRenderingMode(.hierarchical)
                        .symbolEffect(.pulse)
                    Text("\(Int(currentHeartRate)) bpm")
                        .font(.headline)
                        .contentTransition(.numericText())
                }
            }
            
            Spacer()
            
            // 컨트롤 버튼
            HStack(spacing: 16) {
                Button {
                    onPause()
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .tint(.orange)
                
                Button {
                    onStop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .tint(.red)
            }
        }
        .padding()
    }
}
