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
    // ⭐️ RidingTracker를 StateObject로 생성
    @StateObject private var tracker = RidingTracker()
    
    var body: some Scene {
        WindowGroup {
            WatchRidingView()
                .environmentObject(tracker)  // environmentObject로 전달
        }
        .modelContainer(ModelContainer.shared)
    }
    
    // init에서 ModelContext 주입 (중요!)
    init() {
        let tracker = RidingTracker()
        _tracker = StateObject(wrappedValue: tracker)
        
        // ModelContext 설정
        tracker.modelContext = ModelContainer.shared.mainContext
        
        print("✅ RidingTracker 초기화 완료")
        print("✅ ModelContext 주입 완료")
    }
}
