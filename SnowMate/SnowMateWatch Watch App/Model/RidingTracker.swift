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
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
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
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if let error = error {
                print("HealthKit 권한 에러: \(error.localizedDescription)")
            } else {
                print("✅ HealthKit 권한 획득: \(success)")
            }
        }
    }
    
    private func checkAndRequestHealthKitAuthorization(completion: @escaping (Bool) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(false)
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            heartRateType,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        // 권한 상태 확인
        let status = healthStore.authorizationStatus(for: heartRateType)
        
        print("💡 현재 HealthKit 권한 상태: \(status.rawValue)")
        
        // 권한 요청 (이미 결정되었어도 다시 요청 - 팝업은 안 뜨지만 completion은 호출됨)
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if let error = error {
                print("❌ HealthKit 권한 요청 에러: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ HealthKit 권한 요청 완료: \(success)")
                completion(success)
            }
        }
    }
    
    // MARK: - 라이딩 시작
    func startRiding() {
        guard !isTracking else { return }
        
        // HealthKit 권한 먼저 확인 및 요청
        checkAndRequestHealthKitAuthorization { [weak self] authorized in
            guard let self = self, authorized else {
                print("❌ HealthKit 권한 거부됨")
                return
            }
            
            Task { @MainActor in
                // 새 세션 생성
                self.currentSession = RidingSession(startTime: Date())
                self.isTracking = true
                self.isPaused = false
                
                // HealthKit 워크아웃 세션 시작 (먼저!)
                self.startWorkoutSession()
                
                // 위치 추적 시작
                self.locationManager.startUpdatingLocation()
                
                // 심박수 모니터링 시작
                self.startHeartRateMonitoring()
                
                print("🏂 라이딩 시작!")
            }
        }
    }
    
    // MARK: - 라이딩 종료
    func stopRiding() {
        guard isTracking, let session = currentSession else { return }
        
        // 세션 종료 시간 기록
        session.endTime = Date()
        session.totalTime = session.endTime!.timeIntervalSince(session.startTime)
        
        // 평균 속도 계산
        if !session.speedPoints.isEmpty {
            session.avgSpeed = session.speedPoints.map { $0.speed }.reduce(0, +) / Double(session.speedPoints.count)
        }
        
        // 평균 심박수 계산
        if !session.heartRatePoints.isEmpty {
            session.avgHeartRate = session.heartRatePoints.map { $0.bpm }.reduce(0, +) / Double(session.heartRatePoints.count)
        }
        
        // 실제 라이딩 시간 계산 (일시정지 시간 제외)
        let totalPauseDuration = session.pauseEvents.reduce(0.0) { $0 + $1.duration }
        session.activeRidingTime = session.totalTime - totalPauseDuration
        
        // SwiftData에 저장
        saveSession()
        
        // 추적 중지
        locationManager.stopUpdatingLocation()
        stopHeartRateMonitoring()
        stopWorkoutSession()
        
        isTracking = false
        isPaused = false
        slowSpeedTimer?.invalidate()
        
        print("🏁 라이딩 종료!")
        print("📊 최고 속도: \(session.maxSpeed) km/h")
        print("📊 고도 상승: \(session.elevationGain) m")
        print("📊 슬로프 레벨: \(session.slopeLevel.description)")
    }
    
    // MARK: - SwiftData 저장
    private func saveSession() {
        guard let session = currentSession, let context = modelContext else {
            print("❌ ModelContext가 없습니다.")
            return
        }
        
        // SwiftData에 저장
        context.insert(session)
        
        do {
            try context.save()
            print("✅ 세션 저장 완료!")
        } catch {
            print("❌ 세션 저장 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 일시정지
    func pauseRiding() {
        guard isTracking, !isPaused, let session = currentSession else { return }
        
        isPaused = true
        let pauseEvent = PauseEvent(startTime: Date(), reason: .manual)
        session.pauseEvents.append(pauseEvent)
        
        locationManager.stopUpdatingLocation()
        
        // 워크아웃 세션 일시정지
        workoutSession?.pause()
        
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
        
        // 워크아웃 세션 재개
        workoutSession?.resume()
        
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
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            print("❌ 심박수 타입을 가져올 수 없음")
            return
        }
        
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
                
                print("💓 심박수 업데이트: \(Int(bpm)) bpm")
                
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
            print("💓 심박수 모니터링 중지")
        }
    }
    
    // MARK: - HealthKit 워크아웃 세션
    private func startWorkoutSession() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .snowboarding
        configuration.locationType = .outdoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            
            // 🔥 중요: Delegate 설정!
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            
            // 데이터 소스 설정
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )
            
            // 세션 시작
            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { success, error in
                if let error = error {
                    print("❌ 워크아웃 빌더 시작 실패: \(error.localizedDescription)")
                } else {
                    print("✅ 워크아웃 빌더 시작 성공")
                }
            }
            
            print("✅ 워크아웃 세션 시작")
        } catch {
            print("❌ 워크아웃 세션 시작 실패: \(error.localizedDescription)")
        }
    }
    
    private func stopWorkoutSession() {
        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: Date()) { success, error in
            if let error = error {
                print("❌ 워크아웃 종료 실패: \(error.localizedDescription)")
            }
        }
        
        workoutSession = nil
        workoutBuilder = nil
        print("✅ 워크아웃 세션 종료")
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
        print("❌ 위치 추적 에러: \(error.localizedDescription)")
    }
}

// MARK: - HKWorkoutSessionDelegate
extension RidingTracker: HKWorkoutSessionDelegate {
    
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                   didChangeTo toState: HKWorkoutSessionState,
                                   from fromState: HKWorkoutSessionState,
                                   date: Date) {
        Task { @MainActor in
            switch toState {
            case .running:
                print("✅ 워크아웃 세션: 실행 중")
            case .paused:
                print("⏸️ 워크아웃 세션: 일시정지")
            case .stopped:
                print("🛑 워크아웃 세션: 중지됨")
            case .ended:
                print("🏁 워크아웃 세션: 종료됨")
            default:
                print("ℹ️ 워크아웃 세션 상태: \(toState.rawValue)")
            }
        }
    }
    
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                   didFailWithError error: Error) {
        Task { @MainActor in
            print("❌ 워크아웃 세션 에러: \(error.localizedDescription)")
        }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension RidingTracker: HKLiveWorkoutBuilderDelegate {
    
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                                   didCollectDataOf collectedTypes: Set<HKSampleType>) {
        Task { @MainActor in
            for type in collectedTypes {
                if type == HKObjectType.quantityType(forIdentifier: .heartRate) {
                    print("💓 워크아웃 빌더에서 심박수 데이터 수집 중")
                }
            }
        }
    }
    
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // 워크아웃 이벤트 수집
    }
}
