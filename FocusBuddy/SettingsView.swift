//
//  SettingsView.swift
//
//  Created by Sebastián Vidal Aedo on 14-03-26.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timer: PomodoroTimer
    @ObservedObject var buddySettings = BuddySettings.shared

    @State private var workMinutes: Double = 25
    @State private var shortBreakMinutes: Double = 5
    @State private var longBreakMinutes: Double = 15

    var body: some View {
        TabView {
            // MARK: - Timer Tab
            Form {
                Section("Duración de sesiones") {
                    VStack(alignment: .leading) {
                        Label("Enfoque: \(Int(workMinutes)) min", systemImage: "brain.head.profile")
                        Slider(value: $workMinutes, in: 5...60, step: 5)
                            .onChange(of: workMinutes) { v in
                                timer.workDuration = Int(v) * 60
                            }
                    }
                    VStack(alignment: .leading) {
                        Label("Descanso corto: \(Int(shortBreakMinutes)) min", systemImage: "cup.and.saucer")
                        Slider(value: $shortBreakMinutes, in: 1...15, step: 1)
                            .onChange(of: shortBreakMinutes) { v in
                                timer.shortBreakDuration = Int(v) * 60
                            }
                    }
                    VStack(alignment: .leading) {
                        Label("Descanso largo: \(Int(longBreakMinutes)) min", systemImage: "figure.walk")
                        Slider(value: $longBreakMinutes, in: 5...30, step: 5)
                            .onChange(of: longBreakMinutes) { v in
                                timer.longBreakDuration = Int(v) * 60
                            }
                    }
                }
                Section("Sesiones") {
                    Stepper(
                        "Sesiones antes del descanso largo: \(timer.sessionsUntilLongBreak)",
                        value: $timer.sessionsUntilLongBreak,
                        in: 2...8
                    )
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("Timer", systemImage: "timer") }
            .onAppear {
                workMinutes = Double(timer.workDuration / 60)
                shortBreakMinutes = Double(timer.shortBreakDuration / 60)
                longBreakMinutes = Double(timer.longBreakDuration / 60)
            }

            // MARK: - Buddy Tab
            Form {
                Section("Tu Buddy") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                        ForEach(BuddyType.allCases) { buddy in
                            VStack(spacing: 6) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(buddySettings.selectedBuddy == buddy
                                              ? Color.accentColor.opacity(0.2)
                                              : Color.primary.opacity(0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(buddySettings.selectedBuddy == buddy
                                                        ? Color.accentColor
                                                        : Color.clear, lineWidth: 2)
                                        )
                                        .frame(width: 72, height: 72)

                                    Text(buddy.emoji)
                                        .font(.system(size: 36))
                                }
                                Text(buddy.name)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            .onTapGesture {
                                buddySettings.selectedBuddy = buddy
                            }
                        }

                        // Placeholder slots para futuros buddies
                        ForEach(0..<4) { _ in
                            VStack(spacing: 6) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.primary.opacity(0.04))
                                        .frame(width: 72, height: 72)
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.secondary.opacity(0.4))
                                        .font(.system(size: 20))
                                }
                                Text("Próximo")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Tamaño") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Tamaño del buddy")
                            Spacer()
                            Text(sizeLabel)
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                        Slider(value: $buddySettings.buddySize, in: 0.6...1.6, step: 0.2)
                    }
                }

                Section("Stats") {
                    LabeledContent("Sesiones hoy", value: "\(timer.totalSessionsToday) 🍅")
                    LabeledContent("Sesiones totales", value: "\(timer.totalSessionsAllTime)")
                    LabeledContent("Racha actual", value: "\(timer.currentStreak) días 🔥")
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("Buddy", systemImage: "person.fill") }
        }
        .frame(width: 420, height: 440)
    }

    var sizeLabel: String {
        switch buddySettings.buddySize {
        case ..<0.8: return "Pequeño"
        case ..<1.2: return "Normal"
        default:     return "Grande"
        }
    }
}
