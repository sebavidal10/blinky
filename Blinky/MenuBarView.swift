//
//  MenuBarView.swift
//
//  Created by Sebastián Vidal Aedo on 14-03-26.
//

import SwiftUI
import EventKit

struct MenuBarView: View {
    @EnvironmentObject var timer: SessionManager

    @State private var isPreparingSession: Bool = false
    @State private var showingQuitAlert: Bool = false
    @State private var showingSkipAlert: Bool = false
    @State private var showingFinishCycleAlert: Bool = false
    @State private var currentView: AppView = .timer
    @ObservedObject var calendar = CalendarManager.shared
    @ObservedObject var buddySettings = BuddySettings.shared

    enum AppView {
        case timer
        case stats
        case system
        case notes
        case settings
    }

    var body: some View {
        VStack(spacing: 0) {
            // Content Switcher
            switch currentView {
            case .timer:
                timerMainView
            case .stats:
                StatsView()
                    .environmentObject(timer)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .notes:
                NotesView()
                    .environmentObject(timer)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .system:
                SystemStatsView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .settings:
                SettingsView()
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

                TabButton(icon: "calendar", isSelected: currentView == .stats) {
                    currentView = .stats
                }
                
                TabButton(icon: "square.and.pencil", isSelected: currentView == .notes) {
                    currentView = .notes
                }

                TabButton(icon: "memorychip", isSelected: currentView == .system) {
                    currentView = .system
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
        .frame(width: 320, height: 560) 
    }

    // MARK: - Subviews

    private var timerMainView: some View {
        VStack(spacing: 0) {
            // Header
            ViewHeader(titleView: {
                HStack(spacing: 8) {
                    RobotFace(mood: timer.mood, 
                              isRunning: timer.isRunning, 
                              phase: timer.phase,
                              isBlinking: false,
                              isInsomniaActive: buddySettings.isInsomniaEnabled)
                        .scaleEffect(0.35)
                        .frame(width: 30, height: 30)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(timer.phase == .idle ? Localization.readyToWork : timer.mood.label)
                            .font(.system(size: 12, weight: .bold))
                        
                        if timer.phase != .idle {
                            Text(timer.currentGoal.isEmpty ? Localization.unnamedSession : timer.currentGoal)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }, rightContent: {
                EmptyView()
            })



            ZStack {
                VStack(spacing: 0) {
                    // TOP SECTION: Status + Action/Active Session
                    VStack(spacing: 12) {
                        if let event = timer.upcomingMeeting, let countdown = timer.meetingCountdown {
                            // NEXT MEETING COUNTDOWN BANNER
                            VStack(spacing: 8) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.orange.opacity(0.1))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "clock.badge.exclamationmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.orange)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(event.title)
                                            .font(.system(size: 13, weight: .bold))
                                            .lineLimit(1)
                                        Text("\(Localization.at("Starts in", "Comienza en")) \(countdown)")
                                            .font(.system(size: 11))
                                            .foregroundColor(.orange)
                                    }
                                    Spacer()
                                    
                                    Button(action: {
                                        withAnimation {
                                            timer.discardMeeting(event: event)
                                        }
                                    }) {
                                        Text(Localization.at("Discard", "Descartar"))
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.red.opacity(0.8))
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(12)
                                .background(Color.orange.opacity(0.05))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        if timer.phase == .idle && !isPreparingSession {
                            // READY TO WORK - Action Button
                            Button(action: { 
                                timer.sessionDurationLimit = nil
                                timer.currentGoal = ""
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { isPreparingSession = true } 
                            }) {
                                HStack(spacing: 0) {
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(Localization.startWork)
                                            .font(.system(size: 15, weight: .bold))
                                        Text(Localization.infiniteSession)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary.opacity(0.5))
                                }
                                .padding(12)
                                .background(Color.primary.opacity(0.04))
                                .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                        } else if isPreparingSession && timer.phase == .idle {
                            // PREPARING SESSION (Goal Input)
                            VStack(spacing: 12) {
                                TextField(Localization.whatIsYourGoal, text: $timer.currentGoal)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 15, weight: .medium))
                                    .multilineTextAlignment(.leading)
                                    .padding(14)
                                    .background(Color.primary.opacity(0.06))
                                    .cornerRadius(12)
                                
                                HStack(spacing: 12) {
                                    Button(Localization.cancelButton) {
                                        withAnimation { isPreparingSession = false }
                                    }
                                    .buttonStyle(.plain)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(Color.primary.opacity(0.05))
                                    .cornerRadius(10)
                                    
                                    Button(action: { 
                                        isPreparingSession = false
                                        timer.start() 
                                    }) {
                                        Text(Localization.start)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 36)
                                            .background(Color.accentColor)
                                            .cornerRadius(10)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(12)
                            .background(Color.primary.opacity(0.03))
                            .cornerRadius(16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        } else {
                            // ACTIVE SESSION - Subtle Integrated View
                            VStack(alignment: .leading, spacing: 8) {
                                let isMeet = timer.phase == .meeting && timer.meetingHasLink
                                
                                // Line 1: ICON + Name
                                HStack(spacing: 12) {
                                    if timer.phase == .meeting {
                                        ZStack {
                                            Circle()
                                                .fill((isMeet ? Color.teal : Color.secondary).opacity(0.1))
                                                .frame(width: 28, height: 28)
                                            
                                            Image(systemName: isMeet ? "video.fill" : "calendar")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(isMeet ? .teal : .secondary)
                                        }
                                    }
                                    
                                    Text(timer.currentGoal.isEmpty ? Localization.unnamedSession : timer.currentGoal)
                                        .font(.system(size: 14, weight: .bold))
                                        .lineLimit(1)
                                    
                                    Spacer()
                                }
                                
                                // Line 2: Time/Status + Buttons
                                HStack(alignment: .center) {
                                    HStack(spacing: 6) {
                                        Text(timer.timeString)
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(isMeet ? .teal : (timer.phase == .meeting ? .secondary : .blue))
                                        
                                        if !timer.isInfiniteSession && !timer.isMeetingPending {
                                            Text("•")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary.opacity(0.5))
                                            Text(Localization.remainingTime(timer.secondsRemaining / 60))
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.leading, timer.phase == .meeting ? 40 : 0) // Align with text above
                                    
                                    Spacer()
                                    
                                    // Integrated Mini Controls
                                    HStack(spacing: 8) {
                                        Button(action: { 
                                            if timer.isRunning { timer.stop() } else { timer.start() }
                                        }) {
                                            Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.primary)
                                                .frame(width: 26, height: 26)
                                                .background(Color.primary.opacity(0.08))
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Button(action: { timer.finishSession() }) {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(width: 26, height: 26)
                                                .background(Color.green)
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color.primary.opacity(0.04))
                            .cornerRadius(16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.bottom, 20)
                    .zIndex(1)

                    // BOTTOM SECTION: Upcoming Meetings (The ONLY scrollable part)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(Localization.upcomingMeetings)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: { 
                                calendar.refresh()
                            }) {
                                SyncIcon(isFetching: calendar.isFetching)
                            }
                            .buttonStyle(.plain)
                            .disabled(calendar.isFetching)
                        }
                        
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                Color.clear.frame(height: 12)
                                
                                if calendar.todayEvents.isEmpty && calendar.tomorrowEvents.isEmpty {
                                    Text(Localization.noEventsNext2Days)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                        .padding(.vertical, 32)
                                        .frame(maxWidth: .infinity)
                                } else {
                                    VStack(alignment: .leading, spacing: 20) {
                                        // Today
                                        VStack(alignment: .leading, spacing: 12) {
                                            let todayLabelWithDate: String = {
                                                MenuBarView.shortDateFormatter.locale = Locale(identifier: Localization.resolvedLanguage)
                                                let dateStr = MenuBarView.shortDateFormatter.string(from: Date()).capitalized
                                                return "\(Localization.todayLabel), \(dateStr)"
                                            }()
                                            
                                            Text(todayLabelWithDate)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.secondary.opacity(0.5))
                                                .padding(.leading, 2)
                                            
                                            if calendar.todayEvents.isEmpty {
                                                EmptyDayMessage(message: Localization.noEventsToday)
                                            } else {
                                                ForEach(calendar.todayEvents, id: \.self) { event in
                                                    EventRow(event: event, timer: timer)
                                                }
                                            }
                                        }
                                        
                                        // Tomorrow
                                        VStack(alignment: .leading, spacing: 12) {
                                            let tomorrowLabel: String = {
                                                MenuBarView.tomorrowDateFormatter.locale = Locale(identifier: Localization.resolvedLanguage)
                                                let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                                                return MenuBarView.tomorrowDateFormatter.string(from: tomorrowDate).capitalized
                                            }()
                                            
                                            Text(tomorrowLabel)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.secondary.opacity(0.5))
                                                .padding(.leading, 2)
                                            
                                            if calendar.tomorrowEvents.isEmpty {
                                                EmptyDayMessage(message: Localization.noEventsTomorrow)
                                            } else {
                                                ForEach(calendar.tomorrowEvents, id: \.self) { event in
                                                    EventRow(event: event, timer: timer)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.bottom, 16)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
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
        timer.startStop()
    }
    
    // Shared Formatters for Performance
    fileprivate static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f
    }()
    
    fileprivate static let tomorrowDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMM"
        return f
    }()
}

struct EmptyDayMessage: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green.opacity(0.4))
                .font(.system(size: 14))
            
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary.opacity(0.7))
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(10)
        .padding(.leading, 2)
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

struct EventRow: View {
    let event: EKEvent
    @ObservedObject var timer: SessionManager
    @ObservedObject var buddySettings = BuddySettings.shared
    
    private var meetingURL: URL? {
        if let url = event.url { return url }
        if let notes = event.notes {
            let patterns = [
                "https://zoom.us/j/[0-9]+",
                "https://meet.google.com/[a-z0-9-]+",
                "https://teams.microsoft.com/l/meetup-join/[^\\s]+"
            ]
            for pattern in patterns {
                if let range = notes.range(of: pattern, options: .regularExpression) {
                    return URL(string: String(notes[range]))
                }
            }
        }
        return nil
    }

    private var isMeeting: Bool {
        meetingURL != nil
    }

    var body: some View {
        Button(action: {
            if let url = meetingURL {
                openMeetingLink(url)
            }
            
            timer.start(goal: event.title ?? "", 
                        startDate: event.startDate, 
                        endDate: event.endDate, 
                        hasLink: isMeeting,
                        eventID: event.eventIdentifier)
        }) {
            HStack(spacing: 12) {
                Image(systemName: isMeeting ? "video.fill" : "calendar")
                    .font(.system(size: 14))
                    .foregroundColor(isMeeting ? .teal : .secondary)
                    .frame(width: 20)
                
                Text(EventRow.formatter.string(from: event.startDate))
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 45, alignment: .leading)
                
                Text(event.title ?? Localization.unnamedSession)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func openMeetingLink(_ url: URL) {
        let browserName = buddySettings.preferredBrowser
        if browserName == "System Default" {
            NSWorkspace.shared.open(url)
            return
        }
        
        let bundleID: String
        switch browserName {
        case "Safari": bundleID = "com.apple.Safari"
        case "Google Chrome": bundleID = "com.google.Chrome"
        case "Firefox": bundleID = "org.mozilla.firefox"
        case "Arc": bundleID = "company.thebrowser.Browser"
        default:
            NSWorkspace.shared.open(url)
            return
        }
        
        if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.open([url], withApplicationAt: appUrl, configuration: config) { _, _ in }
        } else {
            NSWorkspace.shared.open(url)
        }
    }
    
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
}

struct ViewHeader<Content: View>: View {
    let title: String
    let titleView: AnyView?
    let rightContent: () -> Content
    
    init(title: String, @ViewBuilder rightContent: @escaping () -> Content) {
        self.title = title
        self.titleView = nil
        self.rightContent = rightContent
    }
    
    init<V: View>(@ViewBuilder titleView: @escaping () -> V, @ViewBuilder rightContent: @escaping () -> Content) {
        self.title = ""
        self.titleView = AnyView(titleView())
        self.rightContent = rightContent
    }
    
    init(title: String) where Content == EmptyView {
        self.title = title
        self.titleView = nil
        self.rightContent = { EmptyView() }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let titleView = titleView {
                    titleView
                } else {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                }
                Spacer()
                rightContent()
            }
            .frame(height: 32)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
        }
    }
}
