//
//  CalnendarView.swift
//  SnowMate
//
//  Created by 이혜빈 on 11/8/25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RidingSession.startTime, order: .reverse) private var sessions: [RidingSession]
    
    @State private var selectedDate: Date = Date()
    @State private var showingDiarySheet = false
    @State private var currentMonth: Date = Date()
    @State private var showingMonthYearPicker = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 월 네비게이션 헤더
                monthNavigationHeader
                
                // 캘린더 그리드
                calendarGrid
                
                Divider()
                
                // 선택된 날짜의 라이딩 기록
                if let session = sessionForSelectedDate {
                    ridingDiarySection(for: session)
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("라이딩 기록")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // 년/월 선택 버튼
                    Button(action: { showingMonthYearPicker = true }) {
                        Text(yearString)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    // 오늘 버튼 (오늘이 아닐 때만 표시)
                    if !isToday(selectedDate) || !isCurrentMonth(currentMonth) {
                        Button(action: goToToday) {
                            Text("오늘")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingDiarySheet) {
            if let session = sessionForSelectedDate {
                DiaryEditView(session: session)
            }
        }
        .sheet(isPresented: $showingMonthYearPicker) {
            MonthYearPickerView(selectedDate: $currentMonth, isPresented: $showingMonthYearPicker)
        }
    }
    
    // MARK: - 월 네비게이션 헤더
    private var monthNavigationHeader: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text(monthString)
                .font(.headline)
            
            Spacer()
            
            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.primary)
            }
        }
        .padding()
    }
    
    // MARK: - 캘린더 그리드
    private var calendarGrid: some View {
        VStack(spacing: 0) {
            // 요일 헤더
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            
            // 날짜 그리드
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: isSameDay(date, selectedDate),
                            hasRiding: hasSession(on: date),
                            hasDiary: sessionForDate(date)?.diary != nil
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 50)
                    }
                }
            }
            .padding(.horizontal)
            .frame(height: 320)
        }
    }
    
    // MARK: - 라이딩 일기 섹션
    private func ridingDiarySection(for session: RidingSession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 라이딩 요약
                VStack(alignment: .leading, spacing: 8) {
                    Text("라이딩 요약")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        InfoItem(icon: "clock", value: formatDuration(session.activeRidingTime))
                        InfoItem(icon: "speedometer", value: String(format: "%.1f km/h", session.avgSpeed))
                        InfoItem(icon: "arrow.up.right", value: String(format: "%.0f m", session.elevationGain))
                    }
                }
                
                Divider()
                
                // 일기 섹션
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("오늘의 라이딩 한마디")
                            .font(.headline)
                        Spacer()
                        Button(action: { showingDiarySheet = true }) {
                            Text(session.diary == nil ? "작성하기" : "수정하기")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let note = session.diary?.oneLineReview {
                        Text(note)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    if let photoData = session.diary?.photoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - 빈 상태 뷰
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "snowflake")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("이 날은 라이딩 기록이 없습니다")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Helper Functions
    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: currentMonth)
    }
    
    private var yearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: currentMonth)
    }
    
    private var weekdaySymbols: [String] {
        ["일", "월", "화", "수", "목", "금", "토"]
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = Calendar.current.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date?] = []
        var currentDate = monthFirstWeek.start
        
        while days.count < 42 { // 6주
            if Calendar.current.isDate(currentDate, equalTo: currentMonth, toGranularity: .month) {
                days.append(currentDate)
            } else {
                days.append(nil)
            }
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return days
    }
    
    private func changeMonth(by value: Int) {
        withAnimation {
            if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
                currentMonth = newMonth
            }
        }
    }
    
    // 오늘 날짜로 이동
    private func goToToday() {
        withAnimation {
            selectedDate = Date()
            currentMonth = Date()
        }
    }
    
    // 오늘 날짜인지 확인
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    // 현재 월인지 확인
    private func isCurrentMonth(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
    }
    
    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }
    
    private func hasSession(on date: Date) -> Bool {
        sessions.contains { Calendar.current.isDate($0.startTime, inSameDayAs: date) }
    }
    
    private func sessionForDate(_ date: Date) -> RidingSession? {
        sessions.first { Calendar.current.isDate($0.startTime, inSameDayAs: date) }
    }
    
    private var sessionForSelectedDate: RidingSession? {
        sessionForDate(selectedDate)
    }
    
    // 시간 포맷 헬퍼 함수
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Month/Year Picker View
struct MonthYearPickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    @State private var tempDate: Date
    
    init(selectedDate: Binding<Date>, isPresented: Binding<Bool>) {
        self._selectedDate = selectedDate
        self._isPresented = isPresented
        self._tempDate = State(initialValue: selectedDate.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "년/월 선택",
                    selection: $tempDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .navigationTitle("년/월 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        withAnimation {
                            selectedDate = tempDate
                        }
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let hasRiding: Bool
    let hasDiary: Bool
    let action: () -> Void
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : (hasRiding ? .primary : .secondary))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.blue : Color.clear)
                    )
                
                // 라이딩 기록 인디케이터
                if hasRiding {
                    Circle()
                        .fill(hasDiary ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                } else {
                    Color.clear
                        .frame(width: 6, height: 6)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Info Item
struct InfoItem: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
        }
    }
}

// MARK: - Diary Edit View
struct DiaryEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let session: RidingSession
    
    @State private var diaryNote: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    
    init(session: RidingSession) {
        self.session = session
        _diaryNote = State(initialValue: session.diary?.oneLineReview ?? "")
        _photoData = State(initialValue: session.diary?.photoData)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("오늘의 라이딩 한마디 (50자 이내)", text: $diaryNote, axis: .vertical)
                        .lineLimit(2...3)
                        .onChange(of: diaryNote) { _, newValue in
                            if newValue.count > 50 {
                                diaryNote = String(newValue.prefix(50))
                            }
                        }
                    
                    Text("\(diaryNote.count)/50")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                Section {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let photoData = photoData,
                           let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Label("사진 추가", systemImage: "photo.badge.plus")
                        }
                    }
                    .onChange(of: selectedPhoto) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                photoData = data
                            }
                        }
                    }
                    
                    if photoData != nil {
                        Button("사진 삭제", role: .destructive) {
                            photoData = nil
                            selectedPhoto = nil
                        }
                    }
                } header: {
                    Text("사진")
                }
            }
            .navigationTitle("라이딩 일기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        saveDiary()
                        dismiss()
                    }
                    .disabled(diaryNote.isEmpty)
                }
            }
        }
    }
    
    private func saveDiary() {
        if session.diary == nil {
            // 일기가 없으면 새로 생성
            session.diary = RidingDiary(oneLineReview: diaryNote, photoData: photoData)
        } else {
            // 기존 일기 업데이트
            session.diary?.oneLineReview = diaryNote
            session.diary?.photoData = photoData
        }
        try? modelContext.save()
    }
}
