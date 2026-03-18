//
//  SessionManager.swift
//
//  Created by Sebastián Vidal Aedo on 14-03-26.
//

import Foundation
import Combine
import AppKit
import UserNotifications
import EventKit

enum TimerPhase {
    case idle, working, meeting
}

enum PetMood {
    case idle, focused, celebrating

    var label: String {
        switch self {
        case .idle:        return Localization.moodIdle
        case .focused:     return Localization.moodFocused
        case .celebrating: return Localization.moodCelebrating
        }
    }
}

struct FocusSession: Codable, Identifiable {
    let id: UUID
    let date: Date
    let goal: String
    let durationInMinutes: Int
}

class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published var currentGoal: String = "" {
        didSet { UserDefaults.standard.set(currentGoal, forKey: "currentGoal") }
    }
    
    @Published var isInfiniteSession: Bool = true
    @Published var sessionDurationLimit: Int? = nil // Only for meetings
    @Published var meetingStartDate: Date? = nil
    @Published var meetingEndDate: Date? = nil
    @Published var meetingHasLink: Bool = false
    @Published var meetingCountdown: String? = nil
    @Published var upcomingMeeting: EKEvent? = nil
    @Published var discardedMeetingIDs: Set<String> = []

    // MARK: - State
    @Published var phase: TimerPhase = .idle
    @Published var mood: PetMood = .idle
    @Published var secondsRemaining: Int = 0
    @Published var secondsElapsed: Int = 0
    @Published var isRunning: Bool = false

    // MARK: - Stats (persisted)
    @Published var totalSessionsToday: Int = 0 {
        didSet { UserDefaults.standard.set(totalSessionsToday, forKey: "totalSessionsToday") }
    }
    @Published var totalSessionsAllTime: Int = 0 {
        didSet { UserDefaults.standard.set(totalSessionsAllTime, forKey: "totalSessionsAllTime") }
    }
    @Published var currentStreak: Int = 0 {
        didSet { UserDefaults.standard.set(currentStreak, forKey: "currentStreak") }
    }
    @Published var sessionsHistory: [FocusSession] = [] {
        didSet {
            // Background saving to prevent blocking the UI thread
            DispatchQueue.global(qos: .background).async {
                if let encoded = try? JSONEncoder().encode(self.sessionsHistory) {
                    UserDefaults.standard.set(encoded, forKey: "sessionsHistory")
                }
            }
        }
    }

    private var timer: AnyCancellable?

    // MARK: - Init

    private init() {
        if let savedDiscarded = UserDefaults.standard.stringArray(forKey: "discardedMeetingIDs") {
            discardedMeetingIDs = Set(savedDiscarded)
        }
        
        loadHistory()
        requestNotificationPermission()
        checkDayReset()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name("BlinkyDataImported"), object: nil)
        startTicking()
    }

    func checkDayReset() {
        let ud = UserDefaults.standard
        let lastDate = ud.object(forKey: "lastActiveDate") as? Date ?? Date.distantPast
        let calendar = Calendar.current
        
        if !calendar.isDateInToday(lastDate) {
            // New day detected
            if totalSessionsToday > 0 {
                // If we worked yesterday, increment streak
                currentStreak += 1
            } else if lastDate != Date.distantPast && !calendar.isDateInYesterday(lastDate) {
                // If we missed more than one day, reset streak
                currentStreak = 0
            }
            
            totalSessionsToday = 0
            discardedMeetingIDs.removeAll()
            UserDefaults.standard.removeObject(forKey: "discardedMeetingIDs")
            
            ud.set(Date(), forKey: "lastActiveDate")
        }
    }

    // MARK: - Computed

    var isMeetingPending: Bool {
        guard phase == .meeting, let start = meetingStartDate else { return false }
        return Date() < start
    }

    var timeString: String {
        if isMeetingPending {
            return Localization.at("Pending", "Pendiente")
        }
        // Meetings show elapsed time, Working sessions show remaining (if not infinite)
        let totalSeconds = (phase == .meeting || isInfiniteSession) ? secondsElapsed : secondsRemaining
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var currentSessionIcon: String? {
        switch phase {
        case .meeting:
            return meetingHasLink ? "video" : "calendar"
        case .working:
            return isInfiniteSession ? "bolt" : "calendar"
        case .idle:
            return nil
        }
    }

    var progress: Double {
        guard let limit = sessionDurationLimit, limit > 0 else { return 0 }
        return Double(secondsElapsed) / Double(limit)
    }

    // MARK: - Controls

    func startStop() {
        if isRunning {
            stop()
        } else {
            start()
        }
    }
    
    @objc func reloadData() {
        loadHistory()
        // If there was an active session, it might be messy to reload it mid-way.
    }

    func start(goal: String? = nil, startDate: Date? = nil, endDate: Date? = nil, hasLink: Bool = false) {
        if let goal = goal {
            self.currentGoal = goal
        }

        if phase == .idle {
            if let start = startDate, let end = endDate {
                // Real-time meeting
                self.meetingStartDate = start
                self.meetingEndDate = end
                self.meetingHasLink = hasLink
                self.isInfiniteSession = false
                self.phase = .meeting
                
                let now = Date()
                let totalDuration = Int(end.timeIntervalSince(start))
                self.sessionDurationLimit = totalDuration
                self.secondsElapsed = Int(now.timeIntervalSince(start))
                self.secondsRemaining = Int(end.timeIntervalSince(now))
            } else {
                // Working session
                phase = .working
                secondsElapsed = 0
                if let limit = sessionDurationLimit {
                    isInfiniteSession = false
                    secondsRemaining = limit
                } else {
                    isInfiniteSession = true
                    secondsRemaining = 0
                }
            }
        }
        isRunning = true
        
        updateMood()
        lastTickDate = Date()
        UserDefaults.standard.set(lastTickDate, forKey: "lastActiveDate")
    }

    func stop() {
        isRunning = false
        updateMood()
    }

    func reset() {
        stop()
        phase = .idle
        secondsRemaining = 0
        secondsElapsed = 0
        updateMood()
    }

    func finishSession() {
        let duration = isInfiniteSession ? secondsElapsed : (sessionDurationLimit ?? secondsElapsed)
        let session = FocusSession(
            id: UUID(),
            date: Date(),
            goal: currentGoal.isEmpty ? Localization.unnamedSession : currentGoal,
            durationInMinutes: max(1, duration / 60)
        )
        
        sessionsHistory.append(session)
        totalSessionsToday += 1
        totalSessionsAllTime += 1
        
        reset()
        
        // Celebration mood after reset
        mood = .celebrating
        
        // Back to idle after a while
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            if self?.phase == .idle {
                self?.mood = .idle
            }
        }
    }

    func discardMeeting(event: EKEvent) {
        let session = FocusSession(
            id: UUID(),
            date: Date(),
            goal: "\(event.title ?? Localization.unnamedSession) (\(Localization.at("Discarded", "Descartada")))",
            durationInMinutes: 0
        )
        sessionsHistory.append(session)
        
        discardedMeetingIDs.insert(event.eventIdentifier)
        UserDefaults.standard.set(Array(discardedMeetingIDs), forKey: "discardedMeetingIDs")
        
        if upcomingMeeting?.eventIdentifier == event.eventIdentifier {
            upcomingMeeting = nil
            meetingCountdown = nil
        }
    }

    func deleteSession(id: UUID) {
        guard let index = sessionsHistory.firstIndex(where: { $0.id == id }) else { return }
        let session = sessionsHistory[index]
        if Calendar.current.isDateInToday(session.date) {
            totalSessionsToday = max(0, totalSessionsToday - 1)
        }
        totalSessionsAllTime = max(0, totalSessionsAllTime - 1)
        sessionsHistory.remove(at: index)
    }

    // MARK: - Internal

    private var lastTickDate: Date?

    private func startTicking() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        let now = Date()
        
        // Always check for upcoming meetings, even if idle
        checkUpcomingMeetings()
        
        // Periodically check for day reset (at the top of the minute)
        if Calendar.current.component(.second, from: now) == 0 {
            checkDayReset()
        }
        
        guard isRunning else { return }
        
        let elapsed = Int(now.timeIntervalSince(lastTickDate ?? now))
        lastTickDate = now
        
        // Handle potential background sleep by jumping seconds if needed
        let decrement = max(1, elapsed)
        
        secondsElapsed += decrement
        
        if !isInfiniteSession {
            if let start = meetingStartDate, let end = meetingEndDate {
                // Keep in sync with actual wall clock for meetings
                let nowSecondsElapsed = Int(now.timeIntervalSince(start))
                self.secondsElapsed = max(0, nowSecondsElapsed)
                self.secondsRemaining = Int(max(0, end.timeIntervalSince(now)))
                
                // Update mood based on whether meeting has actually started
                updateMood()
            } else {
                secondsRemaining = max(0, secondsRemaining - decrement)
            }

            if secondsRemaining == 0 {
                // Session limit reached
                finishSession()
                sendNotification(title: Localization.notifSessionCompeleted, body: Localization.notifClickStart)
            }
        }
    }

    private func checkUpcomingMeetings() {
        // Only check if we are NOT already in a meeting
        guard phase != .meeting else {
            upcomingMeeting = nil
            meetingCountdown = nil
            return
        }
        
        let now = Date()
        let calendar = CalendarManager.shared
        
        // Find the next meeting starting in the future
        let next = calendar.todayEvents
            .filter { $0.startDate > now && !$0.isAllDay && !discardedMeetingIDs.contains($0.eventIdentifier) }
            .sorted { $0.startDate < $1.startDate }
            .first
        
        if let event = next {
            let diff = event.startDate.timeIntervalSince(now)
            let threshold = Double(BuddySettings.shared.meetingCountdownThreshold * 60)
            if diff > 0 && diff <= threshold { // Configurable threshold
                upcomingMeeting = event
                let minutes = Int(diff) / 60
                let seconds = Int(diff) % 60
                meetingCountdown = String(format: "%02d:%02d", minutes, seconds)
            } else {
                upcomingMeeting = nil
                meetingCountdown = nil
            }
        } else {
            upcomingMeeting = nil
            meetingCountdown = nil
        }
    }

    private func loadHistory() {
        let ud = UserDefaults.standard
        currentGoal = ud.string(forKey: "currentGoal") ?? ""
        totalSessionsToday = ud.integer(forKey: "totalSessionsToday")
        totalSessionsAllTime = ud.integer(forKey: "totalSessionsAllTime")
        currentStreak = ud.integer(forKey: "currentStreak")
        
        if let data = ud.data(forKey: "sessionsHistory"),
           let decoded = try? JSONDecoder().decode([FocusSession].self, from: data) {
            sessionsHistory = decoded
        }
    }

    private func updateMood() {
        // Don't override celebration if it was just set
        if mood == .celebrating && phase == .idle { return }
        
        switch phase {
        case .working, .meeting:
            mood = isRunning ? .focused : .idle
        case .idle:
            mood = .idle
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in }
    }

    func sessionsInLast7Days() -> [(Date, Int)] {
        let calendar = Calendar.current
        var results: [(Date, Int)] = []
        
        for i in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let count = sessionsHistory.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
                results.append((date, count))
            }
        }
        return results
    }

    private func sendNotification(title: String, body: String) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request)
        }
    }
}
