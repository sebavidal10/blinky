//
//  StatsView.swift
//  FocusBuddy
//
//  Created by Sebastián Vidal Aedo on 14-03-26.
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var timer: PomodoroTimer
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text("Mis Logros")
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 16)

            // Summary Cards
            HStack(spacing: 12) {
                StatCard(title: "Hoy", value: "\(timer.totalSessionsToday)", type: .today)
                StatCard(title: "Total", value: "\(timer.totalSessionsAllTime)", type: .total)
                StatCard(title: "Racha", value: "\(timer.currentStreak)", type: .streak)
            }
            .padding(.horizontal, 24)

            Text("HISTORIAL RECIENTE")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

            // History List
            ScrollView {
                VStack(spacing: 12) {
                    if timer.sessionsHistory.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.3))
                            Text("Aún no hay sesiones registradas.\n¡Empieza tu primer pomodoro!")
                                .multilineTextAlignment(.center)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(timer.sessionsHistory.reversed()) { session in
                            SessionRow(session: session)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let type: BlinkyIcon.IconType

    var body: some View {
        VStack(spacing: 12) {
            BlinkyIcon(type: type)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}

// MARK: - Blinky Style Components

struct BlinkyIcon: View {
    enum IconType {
        case today
        case total
        case streak
    }
    
    let type: IconType
    
    var body: some View {
        ZStack {
            // Mini Head Hardware
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.95), .white.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
                )
            
            // Mini Screen Plate
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(white: 0.1))
                .frame(width: 32, height: 26)
            
            // Symbol
            symbol
        }
    }
    
    @ViewBuilder
    private var symbol: some View {
        switch type {
        case .today:
            // Tech Clock
            Image(systemName: "clock.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.blue)
            
        case .total:
            // Tech Star
            Image(systemName: "star.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.green)
            
        case .streak:
            // Power Cell / Bolt
            Image(systemName: "bolt.fill")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(.orange)
        }
    }
}

struct SessionRow: View {
    let session: FocusSession
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.goal)
                    .font(.system(size: 13, weight: .bold))
                
                Text(formattedDate(session.date))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(session.durationInMinutes) min")
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(.accentColor)
                .cornerRadius(6)
        }
        .padding(12)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(10)
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
