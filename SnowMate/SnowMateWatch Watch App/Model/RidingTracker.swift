//
//  RidingTracker.swift
//  SnowMateWatch Watch App
//
//  Created by 이혜빈 on 11/8/25.
//

//
//  RidingTracker.swift
//  SnowMateWatch Watch App
//
//  Created by 이혜빈 on 11/8/25.
//

import Foundation
import CoreLocation
import HealthKit
import Combine
import SwiftData

// MARK: - Apple Watch용 라이딩 트래커
@MainActor
class RidingTracker: NSObject, ObservableObject {
    
    // MARK: - Published Properties (UI 바인딩용)
    @Published var currentSession: RidingSession?
    @Published var currentSpeed: Double = 0.0 // km/h
    @Published var currentAltitude: Double = 0.0 // meter
    @Published var currentHeartRate: Double = 0.0 // bpm
    @Published var isTracking: Bool = false
    @Published var isPaused: Bool = false
    @Published var showSlowSpeedAlert: Bool = false
    
    // MARK: - SwiftData
    var modelContext: ModelContext?
    
    // MARK: - Services
    private let locationManager = CLLocationManager()
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var workoutSession: HKWorkoutSession?
    
    // MARK: - Tracking State
    private var lastLocation: CLLocation?
    private var lastAltitude: Double = 0
    private var slowSpeedTimer: Timer?
    private var slowSpeedStartTime: Date?
    
    // MARK: - Constants
    private let slowSpeedThreshold: Double = 10.0 // km/h
    private let slowSpeedDuration: TimeInterval = 30.0 // 30초
    private let locationUpdateInterval: TimeInterval = 2.0 // 2초마다 기록
    
    override init() {
        super.init()
        setupLocationManager()
        requestHealthKitAuthorization()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func requestHealthKitAuthorization() {
        // toShare에 워크아웃 타입 추가
        let typesToShare: Set<HKSampleType> = [
            HKWorkoutType.workoutType()
        ]
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKWorkoutType.workoutType() // 워크아웃 읽기 권한도 추가
        ]
        
        // toShare를 nil이 아닌 실제 Set으로 전달
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if let error = error {
                print("❌ HealthKit 권한 에러: \(error.localizedDescription)")
                return
            }
            
            if success {
                print("✅ HealthKit 권한 허용됨")
            } else {
                print("⚠️ HealthKit 권한 거부됨")
            }
        }
    }

    
    // MARK: - 라이딩 시작
    func startRiding() {
        guard !isTracking else { return }
        
        // 새 세션 생성
        currentSession = RidingSession(startTime: Date())
        isTracking = true
        isPaused = false
        
        // 위치 추적 시작
        locationManager.startUpdatingLocation()
        
        // 심박수 모니터링 시작
        startHeartRateMonitoring()
        
        // HealthKit 워크아웃 세션 시작
        startWorkoutSession()
        
        print("🏂 라이딩 시작!")
    }
    
    // MARK: - 라이딩 종료
    func stopRiding() {
        guard isTracking else { return }
        
        print("🏁 라이딩 종료!")
        
        // 위치 및 심박수 업데이트 중지
        locationManager.stopUpdatingLocation()
        stopHeartRateMonitoring()
        stopWorkoutSession()
        
        // 세션 종료 시간 설정
        currentSession?.endTime = Date()
        
        // 전체 시간 계산
        if let session = currentSession {
            session.totalTime = Date().timeIntervalSince(session.startTime)
            
            // 활동 시간 계산 (전체 시간 - 일시정지 시간)
            let totalPauseTime = session.pauseEvents.reduce(0.0) { $0 + $1.duration }
            session.activeRidingTime = session.totalTime - totalPauseTime
            
            // 평균 속도 계산
            if session.activeRidingTime > 0 {
                session.avgSpeed = (session.totalDistance / 1000.0) / (session.activeRidingTime / 3600.0)
            }
            
            // 평균 심박수 계산
            if !session.heartRatePoints.isEmpty {
                let totalBpm = session.heartRatePoints.reduce(0.0) { $0 + $1.bpm }
                session.avgHeartRate = totalBpm / Double(session.heartRatePoints.count)
            }
        }
        
        // 세션 저장
        if let session = currentSession, let context = modelContext {
            do {
                context.insert(session)
                try context.save()
                print("✅ 세션 저장 완료!")
                
                // 통계 출력
                print("📊 최고 속도: \(session.maxSpeed) km/h")
                print("📊 고도 상승: \(session.elevationGain) m")
                print("📊 슬로프 레벨: \(session.slopeLevel.description)")
                
                // 🆕 iPhone으로 세션 전송
                WatchConnectivityManager.shared.sendRidingSession(session)
                print("📤 iPhone으로 세션 전송 시작...")
                
            } catch {
                print("❌ 세션 저장 실패: \(error)")
            }
        }
        
        // 상태 초기화
        isTracking = false
        isPaused = false
    }
    
    // MARK: - 일시정지
    func pauseRiding() {
        guard isTracking, !isPaused, let session = currentSession else { return }
        
        isPaused = true
        let pauseEvent = PauseEvent(startTime: Date(), reason: .manual)
        session.pauseEvents.append(pauseEvent)
        
        locationManager.stopUpdatingLocation()
        print("⏸️ 라이딩 일시정지")
    }
    
    func resumeRiding() {
        guard isTracking, isPaused, let session = currentSession else { return }
        
        // 마지막 일시정지 이벤트 종료
        if let lastPause = session.pauseEvents.last, lastPause.endTime == nil {
            lastPause.endTime = Date()
        }
        
        isPaused = false
        locationManager.startUpdatingLocation()
        showSlowSpeedAlert = false
        slowSpeedTimer?.invalidate()
        
        print("▶️ 라이딩 재개")
    }
    
    // MARK: - 저속 감지 로직
    private func checkSlowSpeed() {
        guard isTracking, !isPaused else { return }
        
        if currentSpeed < slowSpeedThreshold {
            // 저속 시작
            if slowSpeedStartTime == nil {
                slowSpeedStartTime = Date()
                startSlowSpeedTimer()
            }
        } else {
            // 속도 정상 복귀
            slowSpeedStartTime = nil
            slowSpeedTimer?.invalidate()
            showSlowSpeedAlert = false
        }
    }
    
    private func startSlowSpeedTimer() {
        slowSpeedTimer?.invalidate()
        slowSpeedTimer = Timer.scheduledTimer(withTimeInterval: slowSpeedDuration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                // 30초 동안 저속 유지 → 알림 표시
                self.showSlowSpeedAlert = true
            }
        }
    }
    
    private func autoPauseForSlowSpeed() {
        guard let session = currentSession else { return }
        
        isPaused = true
        let pauseEvent = PauseEvent(startTime: Date(), reason: .slowSpeed)
        session.pauseEvents.append(pauseEvent)
        
        locationManager.stopUpdatingLocation()
        print("⏸️ 저속 감지로 자동 일시정지")
    }
    
    // MARK: - HealthKit 심박수 모니터링
    private func startHeartRateMonitoring() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
        
        heartRateQuery = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, error in
            guard let self = self else { return }
            guard error == nil else {
                print("❌ 초기 심박수 쿼리 에러:", error!.localizedDescription)
                return
            }
            
            if let samples {
                Task { @MainActor in
                    self.processHeartRateSamples(samples)
                }
            }
        }
        
        heartRateQuery?.updateHandler = { [weak self] _, samples, _, _, error in
            guard let self = self else { return }
            guard error == nil else {
                print("❌ 심박수 업데이트 에러:", error!.localizedDescription)
                return
            }
            
            if let samples {
                Task { @MainActor in
                    self.processHeartRateSamples(samples)
                }
            }
        }
        
        if let heartRateQuery {
            healthStore.execute(heartRateQuery)
            print("💓 심박수 모니터링 시작")
        }
    }
    
    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else { return }
        
        Task { @MainActor in
            for sample in heartRateSamples {
                let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                self.currentHeartRate = bpm
                
                if let session = self.currentSession {
                    let point = HeartRatePoint(timestamp: sample.startDate, bpm: bpm)
                    session.heartRatePoints.append(point)
                    
                    if bpm > (session.maxHeartRate ?? 0) {
                        session.maxHeartRate = bpm
                    }
                }
            }
        }
    }
    
    private func stopHeartRateMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
    }
    
    // MARK: - HealthKit 워크아웃 세션
    private func startWorkoutSession() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .snowboarding
        configuration.locationType = .outdoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutSession?.startActivity(with: Date())
        } catch {
            print("워크아웃 세션 시작 실패: \(error.localizedDescription)")
        }
    }
    
    private func stopWorkoutSession() {
        workoutSession?.end()
        workoutSession = nil
    }
}

