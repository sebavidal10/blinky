//
//  MenuBarView.swift
//
//  Created by Sebastián Vidal Aedo on 14-03-26.
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var timer: PomodoroTimer

    @State private var isPreparingSession: Bool = false
    @State private var currentView: AppView = .timer
    @ObservedObject var buddySettings = BuddySettings.shared

    enum AppView {
        case timer
        case settings
        case stats
    }

    var body: some View {
        VStack(spacing: 0) {
            // Content Switcher
            switch currentView {
            case .timer:
                timerMainView
            case .settings:
                SettingsView()
                    .environmentObject(timer)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .stats:
                StatsView()
                    .environmentObject(timer)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }

            Spacer(minLength: 0)

            Divider()

            // Menu Footer
            HStack(spacing: 8) {
                TabButton(icon: "timer", isSelected: currentView == .timer) {
                    currentView = .timer
                }

                TabButton(icon: "chart.bar.fill", isSelected: currentView == .stats) {
                    currentView = .stats
                }

                TabButton(icon: "gearshape.fill", isSelected: currentView == .settings) {
                    currentView = .settings
                }

                Spacer()

                Button(action: { NSApp.terminate(nil) }) {
                    Image(systemName: "power")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.red.opacity(0.8))
                        .padding(8)
                        .background(Color.red.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Salir ⌘Q")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(VisualEffectView(material: .titlebar, blendingMode: .withinWindow))
        }
        .frame(width: 320, height: 480)
    }

    // MARK: - Subviews

    private var timerMainView: some View {
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
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            // Pet mood / Robot State
            HStack(spacing: 12) {
                RobotFace(mood: timer.mood, isBlinking: false)
                    .scaleEffect(0.5)
                    .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(timer.phase == .idle ? "Listo para trabajar" : timer.mood.label)
                        .font(.system(size: 15, weight: .bold))
                    
                    if timer.phase != .idle {
                        Text(timer.currentGoal.isEmpty ? (timer.phase == .working ? "Enfoque activo" : "Tiempo de descanso") : timer.currentGoal)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Blinky está esperando por ti")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ZStack {
                if timer.phase == .idle && !isPreparingSession {
                    // Step 1: Nueva Sesión Button (Premium Card Style)
                    Button(action: { 
                        timer.currentGoal = ""
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { isPreparingSession = true } 
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.1))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.accentColor)
                            }
                            Text("Nueva Sesión")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.primary.opacity(0.03))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                } else if isPreparingSession && timer.phase == .idle {
                    // Step 2: Preparing Session
                    VStack(spacing: 16) {
                        TextField("¿Cuál es tu objetivo?", text: $timer.currentGoal)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16, weight: .medium))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Button(action: { 
                            isPreparingSession = false
                            timer.start() 
                        }) {
                            Text("Comenzar")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                                .background(Color.accentColor)
                                .cornerRadius(20)
                                .shadow(color: .accentColor.opacity(0.3), radius: 8, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.primary.opacity(0.03))
                    )
                } else {
                    // Step 3: Normal Timer
                    VStack(spacing: 10) {
                        Text(timer.timeString)
                            .font(.system(size: 48, weight: .thin, design: .monospaced))
                            .foregroundColor(.primary)

                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.primary.opacity(0.06))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(progressColor.gradient)
                                .frame(width: 248 * timer.progress, height: 6)
                        }
                        .frame(width: 248)
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.primary.opacity(0.03))
                    )
                }
            }
            .frame(height: 120)
            .padding(.horizontal, 16)

            // Controls
            if timer.phase != .idle {
                HStack(spacing: 8) {
                    Button(action: handleMainButton) {
                        Label(mainButtonLabel, systemImage: mainButtonIcon)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(timer.isRunning ? .blue : .accentColor)

                    Button(action: {
                        timer.reset()
                        isPreparingSession = false
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered)
                    .help("Reiniciar todo")

                    if timer.phase == .working {
                        Button(action: timer.skip) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Finalizar")
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                    } else {
                        Button(action: timer.skip) {
                            Image(systemName: "forward.end.fill")
                        }
                        .buttonStyle(.bordered)
                        .help("Omitir descanso")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }

            // Sessions dots Card
            HStack(spacing: 6) {
                ForEach(0..<timer.sessionsUntilLongBreak, id: \.self) { i in
                    Circle()
                        .fill(i < (timer.completedSessions % timer.sessionsUntilLongBreak)
                              ? progressColor : Color.primary.opacity(0.15))
                        .frame(width: 6, height: 6)
                }
                Spacer()
                Text("Sesión \(timer.completedSessions + 1) de \(timer.sessionsUntilLongBreak)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.primary.opacity(0.02))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Buddy Management Card
            VStack(spacing: 12) {
                AppearanceToggle(title: "Mostrar Buddy", icon: buddySettings.isBuddyVisible ? "eye.fill" : "eye.slash.fill", isOn: Binding(
                    get: { buddySettings.isBuddyVisible },
                    set: { buddySettings.isBuddyVisible = $0 }
                ))

                AppearanceToggle(title: "Efecto de Iluminación", icon: buddySettings.showAura ? "sun.max.fill" : "sun.max", isOn: $buddySettings.showAura)
            }
            .padding(14)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(16)
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity)
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
        case .working:   return .blue
        case .breakTime: return .green
        case .longBreak: return .cyan
        case .idle:      return .gray
        }
    }
}

struct TabButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                .frame(width: 36, height: 36)
                .background(isSelected ? Color.accentColor : Color.clear)
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct AppearanceToggle: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                Spacer()
            }
        }
        .toggleStyle(.switch)
        .controlSize(.small)
    }
}

#Preview {
    MenuBarView()
        .environmentObject(PomodoroTimer.shared)
}
