//
//  StatsView.swift
//  Blinky
//
//  Created by Sebastián Vidal Aedo on 14-03-26.
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var timer: SessionManager
    @State private var selectedDate = Date()
    @State private var showDatePicker = false

    var body: some View {
        VStack(spacing: 0) {            // Title & Date Picker
            VStack(spacing: 12) {
                HStack {
                    Text(Localization.achievements)
                        .font(.system(size: 16, weight: .bold))
                    
                    if !Calendar.current.isDateInToday(selectedDate) {
                        Button(action: { 
                            withAnimation {
                                selectedDate = Date()
                            }
                        }) {
                            Text(Localization.today)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.accentColor)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button(action: { moveDate(by: -1) }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { showDatePicker.toggle() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10))
                                Text(dateDisplayString)
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showDatePicker) {
                            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .frame(width: 280)
                                .padding()
                                .onChange(of: selectedDate) { _, _ in
                                    showDatePicker = false
                                }
                        }
                        
                        Button(action: { moveDate(by: 1) }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(canMoveForward ? .secondary : .secondary.opacity(0.2))
                        }
                        .buttonStyle(.plain)
                        .disabled(!canMoveForward)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 16)

            // History List
            ScrollView {
                VStack(spacing: 12) {
                    let filteredHistory = timer.sessionsHistory.filter { 
                        Calendar.current.isDate($0.date, inSameDayAs: selectedDate) 
                    }
                    
                    if filteredHistory.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.3))
                            Text(Localization.noSessions)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(filteredHistory.reversed()) { session in
                            SessionRow(session: session)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    private var dateDisplayString: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return Localization.today
        } else if Calendar.current.isDateInYesterday(selectedDate) {
            return Localization.at("Yesterday", "Ayer")
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            formatter.locale = Locale(identifier: Localization.resolvedLanguage == "es" ? "es_ES" : "en_US")
            return formatter.string(from: selectedDate)
        }
    }
    
    private var dailyTotal: Int {
        timer.sessionsHistory.filter { 
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate) 
        }.count
    }
    
    private var canMoveForward: Bool {
        !Calendar.current.isDateInToday(selectedDate) && selectedDate < Date()
    }
    
    private func moveDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            if days > 0 && newDate > Date() { return }
            selectedDate = newDate
        }
    }
}

// MARK: - Blinky Style Components

struct SessionRow: View {
    @EnvironmentObject var timer: SessionManager
    let session: FocusSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.goal)
                .font(.system(size: 13, weight: .bold))
                .lineLimit(2)
            
            HStack(spacing: 8) {
                Text(formattedDate(session.date))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Circle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 2, height: 2)
                
                Text("\(session.durationInMinutes) min")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        timer.deleteSession(id: session.id)
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(.red.opacity(0.8))
                        .frame(width: 22, height: 22)
                        .background(Color.red.opacity(0.05))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(10)
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM, HH:mm"
        formatter.locale = Locale(identifier: Localization.resolvedLanguage == "es" ? "es_ES" : "en_US")
        return formatter.string(from: date)
    }
}


