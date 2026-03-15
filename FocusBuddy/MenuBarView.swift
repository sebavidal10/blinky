//
//  MenuBarView.swift
//
//  Created by Sebastián Vidal Aedo on 14-03-26.
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var timer: PomodoroTimer

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("FocusBuddy")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Text("Hoy: \(timer.totalSessionsToday) 🍅")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 6)

            // Progression info
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("Nivel \(BuddySettings.shared.buddyLevel)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.accentColor)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.1))
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: geo.size.width * BuddySettings.shared.progressToNextLevel)
                    }
                }
                .frame(height: 4)
                .frame(maxWidth: 60)
                
                Spacer()
                
                Text("\(BuddySettings.shared.energyXP) / \(BuddySettings.shared.xpToNextLevel) XP")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            Divider()

            // Pet mood
            HStack(spacing: 10) {
                Text(timer.mood.emoji)
                    .font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text(timer.mood.label)
                        .font(.system(size: 12, weight: .semibold))
                    Text(phaseLabel)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // Timer display
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.06))

                VStack(spacing: 6) {
                    Text(timer.timeString)
                        .font(.system(size: 36, weight: .thin, design: .monospaced))
                        .foregroundColor(.primary)

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.primary.opacity(0.1))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(progressColor)
                                .frame(width: geo.size.width * timer.progress, height: 4)
                                .animation(.linear(duration: 1), value: timer.progress)
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
            }
            .padding(.horizontal, 16)

            // Controls
            HStack(spacing: 8) {
                Button(action: handleMainButton) {
                    Label(mainButtonLabel, systemImage: mainButtonIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(timer.isRunning ? .orange : .blue)
                .disabled(timer.mood == .celebrating)

                Button(action: timer.reset) {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)

                Button(action: timer.skip) {
                    Image(systemName: "forward.end.fill")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            Divider()
                .padding(.top, 10)

            // Sessions dots
            HStack(spacing: 6) {
                ForEach(0..<timer.sessionsUntilLongBreak, id: \.self) { i in
                    Circle()
                        .fill(i < (timer.completedSessions % timer.sessionsUntilLongBreak)
                              ? Color.orange : Color.primary.opacity(0.15))
                        .frame(width: 8, height: 8)
                }
                Spacer()
                Text("Sesión \(timer.completedSessions + 1)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()

            // Buddy Management
            VStack(spacing: 8) {
                Toggle(isOn: Binding(
                    get: { BuddySettings.shared.isBuddyVisible },
                    set: { BuddySettings.shared.isBuddyVisible = $0 }
                )) {
                    HStack {
                        Image(systemName: BuddySettings.shared.isBuddyVisible ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(.secondary)
                        Text("Mostrar Buddy")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()

            // Menu Footer
            HStack(spacing: 12) {
                Button(action: { 
                    AppDelegate.shared.showSettings()
                    AppDelegate.shared.popover?.performClose(nil)
                }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                        Text("Ajustes")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))

                Button(action: { NSApp.terminate(nil) }) {
                    HStack {
                        Text("Salir")
                        Text("⌘Q").font(.system(size: 9)).opacity(0.5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .bold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.primary.opacity(0.03))
        }
        .frame(width: 280)
    }

    // MARK: - Helpers

    var mainButtonLabel: String {
        if timer.isRunning { return "Pausar" }
        return timer.phase == .idle ? "Iniciar" : "Continuar"
    }

    var mainButtonIcon: String {
        timer.isRunning ? "pause.fill" : "play.fill"
    }

    func handleMainButton() {
        if timer.isRunning {
            timer.pause()
        } else {
            timer.start()
        }
    }

    var phaseLabel: String {
        switch timer.phase {
        case .idle:      return "Listo"
        case .working:   return "Enfoque"
        case .breakTime: return "Descanso corto"
        case .longBreak: return "Descanso largo"
        }
    }

    var progressColor: Color {
        switch timer.phase {
        case .working:   return .orange
        case .breakTime: return .green
        case .longBreak: return .blue
        case .idle:      return .gray
        }
    }
}

#Preview {
    MenuBarView()
        .environmentObject(PomodoroTimer.shared)
}
