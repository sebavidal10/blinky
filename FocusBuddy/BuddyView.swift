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
    @State private var floatOffset: CGFloat = 0
    @State private var isHovering: Bool = false
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
                    // Shadow (Subtle)
                    Ellipse()
                        .fill(Color.black.opacity(0.15))
                        .frame(width: 70, height: 8)
                        .offset(y: 45)
                        .blur(radius: 4)
                        .scaleEffect(1.0 - (floatOffset / 20))
                    
                    // Focus Aura
                    Circle()
                        .fill(auraColor)
                        .frame(width: 100, height: 100)
                        .blur(radius: 25)
                        .opacity(timer.isRunning ? 0.3 : 0.1)
                        .scaleEffect(auraScale)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: auraScale)

                    // Robot Head
                    Image("RobotBuddy")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .offset(y: floatOffset)
                        .scaleEffect(isHovering ? 1.05 : 1.0)
                        .shadow(radius: 5)
                        .overlay(
                            Group {
                                if let text = smartReminder {
                                    Text(text)
                                        .font(.system(size: 10, weight: .semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(8)
                                        .offset(y: -55)
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                }
                            }
                        )
                    
                    // Orbital Progress Ring
                    if timer.isRunning && timer.phase != .idle {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 3)
                            
                            Circle()
                                .trim(from: 0, to: timer.progress)
                                .stroke(progressColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(-90 + timer.progress * 360))
                        }
                        .frame(width: 115, height: 115)
                        .animation(.linear(duration: 1), value: timer.progress)
                    }
                }
                .onHover { hovering in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isHovering = hovering
                    }
                }
                .contentShape(Rectangle())

                // Progress Timer Text
                if timer.isRunning && timer.phase != .idle {
                    Text(timer.timeString)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(10)
            
            Spacer()
        }
        .opacity(buddySettings.buddyOpacity)
        .frame(width: 180, height: 180)
        .onAppear {
            startAnimations()
            auraScale = 1.15
        }
        .onChange(of: timer.phase) { _, newValue in
            updateSmartReminder(for: newValue)
        }
    }

    var auraColor: Color {
        switch timer.mood {
        case .focused:     return .blue
        case .relaxing:    return .green
        case .celebrating: return .orange
        case .idle:        return .white
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

    func startAnimations() {
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            floatOffset = -8
        }
    }

    private func updateSmartReminder(for phase: TimerPhase) {
        if phase == .breakTime || phase == .longBreak {
            let reminders = ["Bebe agua 💧", "Estira 🧘", "Respira 🌬️", "Té? ☕️"]
            smartReminder = reminders.randomElement()
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                withAnimation { smartReminder = nil }
            }
        } else {
            smartReminder = nil
        }
    }
}

// MARK: - Helper Components

struct NativeDraggableHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { DraggableNSView() }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class DraggableNSView: NSView {
    override func mouseDown(with event: NSEvent) {
        self.window?.performDrag(with: event)
    }
}
