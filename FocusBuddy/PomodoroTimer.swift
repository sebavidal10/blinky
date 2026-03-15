//
//  PomodoroTimer.swift
//
//  Created by Sebastián Vidal Aedo on 14-03-26.
//

import Foundation
import Combine
import AppKit
import UserNotifications

enum TimerPhase {
    case idle, working, breakTime, longBreak
}

enum PetMood {
    case idle, focused, relaxing, celebrating

    var label: String {
        switch self {
        case .idle:        return "Listo para trabajar"
        case .focused:     return "Concentrado..."
        case .relaxing:    return "Tomando un respiro"
        case .celebrating: return "¡Gran sesión!"
        }
    }
}

class PomodoroTimer: ObservableObject {
    static let shared = PomodoroTimer()

    // MARK: - Config (persisted)
    @Published var workDuration: Int = 25 * 60 {
        didSet {
            validateDurations()
            UserDefaults.standard.set(workDuration, forKey: "workDuration")
        }
    }
    @Published var shortBreakDuration: Int = 5 * 60 {
        didSet {
            validateDurations()
            UserDefaults.standard.set(shortBreakDuration, forKey: "shortBreakDuration")
        }
    }
    @Published var longBreakDuration: Int = 15 * 60 {
        didSet {
            validateDurations()
            UserDefaults.standard.set(longBreakDuration, forKey: "longBreakDuration")
        }
    }
    @Published var sessionsUntilLongBreak: Int = 4 {
        didSet { UserDefaults.standard.set(sessionsUntilLongBreak, forKey: "sessionsUntilLongBreak") }
    }

    // MARK: - State
    @Published var phase: TimerPhase = .idle
    @Published var mood: PetMood = .idle
    @Published var secondsRemaining: Int = 25 * 60
    @Published var isRunning: Bool = false
    @Published var completedSessions: Int = 0

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
    @Published var sessionHistory: [String: Int] = [:]

    private var timer: AnyCancellable?

    // MARK: - Init

    private init() {
        loadDefaults()
        requestNotificationPermission()
        checkDayReset()
    }

    private func loadDefaults() {
        let ud = UserDefaults.standard
        if ud.integer(forKey: "workDuration") > 0 {
            workDuration = ud.integer(forKey: "workDuration")
        }
        if ud.integer(forKey: "shortBreakDuration") > 0 {
            shortBreakDuration = ud.integer(forKey: "shortBreakDuration")
        }
        if ud.integer(forKey: "longBreakDuration") > 0 {
            longBreakDuration = ud.integer(forKey: "longBreakDuration")
        }
        if ud.integer(forKey: "sessionsUntilLongBreak") > 0 {
            sessionsUntilLongBreak = ud.integer(forKey: "sessionsUntilLongBreak")
        }
        totalSessionsToday   = ud.integer(forKey: "totalSessionsToday")
        totalSessionsAllTime = ud.integer(forKey: "totalSessionsAllTime")
        currentStreak        = ud.integer(forKey: "currentStreak")
        sessionHistory       = ud.dictionary(forKey: "sessionHistory") as? [String: Int] ?? [:]
        
        validateDurations()
        secondsRemaining     = workDuration
    }

    private func validateDurations() {
        if workDuration < 60 { workDuration = 60 }
        if shortBreakDuration < 60 { shortBreakDuration = 60 }
        if longBreakDuration < 60 { longBreakDuration = 60 }
    }

    private func checkDayReset() {
        let ud = UserDefaults.standard
        let lastDate = ud.object(forKey: "lastActiveDate") as? Date ?? Date.distantPast
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastDate) {
            if totalSessionsToday > 0 {
                currentStreak += 1
            } else if !calendar.isDateInYesterday(lastDate) {
                currentStreak = 0
            }
            totalSessionsToday = 0
            ud.set(Date(), forKey: "lastActiveDate")
        }
    }

    // MARK: - Computed

    var progress: Double {
        let total: Double
        switch phase {
        case .working:    total = Double(workDuration)
        case .breakTime:  total = Double(shortBreakDuration)
        case .longBreak:  total = Double(longBreakDuration)
        case .idle:       total = Double(workDuration)
        }
        return 1.0 - (Double(secondsRemaining) / total)
    }

    var timeString: String {
        let m = secondsRemaining / 60
        let s = secondsRemaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    // MARK: - Controls

    func start() {
        guard !isRunning else { return }
        if phase == .idle {
            phase = .working
            secondsRemaining = workDuration
        }
        isRunning = true
        updateMood()
        startTicking()
        UserDefaults.standard.set(Date(), forKey: "lastActiveDate")
    }

    func pause() {
        isRunning = false
        timer?.cancel()
        updateMood()
    }

    func reset() {
        isRunning = false
        timer?.cancel()
        phase = .idle
        secondsRemaining = workDuration
        updateMood()
    }

    func skip() {
        timer?.cancel()
        advancePhase()
    }

    // MARK: - Internal

    private func startTicking() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        guard isRunning else { return }
        if secondsRemaining > 0 {
            secondsRemaining -= 1
        } else {
            advancePhase()
        }
    }

    private func advancePhase() {
        switch phase {
        case .working:
            completedSessions    += 1
            totalSessionsToday   += 1
            totalSessionsAllTime += 1
            updateSessionHistory()
            
            if completedSessions % sessionsUntilLongBreak == 0 {
                phase = .longBreak
                secondsRemaining = longBreakDuration
            } else {
                phase = .breakTime
                secondsRemaining = shortBreakDuration
            }
            
            mood = .celebrating
            sendNotification(title: "¡Sesión completada! 🎉", body: "Tómate un descanso, lo mereces.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.updateMood()
            }

        case .breakTime, .longBreak:
            phase = .working
            secondsRemaining = workDuration
            updateMood()
            sendNotification(title: "A trabajar 😤", body: "El descanso terminó. ¡Vamos!")

        case .idle:
            break
        }
        if isRunning { startTicking() }
    }

    private func updateMood() {
        switch phase {
        case .working:
            mood = isRunning ? .focused : .idle
        case .breakTime, .longBreak:
            mood = .relaxing
        case .idle:
            mood = .idle
        }
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in }
    }

    private func updateSessionHistory() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: Date())
        sessionHistory[key] = (sessionHistory[key] ?? 0) + 1
        UserDefaults.standard.set(sessionHistory, forKey: "sessionHistory")
    }

    func sessionsInLast7Days() -> [(Date, Int)] {
        let calendar = Calendar.current
        var results: [(Date, Int)] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        for i in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let key = formatter.string(from: date)
                results.append((date, sessionHistory[key] ?? 0))
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
