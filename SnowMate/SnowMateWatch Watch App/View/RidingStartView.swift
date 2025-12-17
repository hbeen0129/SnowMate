//
//  RidingStartView.swift
//  SnowMateWatch Watch App
//
//  Created by 이혜빈 on 11/9/25.
//

import SwiftUI

// MARK: - 라이딩 시작 화면
struct RidingStartView: View {
    let onStartRiding: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🏂")
                .font(.system(size: 60))
            
            Text("SnowMate")
                .font(.title3)
                .fontWeight(.bold)
            
            Button {
                onStartRiding()
            } label: {
                Text("라이딩 시작")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .tint(.blue)
            
            // HealthKit 사용 안내
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.caption2)
                Text("심박수는 Apple Health에서 측정")
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
            .padding(.top, 4)
        }
        .padding()
    }
}
