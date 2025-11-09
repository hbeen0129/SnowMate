//
//  ModelContainer.swift
//  SnowMateWatch Watch App
//
//  Created by 이혜빈 on 11/9/25.
//

import SwiftData
import Foundation

extension ModelContainer {
    /// iOS와 Watch가 공유하는 SwiftData 컨테이너
    static var shared: ModelContainer = {
        let schema = Schema([
            RidingSession.self,
            SpeedPoint.self,
            AltitudePoint.self,
            HeartRatePoint.self,
            PauseEvent.self,
            RidingDiary.self
        ])
        
        // App Groups의 공유 컨테이너 경로
        let appGroupID = "group.com.snowmate.app"
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            fatalError("App Groups 컨테이너를 찾을 수 없습니다. Xcode에서 App Groups 설정을 확인하세요.")
        }
        
        // 데이터베이스 파일 경로
        let storeURL = containerURL.appendingPathComponent("SnowMate.sqlite")
        
        let configuration = ModelConfiguration(
            url: storeURL,
            allowsSave: true
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: configuration
            )
            
            print("✅ 공유 데이터 컨테이너 생성 성공!")
            print("📂 저장 위치: \(storeURL.path)")
            
            return container
        } catch {
            fatalError("ModelContainer 생성 실패: \(error.localizedDescription)")
        }
    }()
}
