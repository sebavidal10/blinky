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
    @State private var sessionToDelete: FocusSession? = nil
    @State private var showingClearHistoryAlert = false
    @State private var isListView = false

    var body: some View {
        VStack(spacing: 0) {
            // 1. Header
            ViewHeader(title: Localization.achievements) {
                Button(action: { showingClearHistoryAlert = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red.opacity(0.8))
                        .padding(6)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help(Localization.at("Clear History", "Limpiar Historial"))
            }
            
            // 2. View Mode Selector
            HStack(spacing: 0) {
                ViewModeButton(title: Localization.at("Day", "Día"), icon: "calendar", isSelected: !isListView) {
                    withAnimation { isListView = false }
                }
                ViewModeButton(title: Localization.at("List", "Lista"), icon: "list.bullet", isSelected: isListView) {
                    withAnimation { isListView = true }
                }
            }
            .padding(4)
            .background(Color.primary.opacity(0.04))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            if !isListView {
                dayView
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity))
            } else {
                listView
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            }
        }
        .confirmationDialog(
            Localization.at("Are you sure?", "¿Estás seguro?"),
            isPresented: Binding(
                get: { sessionToDelete != nil },
                set: { if !$0 { sessionToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(Localization.at("Delete", "Eliminar"), role: .destructive) {
                if let session = sessionToDelete {
                    withAnimation {
                        timer.deleteSession(id: session.id)
                    }
                }
                sessionToDelete = nil
            }
            Button(Localization.at("Cancel", "Cancelar"), role: .cancel) {
                sessionToDelete = nil
            }
        } message: {
            Text(Localization.at("This action cannot be undone.", "Esta acción no se puede deshacer."))
        }
        .confirmationDialog(
            Localization.at("Clear All History?", "¿Limpiar todo el historial?"),
            isPresented: $showingClearHistoryAlert,
            titleVisibility: .visible
        ) {
            Button(Localization.at("Clear Everything", "Borrar Todo"), role: .destructive) {
                timer.clearHistory()
            }
            Button(Localization.at("Cancel", "Cancelar"), role: .cancel) {}
        } message: {
            Text(Localization.at("This will permanently delete all your recorded sessions.", "Esto borrará permanentemente todas tus sesiones registradas."))
        }
    }
    
    // MARK: - Day View
    
    private var dayView: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button(action: { moveDate(by: -1) }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text(dateDisplayString)
                        .font(.system(size: 16, weight: .black))
                    
                    if !Calendar.current.isDateInToday(selectedDate) {
                        Button(action: { withAnimation { selectedDate = Date() } }) {
                            Text(Localization.today.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text(Localization.at("Viewing Today", "Viendo Hoy"))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
                .onTapGesture {
                    showDatePicker.toggle()
                }
                .popover(isPresented: $showDatePicker) {
                    CalendarDotsView(selectedDate: $selectedDate)
                        .environmentObject(timer)
                        .frame(width: 280)
                        .onChange(of: selectedDate) { _, _ in
                            showDatePicker = false
                        }
                }
                
                Spacer()
                
                Button(action: { moveDate(by: 1) }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(canMoveForward ? .secondary.opacity(0.6) : .secondary.opacity(0.1))
                }
                .buttonStyle(.plain)
                .disabled(!canMoveForward)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            // Summary Card
            HStack(spacing: 16) {
                SummaryStatView(label: Localization.at("Sessions", "Sesiones"), value: "\(dailyTotal)")
                
                Divider().frame(height: 24)
                
                SummaryStatView(label: Localization.at("Focus", "Enfoque"), value: "\(dailyFocusTime) min")
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // Session List
            ScrollView {
                let filteredHistory = timer.sessionsHistory.filter { 
                    Calendar.current.isDate($0.date, inSameDayAs: selectedDate) 
                }
                
                VStack(spacing: 10) {
                    if filteredHistory.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(filteredHistory.reversed()) { session in
                            SessionRow(session: session, showDate: false) {
                                sessionToDelete = session
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - List View
    
    private var listView: some View {
        ScrollView {
            VStack(spacing: 10) {
                if timer.sessionsHistory.isEmpty {
                    emptyStateView
                } else {
                    ForEach(timer.sessionsHistory) { session in
                        SessionRow(session: session, showDate: true) {
                            sessionToDelete = session
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Subviews & Data
    
    private var dateDisplayString: String {
        StatsView.dateDisplayFormatter.locale = Locale(identifier: Localization.resolvedLanguage == "es" ? "es_ES" : "en_US")
        return StatsView.dateDisplayFormatter.string(from: selectedDate).capitalized
    }
    
    private var dailyTotal: Int {
        timer.sessionsHistory.filter { 
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate) 
        }.count
    }
    
    private var dailyFocusTime: Int {
        timer.sessionsHistory.filter { 
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate) 
        }.reduce(0) { $0 + $1.durationInMinutes }
    }
    
    private var canMoveForward: Bool {
        !Calendar.current.isDateInToday(selectedDate) && selectedDate < Date()
    }
    
    private func moveDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            if days > 0 && newDate > Date() { return }
            withAnimation {
                selectedDate = newDate
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 40)
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.3))
            Text(Localization.noSessions)
                .multilineTextAlignment(.center)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer(minLength: 40)
        }
    }
    
    fileprivate static let dateDisplayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM"
        return formatter
    }()
}

// MARK: - Components

struct ViewModeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .background(isSelected ? Color.accentColor : Color.clear)
            .foregroundColor(isSelected ? .white : .secondary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct SummaryStatView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.primary)
        }
    }
}

struct SessionRow: View {
    @EnvironmentObject var timer: SessionManager
    let session: FocusSession
    var showDate: Bool = false
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.goal)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(formattedDate(session.date))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.3))
                    
                    Text("\(session.durationInMinutes) min")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundColor(.red.opacity(0.4))
                    .padding(8)
                    .background(Color.red.opacity(0.05))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(12)
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = showDate ? SessionRow.listDateFormatter : SessionRow.timeFormatter
        formatter.locale = Locale(identifier: Localization.resolvedLanguage == "es" ? "es_ES" : "en_US")
        return formatter.string(from: date)
    }
    
    private static let listDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM, HH:mm"
        return formatter
    }()
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
