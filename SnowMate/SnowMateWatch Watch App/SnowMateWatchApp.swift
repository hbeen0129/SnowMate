//
//  SnowMateWatchApp.swift
//  SnowMateWatch Watch App
//
//  Created by 이혜빈 on 11/8/25.
//

import SwiftUI
import SwiftData

@main
struct SnowMateWatch_Watch_AppApp: App {
    @StateObject private var tracker = RidingTracker()
    
    init() {
        // WatchConnectivity 초기화 및 ModelContext 설정
        WatchConnectivityManager.shared.configure(with: ModelContainer.shared.mainContext)
        print("✅ WatchConnectivity 초기화 완료 (Watch)")
    }
    
    var body: some Scene {
        WindowGroup {
            WatchRidingView()
                .environmentObject(tracker)
        }
        .modelContainer(ModelContainer.shared)
    }
}
