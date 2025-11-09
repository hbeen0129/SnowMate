//
//  SnowMateApp.swift
//  SnowMate
//
//  Created by 이혜빈 on 11/8/25.
//

import SwiftUI
import SwiftData

@main
struct SnowMateApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(ModelContainer.shared)  // ✅ 공유 컨테이너 사용
    }
}
