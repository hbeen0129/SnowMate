//
//  HomeView.swift
//  SnowMate
//
//  Created by 이혜빈 on 11/8/25.
//

import SwiftUI

// 임시 홈 뷰
struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("🏂 SnowMate")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Apple Watch에서 라이딩을 시작하세요!")
                    .foregroundColor(.secondary)
                    .padding()
            }
            .navigationTitle("홈")
        }
    }
}
