//
//  RidingSession.swift
//  SnowMate
//
//  Created by 이혜빈 on 11/8/25.
//

import Foundation
import SwiftData
import CoreLocation

// MARK: - 라이딩 세션 메인 모델
@Model
final class RidingSession {
    var id: UUID
    var date: Date
    var startTime: Date
    var endTime: Date?
    
    // 속도 데이터
    var maxSpeed: Double // km/h
    var avgSpeed: Double // km/h
    @Relationship(deleteRule: .cascade, inverse: \SpeedPoint.session)
    var speedPoints: [SpeedPoint] = []
    
    // 고도 데이터
    var maxAltitude: Double // meter
    var minAltitude: Double // meter
    var elevationGain: Double // 총 상승 고도
    var elevationLoss: Double // 총 하강 고도
    @Relationship(deleteRule: .cascade, inverse: \AltitudePoint.session)
    var altitudePoints: [AltitudePoint] = []
    
    // 거리 & 시간
    var totalDistance: Double // meter
    var activeRidingTime: TimeInterval // 실제 라이딩 시간 (일시정지 제외)
    var totalTime: TimeInterval // 전체 시간
    
    // 심박수
    var avgHeartRate: Double? // bpm
    var maxHeartRate: Double? // bpm
    @Relationship(deleteRule: .cascade, inverse: \HeartRatePoint.session)
    var heartRatePoints: [HeartRatePoint] = []
    
    // 일시정지 기록
    @Relationship(deleteRule: .cascade, inverse: \PauseEvent.session)
    var pauseEvents: [PauseEvent] = []
    
    // 일기 (캘린더용)
    @Relationship(deleteRule: .cascade)
    var diary: RidingDiary?
    
    // 계산된 속성들
    var slopeLevel: SlopeLevel {
        // 고도 상승량으로 슬로프 난이도 판단
        if elevationGain < 200 {
            return .beginner
        } else if elevationGain < 400 {
            return .intermediate
        } else if elevationGain < 600 {
            return .advanced
        } else {
            return .expert
        }
    }
    
    var isActive: Bool {
        endTime == nil
    }
    
    init(startTime: Date = Date()) {
        self.id = UUID()
        self.date = startTime
        self.startTime = startTime
        self.endTime = nil
        self.maxSpeed = 0
        self.avgSpeed = 0
        self.speedPoints = []
        self.maxAltitude = 0
        self.minAltitude = 0
        self.elevationGain = 0
        self.elevationLoss = 0
        self.altitudePoints = []
        self.totalDistance = 0
        self.activeRidingTime = 0
        self.totalTime = 0
        self.avgHeartRate = nil
        self.maxHeartRate = nil
        self.heartRatePoints = []
        self.pauseEvents = []
        self.diary = nil
    }
}

// MARK: - 실시간 데이터 포인트들
@Model
final class SpeedPoint {
    var timestamp: Date
    var speed: Double // km/h
    var latitude: Double?
    var longitude: Double?
    
    // 역참조 (SwiftData 관계 설정)
    var session: RidingSession?
    
    init(timestamp: Date, speed: Double, latitude: Double? = nil, longitude: Double? = nil) {
        self.timestamp = timestamp
        self.speed = speed
        self.latitude = latitude
        self.longitude = longitude
    }
    
    // 편의 생성자
    convenience init(timestamp: Date, speed: Double, location: CLLocationCoordinate2D?) {
        self.init(timestamp: timestamp, speed: speed)
        if let location = location {
            self.latitude = location.latitude
            self.longitude = location.longitude
        }
    }
}

@Model
final class AltitudePoint {
    var timestamp: Date
    var altitude: Double // meter
    var latitude: Double?
    var longitude: Double?
    
    // 역참조
    var session: RidingSession?
    
    init(timestamp: Date, altitude: Double, latitude: Double? = nil, longitude: Double? = nil) {
        self.timestamp = timestamp
        self.altitude = altitude
        self.latitude = latitude
        self.longitude = longitude
    }
    
    // 편의 생성자
    convenience init(timestamp: Date, altitude: Double, location: CLLocationCoordinate2D?) {
        self.init(timestamp: timestamp, altitude: altitude)
        if let location = location {
            self.latitude = location.latitude
            self.longitude = location.longitude
        }
    }
}

@Model
final class HeartRatePoint {
    var timestamp: Date
    var bpm: Double
    
    // 역참조
    var session: RidingSession?
    
    init(timestamp: Date, bpm: Double) {
        self.timestamp = timestamp
        self.bpm = bpm
    }
}

// MARK: - 일시정지 이벤트
@Model
final class PauseEvent {
    var startTime: Date
    var endTime: Date?
    var reasonRaw: String // enum을 String으로 저장
    
    // 역참조
    var session: RidingSession?
    
    var reason: PauseReason {
        get { PauseReason(rawValue: reasonRaw) ?? .manual }
        set { reasonRaw = newValue.rawValue }
    }
    
    var duration: TimeInterval {
        guard let end = endTime else { return 0 }
        return end.timeIntervalSince(startTime)
    }
    
    init(startTime: Date, reason: PauseReason) {
        self.startTime = startTime
        self.endTime = nil
        self.reasonRaw = reason.rawValue
    }
}

enum PauseReason: String, Codable, CaseIterable {
    case manual = "manual"
    case slowSpeed = "slowSpeed"
    case potentialFall = "potentialFall"
    
    var displayName: String {
        switch self {
        case .manual: return "수동 일시정지"
        case .slowSpeed: return "저속 감지"
        case .potentialFall: return "넘어짐 의심"
        }
    }
}

// MARK: - 캘린더 일기
@Model
final class RidingDiary {
    var id: UUID
    var oneLineReview: String
    var photoData: Data? // 사진 1장 (JPEG 데이터)
    var createdAt: Date
    
    init(oneLineReview: String = "", photoData: Data? = nil) {
        self.id = UUID()
        self.oneLineReview = oneLineReview
        self.photoData = photoData
        self.createdAt = Date()
    }
}

// MARK: - Enums
enum SlopeLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    var emoji: String {
        switch self {
        case .beginner: return "🟢"
        case .intermediate: return "🔵"
        case .advanced: return "⚫️"
        case .expert: return "💎"
        }
    }
    
    var displayName: String {
        switch self {
        case .beginner: return "초급"
        case .intermediate: return "중급"
        case .advanced: return "상급"
        case .expert: return "최상급"
        }
    }
    
    var description: String {
        switch self {
        case .beginner: return "초급 슬로프"
        case .intermediate: return "중급 슬로프"
        case .advanced: return "상급 슬로프"
        case .expert: return "최상급 슬로프"
        }
    }
}