// MARK: - CLLocationManagerDelegate
extension RidingTracker: CLLocationManagerDelegate {
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            await self.processLocation(location)
        }
    }
    
    private func processLocation(_ location: CLLocation) async {
        guard let session = currentSession, !isPaused else { return }
        
        // 현재 속도 업데이트 (m/s → km/h)
        let speedKmh = location.speed >= 0 ? location.speed * 3.6 : 0
        currentSpeed = speedKmh
        
        // 현재 고도 업데이트
        currentAltitude = location.altitude
        
        // 속도 기록
        let speedPoint = SpeedPoint(
            timestamp: location.timestamp,
            speed: speedKmh,
            location: location.coordinate
        )
        session.speedPoints.append(speedPoint)
        
        // 최고 속도 업데이트
        if speedKmh > session.maxSpeed {
            session.maxSpeed = speedKmh
        }
        
        // 고도 기록 및 계산
        let altitudePoint = AltitudePoint(
            timestamp: location.timestamp,
            altitude: location.altitude,
            location: location.coordinate
        )
        session.altitudePoints.append(altitudePoint)
        
        // 고도 변화 계산
        if lastAltitude != 0 {
            let altitudeDiff = location.altitude - lastAltitude
            if altitudeDiff > 0 {
                session.elevationGain += altitudeDiff
            } else {
                session.elevationLoss += abs(altitudeDiff)
            }
        }
        lastAltitude = location.altitude
        
        // 최대/최소 고도 업데이트
        if location.altitude > session.maxAltitude {
            session.maxAltitude = location.altitude
        }
        if session.minAltitude == 0 || location.altitude < session.minAltitude {
            session.minAltitude = location.altitude
        }
        
        // 거리 계산
        if let last = lastLocation {
            let distance = location.distance(from: last)
            session.totalDistance += distance
        }
        lastLocation = location
        
        // 저속 감지
        checkSlowSpeed()
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 추적 에러: \(error.localizedDescription)")
    }
}
