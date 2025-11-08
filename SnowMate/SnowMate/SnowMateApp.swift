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
        .modelContainer(for: [
            RidingSession.self,
            SpeedPoint.self,
            AltitudePoint.self,
            HeartRatePoint.self,
            PauseEvent.self,
            RidingDiary.self
        ])
    }
}
