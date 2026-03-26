//
//  BuddyView.swift
//
//  Created by Sebastián Vidal Aedo on 14-03-26.
//

import SwiftUI
import Combine

struct BuddyView: View {
    @EnvironmentObject var timer: SessionManager
    @ObservedObject var buddySettings = BuddySettings.shared
    @State private var floatOffset: CGFloat = 0
    @State private var isHovering: Bool = false
    @State private var auraPulse: CGFloat = 1.0
    @State private var blinkScale: CGFloat = 1.0
    @State private var smartReminder: String? = nil
    @State private var showNoteInput: Bool = false
    @State private var noteText: String = ""
    @FocusState private var isNoteFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 12) {
                // Character Area
                ZStack {
                    if buddySettings.showAura {
                        Circle()
                            .fill(auraColor)
                            .frame(width: 100, height: 100)
                            .blur(radius: 20)
                            .opacity((timer.isRunning || timer.meetingCountdown != nil) ? 0.25 : 0.1)
                            .scaleEffect(timer.isRunning ? auraPulse : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isHovering)
                    }
                    
                    if timer.mood == .celebrating {
                        ConfettiView()
                            .frame(width: 160, height: 200)
                            .transition(.opacity)
                    }

                    // NATIVE ROBOT FACE
                    RobotFace(mood: timer.mood, 
                              isRunning: timer.isRunning, 
                              phase: timer.phase,
                              isBlinking: blinkScale < 1.0, 
                              isInsomniaActive: buddySettings.isInsomniaEnabled,
                              meetingCountdown: timer.meetingCountdown)
                        .frame(width: 90, height: 90)
                        .offset(y: floatOffset + 8) // Centralized offset
                        .scaleEffect(isHovering ? 1.05 : 1.0)
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                        .overlay(
                            Group {
                                if let text = smartReminder {
                                    MessageBubble(text: text)
                                        .offset(y: -75)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                        )
                    
                    // Orbital Progress Ring (Integrated)
                    if timer.phase != .idle && !timer.isMeetingPending {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.08), lineWidth: 3)
                            
                            Circle()
                                .trim(from: 0, to: max(0.001, timer.progress))
                                .stroke(progressColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
                        .frame(width: 130, height: 130)
                        .animation(.linear(duration: 1), value: timer.progress)
                    }
                }
                .onHover { hovering in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isHovering = hovering
                    }
                }
                .overlay(
                    HStack(alignment: .bottom) {
                        // Left: Session Icon (Mirroring pencil)
                        VStack {
                            Spacer()
                            if let icon = timer.currentSessionIcon, timer.meetingCountdown == nil {
                                Image(systemName: icon + ".circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.8))
                                    .background(Circle().fill(Color.black.opacity(0.2)))
                                    .transition(.scale.combined(with: .opacity))
                                    .padding(4)
                            }
                        }
                        
                        Spacer()
                        
                        // Right: Pencil Button
                        VStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showNoteInput.toggle()
                                    if showNoteInput {
                                        // Activating app to ensure window can become key
                                        NSApp.activate(ignoringOtherApps: true)
                                        isNoteFocused = true
                                    }
                                }
                            }) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(showNoteInput ? .accentColor : .white.opacity(0.8))
                                    .background(Circle().fill(Color.black.opacity(0.2)))
                            }
                            .buttonStyle(.plain)
                            .transition(.scale.combined(with: .opacity))
                            .help(Localization.quickNoteShortcut)
                            .padding(4)
                        }
                    }
                )
                
                if showNoteInput {
                    VStack(spacing: 8) {
                        TextField(Localization.at("Quick Note...", "Nota rápida..."), text: $noteText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11, weight: .medium))
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial))
                            .focused($isNoteFocused)
                            .onSubmit {
                                if !noteText.isEmpty {
                                    NotesManager.shared.addNote(noteText)
                                    noteText = ""
                                }
                                withAnimation { showNoteInput = false }
                            }
                            .frame(width: 140)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.top, 4)
                }

                // Progress Timer Text
                if timer.phase != .idle {
                    Text(timer.timeString)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 4)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(10)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Localization.buddyAccessibilityLabel)
            .accessibilityValue(Localization.buddyAccessibilityValue(
                phase: timer.phase == .meeting ? Localization.settingsCalendars : (timer.phase == .working ? Localization.phaseFocus : Localization.phaseShortBreak),
                time: timer.timeString
            ))
            
            Spacer()
        }
        .opacity(buddySettings.buddyOpacity)
        .frame(width: 200, height: 280)
        .onAppear {
            startAnimations()
            startBlinking()
            checkFirstLaunchGreeting()
        }
        .onChange(of: timer.phase) { _, newValue in
            updateSmartReminder(for: newValue)
        }
    }

    var auraColor: Color {
        if timer.phase == .meeting { return .teal }
        switch timer.mood {
        case .focused:     return .blue
        case .celebrating: return .orange
        case .idle:        return .white
        }
    }

    var progressColor: Color {
        switch timer.phase {
        case .working: return .blue.opacity(0.8)
        case .meeting: return (timer.isMeetingPending ? Color.secondary : Color.teal).opacity(0.8)
        case .idle:    return .gray.opacity(0.8)
        }
    }

    func startAnimations() {
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            floatOffset = -6
        }
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            auraPulse = 1.2
        }
    }

    func startBlinking() {
        let interval = Double.random(in: 3...7)
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.blink()
        }
    }
    
    private func blink() {
        withAnimation(.easeInOut(duration: 0.08)) {
            blinkScale = 0.1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeInOut(duration: 0.08)) {
                self.blinkScale = 1.0
            }
            self.startBlinking()
        }
    }

    private func updateSmartReminder(for phase: TimerPhase) {
        switch phase {
        case .working, .meeting:
            scheduleRandomReminder()
        case .idle:
            smartReminder = nil
        }
    }
    
    private func scheduleRandomReminder() {
        let interval = Double.random(in: 120...300)
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            guard SessionManager.shared.isRunning,
                  SessionManager.shared.phase != .idle else { return }
            
            self.showRandomReminder()
            self.scheduleRandomReminder()
        }
    }
    
    private func showRandomReminder() {
        let reminders = [
            Localization.reminderDeepBreath,
            Localization.reminderStretchBack,
            Localization.reminderDrinkWater,
            Localization.reminderLookAway,
            Localization.reminderShouldersRelaxed,
            Localization.reminderKeepItUp,
            Localization.reminderStayHydrated,
            Localization.reminderZeroDistractions,
            Localization.reminderReadyFocus
        ]
        
        var selectedReminder = reminders.randomElement() ?? Localization.reminderKeepItUp
        
        // Contextual overrides
        let timer = SessionManager.shared
        if timer.consecutiveMeetings >= 3 {
            selectedReminder = Localization.reminderTooManyMeetings
        } else if timer.focusTimeToday >= 60 && timer.focusTimeToday % 60 < 5 {
            selectedReminder = Localization.reminderGreatProgress(timer.focusTimeToday)
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            smartReminder = selectedReminder
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation { self.smartReminder = nil }
        }
    }

    private func checkFirstLaunchGreeting() {
        let hasGreeted = UserDefaults.standard.bool(forKey: "hasGreetedUser")
        if !hasGreeted {
            smartReminder = Localization.at("Hello! I'm Blinky ⚡️", "¡Hola! Soy Blinky ⚡️")
            UserDefaults.standard.set(true, forKey: "hasGreetedUser")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation { smartReminder = nil }
            }
        }
    }
}

