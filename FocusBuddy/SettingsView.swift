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
            // MARK: - Insights Tab
            ScrollView {
                VStack(spacing: 24) {
                    // Weekly Chart Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Productividad Semanal")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .bottom, spacing: 12) {
                            ForEach(timer.sessionsInLast7Days(), id: \.0) { date, count in
                                VStack(spacing: 8) {
                                    ZStack(alignment: .bottom) {
                                        Capsule()
                                            .fill(Color.primary.opacity(0.05))
                                            .frame(width: 25, height: 120)
                                        
                                        Capsule()
                                            .fill(Color.orange.gradient)
                                            .frame(width: 25, height: max(6, CGFloat(count) * 15))
                                            .animation(.spring(), value: count)
                                    }
                                    
                                    Text(dateSymbol(for: date))
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    
                    // Lifetime Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Tus Logros")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                            BadgeCell(title: "Primer Paso", icon: "seedling", active: timer.totalSessionsAllTime >= 1)
                            BadgeCell(title: "Enfocado", icon: "brain", active: timer.totalSessionsAllTime >= 10)
                            BadgeCell(title: "Maestro", icon: "medal", active: timer.totalSessionsAllTime >= 50)
                            BadgeCell(title: "Racha 3 días", icon: "flame", active: timer.currentStreak >= 3)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
                .padding(20)
            }
            .tabItem { Label("Insights", systemImage: "chart.bar.fill") }

            // MARK: - Timer Tab
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Duración de sesiones")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading) {
                                Label("Enfoque: \(Int(workMinutes)) min", systemImage: "brain.head.profile")
                                Slider(value: $workMinutes, in: 5...60, step: 5)
                                    .onChange(of: workMinutes) { _ , newValue in
                                        timer.workDuration = Int(newValue) * 60
                                    }
                            }
                            VStack(alignment: .leading) {
                                Label("Descanso corto: \(Int(shortBreakMinutes)) min", systemImage: "cup.and.saucer")
                                Slider(value: $shortBreakMinutes, in: 1...15, step: 1)
                                    .onChange(of: shortBreakMinutes) { _ , newValue in
                                        timer.shortBreakDuration = Int(newValue) * 60
                                    }
                            }
                            VStack(alignment: .leading) {
                                Label("Descanso largo: \(Int(longBreakMinutes)) min", systemImage: "figure.walk")
                                Slider(value: $longBreakMinutes, in: 5...30, step: 5)
                                    .onChange(of: longBreakMinutes) { _ , newValue in
                                        timer.longBreakDuration = Int(newValue) * 60
                                    }
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Configuración de Cilos")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Stepper(
                            "Sesiones antes del descanso largo: \(timer.sessionsUntilLongBreak)",
                            value: $timer.sessionsUntilLongBreak,
                            in: 2...8
                        )
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
                .padding(20)
            }
            .tabItem { Label("Timer", systemImage: "timer") }
            .onAppear {
                workMinutes = Double(timer.workDuration / 60)
                shortBreakMinutes = Double(timer.shortBreakDuration / 60)
                longBreakMinutes = Double(timer.longBreakDuration / 60)
            }

            // MARK: - Buddy Tab
            ScrollView {
                VStack(spacing: 24) {
                    // Coin Counter Header
                    HStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Text("🪙")
                            Text("\(buddySettings.energyCoins)")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.orange.opacity(0.1)))
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Tienda de Buddies")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 85))], spacing: 16) {
                            ForEach(BuddyType.allCases) { buddy in
                                let isUnlocked = buddySettings.unlockedBuddyIDs.contains(buddy.id)
                                VStack(spacing: 6) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(buddySettings.selectedBuddy == buddy
                                                  ? Color.accentColor.opacity(0.15)
                                                  : Color.primary.opacity(0.04))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(buddySettings.selectedBuddy == buddy
                                                            ? Color.accentColor
                                                            : Color.clear, lineWidth: 2)
                                            )
                                            .frame(width: 72, height: 72)
                                            .opacity(isUnlocked ? 1.0 : 0.6)

                                        Text(buddy.emoji)
                                            .font(.system(size: 36))
                                            .grayscale(isUnlocked ? 0 : 1.0)
                                            .opacity(isUnlocked ? 1.0 : 0.5)
                                        
                                        if !isUnlocked {
                                            VStack(spacing: 2) {
                                                Image(systemName: "lock.fill")
                                                    .font(.system(size: 10))
                                                Text("\(buddy.price)")
                                                    .font(.system(size: 9, weight: .bold))
                                            }
                                            .foregroundColor(.white)
                                            .padding(4)
                                            .background(Circle().fill(Color.black.opacity(0.6)))
                                            .offset(x: 25, y: 25)
                                        }
                                    }
                                    Text(buddy.name)
                                        .font(.system(size: 11))
                                        .foregroundColor(buddySettings.selectedBuddy == buddy ? .primary : .secondary)
                                }
                                .onTapGesture {
                                    if isUnlocked {
                                        buddySettings.selectedBuddy = buddy
                                    } else if buddySettings.energyCoins >= buddy.price {
                                        buddySettings.buyBuddy(buddy)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Accesorios")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 16) {
                            ForEach(Accessory.allCases) { acc in
                                let isUnlocked = buddySettings.unlockedAccessoryIDs.contains(acc.id)
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(buddySettings.selectedAccessory == acc
                                                  ? Color.orange.opacity(0.2)
                                                  : Color.primary.opacity(0.04))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Circle()
                                                    .stroke(buddySettings.selectedAccessory == acc
                                                            ? Color.orange
                                                            : Color.clear, lineWidth: 2)
                                            )
                                        
                                        if acc == .none {
                                            Image(systemName: "slash.circle")
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text(acc.emoji)
                                                .font(.system(size: 24))
                                                .grayscale(isUnlocked ? 0 : 1.0)
                                                .opacity(isUnlocked ? 1.0 : 0.5)
                                        }
                                        
                                        if !isUnlocked && acc != .none {
                                            Text("\(acc.price)")
                                                .font(.system(size: 8, weight: .black))
                                                .foregroundColor(.white)
                                                .padding(3)
                                                .background(Circle().fill(Color.orange))
                                                .offset(x: 18, y: 18)
                                        }
                                    }
                                    Text(acc.rawValue.capitalized)
                                        .font(.system(size: 9))
                                        .foregroundColor(buddySettings.selectedAccessory == acc ? .primary : .secondary)
                                }
                                .onTapGesture {
                                    if isUnlocked {
                                        buddySettings.selectedAccessory = acc
                                    } else if buddySettings.energyCoins >= acc.price {
                                        buddySettings.buyAccessory(acc)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Apariencia")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label("Tamaño", systemImage: "ruler")
                                    Spacer()
                                    Text(sizeLabel).foregroundColor(.secondary).font(.system(size: 12))
                                }
                                Slider(value: $buddySettings.buddySize, in: 0.6...1.6, step: 0.2)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label("Opacidad", systemImage: "circle.lefthalf.filled")
                                    Spacer()
                                    Text("Opacidad: \(Int(buddySettings.buddyOpacity * 100))%").foregroundColor(.secondary).font(.system(size: 12))
                                }
                                Slider(value: $buddySettings.buddyOpacity, in: 0.2...1.0, step: 0.1)
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Progresión")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Nivel \(buddySettings.buddyLevel)")
                                    .font(.system(size: 18, weight: .bold))
                                Spacer()
                                Text("\(buddySettings.energyXP) XP")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            ProgressView(value: buddySettings.progressToNextLevel)
                                .tint(.orange)
                            
                            HStack {
                                LabeledContent("Sesiones hoy", value: "\(timer.totalSessionsToday) 🍅")
                                Spacer()
                                LabeledContent("Racha", value: "\(timer.currentStreak) días 🔥")
                            }
                            .font(.system(size: 12))
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Salud y Bienestar")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 20) {
                            HStack {
                                Label("Recordatorios de Salud", systemImage: "heart.fill")
                                Spacer()
                                Text("Activados").foregroundColor(.green).font(.system(size: 12))
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    
                }
                .padding(20)
            }
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

    private func dateSymbol(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // Mon, Tue, etc.
        return formatter.string(from: date).prefix(1).uppercased()
    }
}

struct BadgeCell: View {
    let title: String
    let icon: String
    let active: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(active ? .orange : .secondary.opacity(0.3))
                .frame(width: 50, height: 50)
                .background(active ? Color.orange.opacity(0.1) : Color.primary.opacity(0.03))
                .clipShape(Circle())
            
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(active ? .primary : .secondary)
        }
        .frame(width: 80)
    }
}
