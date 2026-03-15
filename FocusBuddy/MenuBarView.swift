//
//  MenuBarView.swift
//
//  Created by Sebastián Vidal Aedo on 14-03-26.
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var timer: PomodoroTimer

    @State private var isPreparingSession: Bool = false
    @State private var showingQuitAlert: Bool = false
    @State private var showingSkipAlert: Bool = false
    @State private var showingFinishCycleAlert: Bool = false
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

                Button(action: { showingQuitAlert = true }) {
                    Image(systemName: "power")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red)
                        .frame(width: 36, height: 36)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .help(Localization.quitHelp)
                .confirmationDialog(Localization.quitTitle, isPresented: $showingQuitAlert, titleVisibility: .visible) {
                    Button(Localization.quitButton, role: .destructive) {
                        NSApp.terminate(nil)
                    }
                    Button(Localization.cancelButton, role: .cancel) {}
                } message: {
                    Text(Localization.quitMessage)
                }
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
                Text("\(Localization.today): \(timer.totalSessionsToday) 🍅")
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
                    Text(timer.phase == .idle ? Localization.readyToWork : timer.mood.label)
                        .font(.system(size: 15, weight: .bold))
                    
                    if timer.phase != .idle {
                        Text(timer.currentGoal.isEmpty ? (timer.phase == .working ? Localization.activeFocus : Localization.breakTime) : timer.currentGoal)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    } else {
                        Text(Localization.robotWaiting)
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
                            Text(Localization.newSession)
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
                        TextField(Localization.whatIsYourGoal, text: $timer.currentGoal)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16, weight: .medium))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Button(action: { 
                            isPreparingSession = false
                            timer.start() 
                        }) {
                            Text(Localization.start)
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
                HStack(spacing: 10) {
                    Button(action: handleMainButton) {
                        Label(mainButtonLabel, systemImage: mainButtonIcon)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(timer.isRunning ? .blue : .accentColor)

                    HStack(spacing: 8) {
                        Button(action: { showingFinishCycleAlert = true }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.bordered)
                        .help(Localization.endCycle)
                        .confirmationDialog(Localization.endCycleTitle, isPresented: $showingFinishCycleAlert, titleVisibility: .visible) {
                            Button(Localization.endCycleButton, role: .destructive) {
                                timer.finishFullCycle()
                                isPreparingSession = false
                            }
                            Button(Localization.cancelButton, role: .cancel) {}
                        } message: {
                            Text(Localization.endCycleMessage)
                        }

                        if timer.phase == .working {
                            Button(action: { showingSkipAlert = true }) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                            }
                            .buttonStyle(.bordered)
                            .help(Localization.finishSession)
                            .confirmationDialog(Localization.finishSessionTitle, isPresented: $showingSkipAlert, titleVisibility: .visible) {
                                Button(Localization.finishSessionButton, role: .destructive) {
                                    timer.skip()
                                }
                                Button(Localization.cancelButton, role: .cancel) {}
                            } message: {
                                Text(Localization.finishSessionMessage)
                            }
                        } else {
                            Button(action: timer.skip) {
                                Image(systemName: "forward.end.fill")
                            }
                            .buttonStyle(.bordered)
                            .help(Localization.skipBreak)
                        }
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
                Text("\(Localization.sessionOf) \(timer.completedSessions + 1) \(Localization.of) \(timer.sessionsUntilLongBreak)")
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
                AppearanceToggle(title: Localization.showBuddy, icon: buddySettings.isBuddyVisible ? "eye.fill" : "eye.slash.fill", isOn: Binding(
                    get: { buddySettings.isBuddyVisible },
                    set: { buddySettings.isBuddyVisible = $0 }
                ))

                AppearanceToggle(title: Localization.lightingEffect, icon: buddySettings.showAura ? "sun.max.fill" : "sun.max", isOn: $buddySettings.showAura)
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
        if timer.isRunning { return Localization.pauseLabel }
        return timer.phase == .idle ? Localization.start : Localization.continueLabel
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
        case .idle:      return Localization.phaseReady
        case .working:   return Localization.phaseFocus
        case .breakTime: return Localization.phaseShortBreak
        case .longBreak: return Localization.phaseLongBreak
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
                .background(isSelected ? Color.accentColor : Color.primary.opacity(0.05))
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
