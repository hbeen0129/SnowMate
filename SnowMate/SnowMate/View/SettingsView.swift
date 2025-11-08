//
//  SettingsView.swift
//  SnowMate
//
//  Created by 이혜빈 on 11/8/25.
//

import SwiftUI

// 임시 설정 뷰
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("앱 정보") {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("설정")
        }
    }
}
