//
//  SystemStatsView.swift
//  Blinky
//

import SwiftUI

struct SystemStatsView: View {
    @ObservedObject var monitor = SystemMonitor.shared
    @State private var isRefreshing = false
    
    var body: some View {
        VStack(spacing: 0) {
            ViewHeader(title: Localization.systemStats) {
                Button(action: {
                    isRefreshing = true
                    monitor.updateStats()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        isRefreshing = false
                    }
                }) {
                    SyncIcon(isFetching: isRefreshing, color: .primary, size: 12)
                        .frame(width: 24, height: 24)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isRefreshing)
            }
            
            ScrollView {
                VStack(spacing: 16) {
                    
                    // Uptime
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.secondary)
                        Text(Localization.uptime)
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Text(monitor.uptimeString)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                    }
                    .padding(12)
                    .background(Color.primary.opacity(0.04))
                    .cornerRadius(12)
                    
                    // RAM
                    StatCard(
                        title: Localization.ramUsage,
                        icon: "memorychip",
                        usage: monitor.ramUsage,
                        usedStr: String(format: "%.1f GB", monitor.ramUsedGB),
                        totalStr: String(format: "%.1f GB", monitor.ramTotalGB),
                        color: .blue
                    )
                    
                    // CPU
                    StatCard(
                        title: Localization.cpuUsage,
                        icon: "cpu",
                        usage: monitor.cpuUsage,
                        usedStr: String(format: "%.1f%%", monitor.cpuUsage * 100),
                        totalStr: "100%",
                        color: monitor.cpuUsage > 0.8 ? .red : (monitor.cpuUsage > 0.5 ? .orange : .green)
                    )
                    
                    // Disk
                    StatCard(
                        title: Localization.diskUsage,
                        icon: "internaldrive",
                        usage: monitor.diskUsage,
                        usedStr: String(format: "%.1f GB", monitor.diskUsedGB),
                        totalStr: String(format: "%.1f GB", monitor.diskTotalGB),
                        color: .purple
                    )
                }
                .padding(16)
            }
        }
        .onAppear {
            monitor.start()
        }
        .onDisappear {
            monitor.stop()
        }
    }
}

struct StatCard: View {
    let title: String
    let icon: String
    let usage: Double
    let usedStr: String
    let totalStr: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Text("\(usedStr) / \(totalStr)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.05))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: max(0, min(geo.size.width * CGFloat(usage), geo.size.width)), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(12)
    }
}
