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
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Timer Configuration
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Temporizador")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label("Enfoque", systemImage: "brain.head.profile")
                                    Spacer()
                                    Text("\(Int(workMinutes)) min")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 12, design: .monospaced))
                                }
                                Slider(value: $workMinutes, in: 5...60, step: 5)
                                    .onChange(of: workMinutes) { _, newValue in
                                        timer.workDuration = Int(newValue) * 60
                                    }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label("Descanso corto", systemImage: "cup.and.saucer")
                                    Spacer()
                                    Text("\(Int(shortBreakMinutes)) min")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 12, design: .monospaced))
                                }
                                Slider(value: $shortBreakMinutes, in: 1...15, step: 1)
                                    .onChange(of: shortBreakMinutes) { _, newValue in
                                        timer.shortBreakDuration = Int(newValue) * 60
                                    }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label("Descanso largo", systemImage: "figure.walk")
                                    Spacer()
                                    Text("\(Int(longBreakMinutes)) min")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 12, design: .monospaced))
                                }
                                Slider(value: $longBreakMinutes, in: 5...30, step: 5)
                                    .onChange(of: longBreakMinutes) { _, newValue in
                                        timer.longBreakDuration = Int(newValue) * 60
                                    }
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)

                    // Cycles
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Ciclos")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Sesiones antes del descanso largo")
                                .font(.system(size: 13))
                            Spacer()
                            Stepper("", value: $timer.sessionsUntilLongBreak, in: 2...8)
                                .labelsHidden()
                            Text("\(timer.sessionsUntilLongBreak)")
                                .font(.system(size: 13, design: .monospaced))
                                .frame(width: 20)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)

                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .padding(.top, 16) 
            }
        }
        .onAppear {
            workMinutes = Double(timer.workDuration / 60)
            shortBreakMinutes = Double(timer.shortBreakDuration / 60)
            longBreakMinutes = Double(timer.longBreakDuration / 60)
        }
    }

    private func dateSymbol(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date).prefix(1).uppercased()
    }
}

#Preview {
    SettingsView()
        .environmentObject(PomodoroTimer.shared)
}
