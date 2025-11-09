//
//  RidingPausedView.swift
//  SnowMateWatch Watch App
//
//  Created by 이혜빈 on 11/9/25.
//

import SwiftUI

// MARK: - 라이딩 일시정지 화면
struct RidingPausedView: View {
    let session: RidingSession?
    let onResume: () -> Void
    let onStop: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange.gradient)
                .symbolRenderingMode(.hierarchical)
            
            Text("일시정지")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                if let session = session {
                    Text("최고 속도: \(Int(session.maxSpeed)) km/h")
                        .font(.caption)
                    Text("고도 상승: \(Int(session.elevationGain)) m")
                        .font(.caption)
                }
            }
            .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Button {
                    onResume()
                } label: {
                    Text("계속하기")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .padding(.vertical, 12)
            }
            .buttonBorderShape(.capsule)
            .tint(.blue)
            
            Button {
                onStop()
            } label: {
                Text("종료")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .tint(.red)
        }
    }
}
