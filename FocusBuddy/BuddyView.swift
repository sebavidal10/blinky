//
//  BuddyView.swift
//
//  Created by Sebastián Vidal Aedo on 14-03-26.
//

import SwiftUI
import Combine

struct BuddyView: View {
    @EnvironmentObject var timer: PomodoroTimer
    @ObservedObject var buddySettings = BuddySettings.shared
    @State private var bounce: CGFloat = 0
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var isHovering: Bool = false
    @State private var interactiveBounce: CGFloat = 0
    @State private var touchScale: CGFloat = 1.0
    @State private var typingVibration: CGFloat = 0
    @State private var levelUpGlow: Bool = false
    @State private var auraScale: CGFloat = 1.0
    @State private var smartReminder: String? = nil
    @State private var isHandleHovering: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Drag Handle (Native & Fluid)
            NativeDraggableHandle()
                .frame(width: 40, height: 20)
                .overlay(
                    Image(systemName: "circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(isHandleHovering ? 0.6 : 0.3))
                )
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHandleHovering = hovering
                    }
                }
                .padding(.vertical, 4)
            
            VStack(spacing: 4) {
                // Character Area
                ZStack {
                    // Shadow
                    Ellipse()
                        .fill(Color.black.opacity(0.15))
                        .frame(width: 80, height: 10)
                        .offset(y: 40 + bounce * 0.3)
                        .blur(radius: 4)
                        .opacity(timer.mood == .sleeping ? 0.05 : 0.15)
                    
                    // Focus Aura (Dynamic Glow)
                    Circle()
                        .fill(auraColor)
                        .frame(width: 90, height: 90)
                        .blur(radius: 20)
                        .opacity(timer.phase == .idle ? 0.1 : 0.4)
                        .scaleEffect(auraScale)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: auraScale)
                        .onAppear {
                            auraScale = 1.2
                        }

                    // Buddy emoji
                    Text(buddySettings.selectedBuddy.emoji(for: timer.mood))
                        .font(.system(size: 52 * buddySettings.buddySize))
                        .offset(y: bounce + interactiveBounce)
                        .scaleEffect(scale * touchScale * (isHovering ? 1.08 : 1.0) + typingVibration)
                        .rotationEffect(.degrees(rotation))
                        .shadow(color: .orange.opacity(levelUpGlow ? 0.8 : 0), radius: 20)
                        .overlay(
                            Text("LEVEL UP!")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.orange)
                                .offset(y: -60)
                                .opacity(levelUpGlow ? 1 : 0)
                                .scaleEffect(levelUpGlow ? 1.2 : 0.5)
                        )
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.3), value: timer.mood)
                        .id(timer.mood)
                        .overlay(
                            Group {
                                if let text = smartReminder {
                                    Text(text)
                                        .font(.system(size: 10, weight: .medium))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(8)
                                        .offset(y: -45)
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                }
                            }
                        )
                        .overlay(
                            Text(buddySettings.selectedAccessory.emoji)
                                .font(.system(size: 30 * buddySettings.buddySize))
                                .offset(y: bounce + interactiveBounce - 35 * buddySettings.buddySize)
                                .scaleEffect(scale * touchScale)
                                .shadow(radius: 2)
                        )
                    
                    // Orbital Progress Ring (Traveling Section)
                    if timer.isRunning && timer.phase != .idle {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.15), lineWidth: 4)
                            
                            Circle()
                                .trim(from: 0, to: timer.progress)
                                .stroke(progressColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .rotationEffect(.degrees(-90 + timer.progress * 360))
                        }
                        .frame(width: 110, height: 110)
                        .animation(.linear(duration: 1), value: timer.progress)
                    }
                }
                .onHover { hovering in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isHovering = hovering
                    }
                }
                .contentShape(Rectangle())

                // Progress Timer Text (Relocated)
                if timer.isRunning && timer.phase != .idle {
                    Text(timer.timeString)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.top, 4)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(8)
            .onTapGesture {
                // Interactive jump & scale feedback
                withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                    interactiveBounce = -15
                    touchScale = 1.2
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        interactiveBounce = 0
                        touchScale = 1.0
                    }
                }
            }
            
            Spacer()
        }
        .opacity(buddySettings.buddyOpacity)
        .frame(width: 200, height: 200)
        .onAppear { startAnimations() }
        .onChange(of: timer.mood) { _, _ in
            withAnimation(.none) {
                rotation = 0
                bounce = 0
                scale = 1.0
            }
            startAnimations()
        }
        .onChange(of: timer.phase) { _, newValue in
            updateSmartReminder(for: newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BuddyDidType"))) { _ in
            if timer.mood == .typing {
                withAnimation(.linear(duration: 0.05)) {
                    typingVibration = 0.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
                        typingVibration = 0
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BuddyLevelUp"))) { _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                levelUpGlow = true
                interactiveBounce = -40
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 1.0)) {
                    levelUpGlow = false
                    interactiveBounce = 0
                }
            }
        }
    }

    // MARK: - Visual Attributes
    
    var auraColor: Color {
        switch timer.mood {
        case .focused, .typing, .exhausted: return .orange
        case .celebrating:                  return .green
        case .sleeping:                     return .blue
        case .distracted:                   return .yellow
        default:                            return .white.opacity(0.5)
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

    // MARK: - Animations

    func startAnimations() {
        if timer.mood == .celebrating {
            withAnimation(.easeInOut(duration: 0.12).repeatForever(autoreverses: true)) {
                rotation = 6
            }
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                bounce = -14
            }
            withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                scale = 1.08
            }
            return
        }
        
        if timer.mood == .distracted {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                rotation = 5
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                bounce = -2
            }
            return
        }

        rotation = 0

        withAnimation(.easeInOut(duration: bounceDuration).repeatForever(autoreverses: true)) {
            bounce = bounceAmount
        }
        withAnimation(.easeInOut(duration: scaleDuration).repeatForever(autoreverses: true)) {
            scale = scaleAmount
        }
    }

    var bounceDuration: Double {
        switch timer.mood {
        case .idle:        return 2.0
        case .focused:     return 1.4
        case .tired:       return 3.5
        case .celebrating: return 0.4
        case .sleeping:    return 4.0
        case .typing:      return 1.0
        case .distracted:  return 2.5
        case .exhausted:   return 5.0
        }
    }

    var bounceAmount: CGFloat {
        switch timer.mood {
        case .idle:        return -5
        case .focused:     return -7
        case .tired:       return -2
        case .celebrating: return -14
        case .sleeping:    return -1
        case .typing:      return -6
        case .distracted:  return -3
        case .exhausted:   return -2
        }
    }

    var scaleDuration: Double {
        switch timer.mood {
        case .celebrating: return 0.3
        case .sleeping:    return 3.0
        default:           return 2.5
        }
    }

    var scaleAmount: CGFloat {
        switch timer.mood {
        case .celebrating: return 1.08
        case .sleeping:    return 0.97
        default:           return 1.02
        }
    }


    private func updateSmartReminder(for phase: TimerPhase) {
        if phase == .breakTime || phase == .longBreak {
            let reminders = [
                "¡Bebe agua! 💧",
                "Estira la espalda 🧘",
                "Mira a lo lejos 👁️",
                "Respira profundo 🌬️",
                "Un poco de té? ☕️"
            ]
            smartReminder = reminders.randomElement()
            
            // Hide after 8 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                withAnimation { smartReminder = nil }
            }
        } else {
            smartReminder = nil
        }
    }
}

// MARK: - Helper Components

struct NativeDraggableHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = DraggableNSView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

class DraggableNSView: NSView {
    override func mouseDown(with event: NSEvent) {
        // macOS Native Dragging
        self.window?.performDrag(with: event)
    }
}
