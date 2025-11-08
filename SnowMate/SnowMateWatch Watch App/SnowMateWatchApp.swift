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
        .modelContainer(for: [
            RidingSession.self,
            SpeedPoint.self,
            AltitudePoint.self,
            HeartRatePoint.self,
            PauseEvent.self
        ])
    }
}
