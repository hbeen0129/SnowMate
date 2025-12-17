//
//  WatchConnectivityManager.swift
//  SnowMate
//
//  Created by 이혜빈 on 11/16/25.
//

import Foundation
import WatchConnectivity
import SwiftData

class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()
    
    private let session: WCSession
    private var modelContext: ModelContext?
    
    private override init() {
        self.session = WCSession.default
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    /// ModelContext 설정 (앱 시작 시 호출)
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// 라이딩 세션을 상대 디바이스로 전송
    func sendRidingSession(_ session: RidingSession) {
        guard WCSession.default.isReachable else {
            print("⚠️ 상대 디바이스에 연결할 수 없습니다")
            return
        }
        
        let sessionData = encodeSession(session)
        
        WCSession.default.sendMessage(
            sessionData,
            replyHandler: { reply in
                print("✅ 세션 전송 성공: \(reply)")
            },
            errorHandler: { error in
                print("❌ 세션 전송 실패: \(error.localizedDescription)")
            }
        )
    }
    
    /// 세션을 Dictionary로 인코딩
    private func encodeSession(_ session: RidingSession) -> [String: Any] {
        var data: [String: Any] = [
            "type": "ridingSession",
            "startTime": session.startTime.timeIntervalSince1970,
            "totalTime": session.totalTime,
            "activeRidingTime": session.activeRidingTime,
            "totalDistance": session.totalDistance,
            "maxSpeed": session.maxSpeed,
            "avgSpeed": session.avgSpeed,
            "maxAltitude": session.maxAltitude,
            "minAltitude": session.minAltitude,
            "elevationGain": session.elevationGain,
            "elevationLoss": session.elevationLoss
        ]
        
        if let endTime = session.endTime {
            data["endTime"] = endTime.timeIntervalSince1970
        }
        
        if let avgHR = session.avgHeartRate {
            data["avgHeartRate"] = avgHR
        }
        
        if let maxHR = session.maxHeartRate {
            data["maxHeartRate"] = maxHR
        }
        
        // 속도 포인트
        let speedPoints = session.speedPoints.map { point in
            [
                "timestamp": point.timestamp.timeIntervalSince1970,
                "speed": point.speed
            ]
        }
        data["speedPoints"] = speedPoints
        
        // 고도 포인트
        let altitudePoints = session.altitudePoints.map { point in
            [
                "timestamp": point.timestamp.timeIntervalSince1970,
                "altitude": point.altitude
            ]
        }
        data["altitudePoints"] = altitudePoints
        
        // 심박수 포인트
        let heartRatePoints = session.heartRatePoints.map { point in
            [
                "timestamp": point.timestamp.timeIntervalSince1970,
                "bpm": point.bpm
            ]
        }
        data["heartRatePoints"] = heartRatePoints
        
        // 일시정지 이벤트
        let pauseEvents = session.pauseEvents.map { event in
            var eventData: [String: Any] = [
                "startTime": event.startTime.timeIntervalSince1970,
                "reason": event.reasonRaw
            ]
            if let endTime = event.endTime {
                eventData["endTime"] = endTime.timeIntervalSince1970
            }
            return eventData
        }
        data["pauseEvents"] = pauseEvents
        
        return data
    }
    
    /// 받은 세션 데이터를 SwiftData에 저장
    private func receiveRidingSession(
        from data: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard let modelContext = self.modelContext else {
            print("❌ ModelContext가 설정되지 않았습니다")
            replyHandler(["status": "error", "message": "ModelContext not configured"])
            return
        }
        
        do {
            // 세션 생성
            let session = RidingSession()
            
            // 기본 정보
            session.startTime = Date(timeIntervalSince1970: data["startTime"] as! TimeInterval)
            if let endTime = data["endTime"] as? TimeInterval {
                session.endTime = Date(timeIntervalSince1970: endTime)
            }
            session.totalTime = data["totalTime"] as! TimeInterval
            session.activeRidingTime = data["activeRidingTime"] as! TimeInterval
            session.totalDistance = data["totalDistance"] as! Double
            
            // 속도
            session.maxSpeed = data["maxSpeed"] as! Double
            session.avgSpeed = data["avgSpeed"] as! Double
            
            // 고도
            session.maxAltitude = data["maxAltitude"] as! Double
            session.minAltitude = data["minAltitude"] as! Double
            session.elevationGain = data["elevationGain"] as! Double
            session.elevationLoss = data["elevationLoss"] as! Double
            
            // 심박수
            session.avgHeartRate = data["avgHeartRate"] as? Double
            session.maxHeartRate = data["maxHeartRate"] as? Double
            
            // 속도 포인트
            if let speedPointsData = data["speedPoints"] as? [[String: Any]] {
                for pointData in speedPointsData {
                    let point = SpeedPoint(
                        timestamp: Date(timeIntervalSince1970: pointData["timestamp"] as! TimeInterval),
                        speed: pointData["speed"] as! Double
                    )
                    session.speedPoints.append(point)
                }
            }
            
            // 고도 포인트
            if let altitudePointsData = data["altitudePoints"] as? [[String: Any]] {
                for pointData in altitudePointsData {
                    let point = AltitudePoint(
                        timestamp: Date(timeIntervalSince1970: pointData["timestamp"] as! TimeInterval),
                        altitude: pointData["altitude"] as! Double
                    )
                    session.altitudePoints.append(point)
                }
            }
            
            // 심박수 포인트
            if let heartRatePointsData = data["heartRatePoints"] as? [[String: Any]] {
                for pointData in heartRatePointsData {
                    let point = HeartRatePoint(
                        timestamp: Date(timeIntervalSince1970: pointData["timestamp"] as! TimeInterval),
                        bpm: pointData["bpm"] as! Double
                    )
                    session.heartRatePoints.append(point)
                }
            }
            
            // 일시정지 이벤트
            if let pauseEventsData = data["pauseEvents"] as? [[String: Any]] {
                for eventData in pauseEventsData {
                    let reasonRaw = eventData["reason"] as! String
                    let event = PauseEvent(
                        startTime: Date(timeIntervalSince1970: eventData["startTime"] as! TimeInterval),
                        reason: PauseReason(rawValue: reasonRaw) ?? .manual
                    )
                    if let endTime = eventData["endTime"] as? TimeInterval {
                        event.endTime = Date(timeIntervalSince1970: endTime)
                    }
                    session.pauseEvents.append(event)
                }
            }
            
            // SwiftData에 저장
            modelContext.insert(session)
            try modelContext.save()
            
            print("✅ 라이딩 세션을 받아서 저장했습니다!")
            print("📊 최고 속도: \(session.maxSpeed) km/h")
            print("📊 고도 상승: \(session.elevationGain) m")
            
            replyHandler(["status": "success"])
            
        } catch {
            print("❌ 세션 저장 실패: \(error.localizedDescription)")
            replyHandler(["status": "error", "message": error.localizedDescription])
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            print("❌ WCSession 활성화 실패: \(error.localizedDescription)")
        } else {
            print("✅ WCSession 활성화 성공: \(activationState.rawValue)")
        }
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("⚠️ WCSession이 비활성화되었습니다")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("⚠️ WCSession이 해제되었습니다")
        session.activate()
    }
    #endif
    
    // 메시지 수신
    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard let type = message["type"] as? String,
              type == "ridingSession" else {
            replyHandler(["status": "error", "message": "Unknown message type"])
            return
        }
        
        // 메인 스레드에서 SwiftData 작업 수행
        DispatchQueue.main.async {
            self.receiveRidingSession(from: message, replyHandler: replyHandler)
        }
    }
}