// MARK: - Native Robot Design

struct MessageBubble: View {
    let text: String
    
    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                )
            
            // Comic tail
            Image(systemName: "triangle.fill")
                .resizable()
                .frame(width: 8, height: 6)
                .foregroundColor(.white.opacity(0.2)) // Matching ultraThinMaterial feeling
                .rotationEffect(.degrees(180))
                .offset(y: -1)
        }
    }
}

struct RobotFace: View {
    let mood: PetMood
    let isRunning: Bool
    let phase: TimerPhase
    let isBlinking: Bool
    var isInsomniaActive: Bool = false
    var meetingCountdown: String? = nil
    
    @State private var isBlinkingCountdown: Bool = false
    
    var body: some View {
        ZStack {
            // Single central antenna
            Capsule()
                .fill(Color(white: 0.8))
                .frame(width: 4, height: 12)
                .offset(y: -42)

            // Outer Head (Squared with rounded corners)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.95), .white.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 72)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
                )
            
            // Screen / Face Plate (Darker squared area)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(white: 0.08))
                .frame(width: 64, height: 50)
                .shadow(inner: .black.opacity(0.6), radius: 3)
            
            
            // Interaction: Eyes or PAUSE or COUNTDOWN
            if let countdown = meetingCountdown {
                Text(countdown)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(.orange)
                    .opacity(isBlinkingCountdown ? 0.3 : 1.0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                            isBlinkingCountdown = true
                        }
                    }
            } else if !isRunning && phase != .idle {
                Text(Localization.pauseLabel.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(statusColor)
            } else {
                HStack(spacing: 14) {
                    Eye(mood: mood, isBlinking: isBlinking, isInsomniaActive: isInsomniaActive)
                    Eye(mood: mood, isBlinking: isBlinking, isInsomniaActive: isInsomniaActive)
                }
                .offset(y: -2)
                .overlay(
                    // Focus Glasses Accessory
                    FocusGlasses()
                        .opacity(mood == .focused ? 1 : 0)
                        .scaleEffect(mood == .focused ? 1 : 0.8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: mood)
                )
            }
            
            // Status Indicator (Small dot)
            Circle()
                .fill(statusColor.opacity(0.8))
                .frame(width: 4, height: 4)
                .blur(radius: 0.5)
                .offset(x: 22, y: -16)
        }
    }
    
    var statusColor: Color {
        switch mood {
        case .focused: return .blue
        case .celebrating: return .orange
        case .idle: return .white
        }
    }
}

