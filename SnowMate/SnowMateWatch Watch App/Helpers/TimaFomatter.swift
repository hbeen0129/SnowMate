//
//  TimaFomatter.swift
//  SnowMateWatch Watch App
//
//  Created by 이혜빈 on 11/9/25.
//

import Foundation

// MARK: - 시간 포맷팅 유틸리티
struct TimeFormatter {
    /// 시간 간격을 "시간 분" 형식으로 변환
    static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else {
            return "\(minutes)분"
        }
    }
}
