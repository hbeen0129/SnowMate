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
    
    @State private var showHealthNotice = false
    @State private var showCountdown = false
    @State private var countdown = 3
    
    var body: some View {
        ZStack {
            // 메인 시작 화면
            VStack(spacing: 20) {
                Text("🏂")
                    .font(.system(size: 60))
                
                Text("SnowMate")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Button {
                    showHealthNotice = true
                } label: {
                    Text("라이딩 시작")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .tint(.blue)
            }
            .padding()
            .opacity(showHealthNotice ? 0 : 1)
            
            // HealthKit 안내 화면
            if showHealthNotice && !showCountdown {
                VStack(spacing: 16) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("심박수는\nApple Health에서\n측정됩니다")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
                .onAppear {
                    // 2초 후 카운트다운 시작
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showCountdown = true
                        }
                    }
                }
            }
            
            // 카운트다운 화면
            if showCountdown {
                VStack {
                    Text("\(countdown)")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.scale.combined(with: .opacity))
                .onAppear {
                    startCountdown()
                }
            }
        }
    }
    
    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 1 {
                withAnimation(.spring()) {
                    countdown -= 1
                }
            } else {
                timer.invalidate()
                // 카운트다운 완료 후 라이딩 시작
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onStartRiding()
                }
            }
        }
    }
}
