//
//  ContentView.swift
//  SnowMate
//
//  Created by 이혜빈 on 11/8/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // 홈 화면
            HomeView()
                .tabItem {
                    Label("홈", systemImage: "house.fill")
                }
            
            // 캘린더 화면
            CalendarView()
                .tabItem {
                    Label("캘린더", systemImage: "calendar")
                }
            
            // 설정 화면
            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gearshape.fill")
                }
        }
    }
}
