//
//  StatRow.swift
//  SnowMateWatch Watch App
//
//  Created by 이혜빈 on 11/9/25.
//

import SwiftUI

// MARK: - 통계 행 컴포넌트
struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    var color: Color = .blue
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color.gradient)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 24)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}
