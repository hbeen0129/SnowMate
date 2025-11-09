//
//  SnowMateWatchApp.swift
//  SnowMateWatch Watch App
//
//  Created by 이혜빈 on 11/8/25.
//

import SwiftUI
import SwiftData

@main
struct SnowMate_Watch_App: App {
    var body: some Scene {
        WindowGroup {
            WatchRidingView()
        }
        .modelContainer(ModelContainer.shared)  // ✅ 공유 컨테이너 사용
    }
}
