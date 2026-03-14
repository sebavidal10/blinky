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

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .gesture(dragGesture)

            VStack(spacing: 4) {
                ZStack {
                    // Shadow
                    Ellipse()
                        .fill(Color.black.opacity(0.15))
                        .frame(width: 80, height: 10)
                        .offset(y: 40 + bounce * 0.3)
                        .blur(radius: 4)

                    // Buddy emoji
                    Text(timer.mood.emoji)
                        .font(.system(size: 52 * buddySettings.buddySize))
                        .offset(y: bounce)
                        .scaleEffect(scale)
                        .rotationEffect(.degrees(rotation))
                        .id(timer.mood)
                }
                .frame(height: 120)

                // Progress ring
                if timer.phase != .idle {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 3)
                            .frame(width: 40, height: 40)

                        Circle()
                            .trim(from: 0, to: timer.progress)
                            .stroke(progressColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: timer.progress)

                        Text(timer.timeString)
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                } else {
                    Text("")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(8)
        }
        .frame(width: 130, height: 170)
        .onAppear { startAnimations() }
        .onChange(of: timer.mood) { _ in
            withAnimation(.none) {
                rotation = 0
                bounce = 0
                scale = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                startAnimations()
            }
        }
    }

    // MARK: - Progress color

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
        }
    }

    var bounceAmount: CGFloat {
        switch timer.mood {
        case .idle:        return -5
        case .focused:     return -7
        case .tired:       return -2
        case .celebrating: return -14
        case .sleeping:    return -1
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

    // MARK: - Drag to reposition

    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if let window = NSApp.windows.first(where: { $0.level == .floating }) {
                    let origin = window.frame.origin
                    window.setFrameOrigin(NSPoint(
                        x: origin.x + value.translation.width,
                        y: origin.y - value.translation.height
                    ))
                }
            }
    }
}

#Preview {
    BuddyView()
        .environmentObject(PomodoroTimer.shared)
        .background(Color.gray.opacity(0.3))
}