struct FocusGlasses: View {
    var body: some View {
        HStack(spacing: 8) {
            // Lens Left
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.blue.opacity(0.6), lineWidth: 1.5)
                .background(Color.blue.opacity(0.1))
                .frame(width: 24, height: 18)
            
            // Lens Right
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.blue.opacity(0.6), lineWidth: 1.5)
                .background(Color.blue.opacity(0.1))
                .frame(width: 24, height: 18)
        }
        .overlay(
            // Bridge
            Capsule()
                .fill(Color.blue.opacity(0.6))
                .frame(width: 10, height: 2)
                .offset(y: -2),
            alignment: .center
        )
    }
}

struct Eye: View {
    let mood: PetMood
    let isBlinking: Bool
    var isInsomniaActive: Bool = false
    
    var body: some View {
        Group {
            if isBlinking {
                Capsule()
                    .fill(eyeColor)
                    .frame(width: 14, height: 2)
            } else {
                switch mood {
                case .celebrating:
                    // Happy ^ shape
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 8))
                        path.addLine(to: CGPoint(x: 7, y: 0))
                        path.addLine(to: CGPoint(x: 14, y: 8))
                    }
                    .stroke(eyeColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .frame(width: 14, height: 8)
                
                case .focused:
                    // Determinate horizontal bars
                    RoundedRectangle(cornerRadius: 1)
                        .fill(eyeColor)
                        .frame(width: 12, height: 4)
                
                case .idle:
                    // Soft circular eyes for a friendlier "ready" look
                    Circle()
                        .fill(eyeColor.opacity(0.6))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .animation(.spring(response: 0.2), value: mood)
    }
    
    var eyeColor: Color {
        if isInsomniaActive { return .orange }
        switch mood {
        case .focused: return .blue.opacity(0.9)
        case .celebrating: return .orange.opacity(0.9)
        case .idle: return .white.opacity(0.8)
        }
    }
}

// Shadows extension for SwiftUI
extension View {
    func shadow(inner color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) -> some View {
        self.overlay(
            self.mask(self)
                .foregroundColor(.clear)
                .overlay(
                    self.mask(self)
                        .shadow(color: color, radius: radius, x: x, y: y)
                )
                .opacity(0.5)
        )
    }
}
