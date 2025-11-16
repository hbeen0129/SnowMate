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
    init() {
        // WatchConnectivity 초기화 및 ModelContext 설정
        WatchConnectivityManager.shared.configure(with: ModelContainer.shared.mainContext)
        print("✅ WatchConnectivity 초기화 완료 (iOS)")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(ModelContainer.shared)
    }
}
