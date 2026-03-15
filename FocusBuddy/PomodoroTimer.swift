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

struct FocusSession: Codable, Identifiable {
    let id: UUID
    let date: Date
    let goal: String
    let durationInMinutes: Int
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
    @Published var currentGoal: String = "" {
        didSet { UserDefaults.standard.set(currentGoal, forKey: "currentGoal") }
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
        currentGoal          = ud.string(forKey: "currentGoal") ?? ""
        if let data = ud.data(forKey: "sessionsHistory"),
           let decoded = try? JSONDecoder().decode([FocusSession].self, from: data) {
            sessionsHistory = decoded
        }
        
        validateDurations()
        secondsRemaining     = workDuration
    }

    private func validateDurations() {
        if workDuration < 60 { workDuration = 60 }
        if shortBreakDuration < 60 { shortBreakDuration = 60 }
        if longBreakDuration < 60 { longBreakDuration = 60 }
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
        
        // Turn on DND if starting work
        if phase == .working && BuddySettings.shared.enableDNDSync {
            DNDManager.shared.setDND(enabled: true)
        }
        
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

    func finishFullCycle() {
        isRunning = false
        timer?.cancel()
        
        // Turn off DND on manual reset
        if BuddySettings.shared.enableDNDSync {
            DNDManager.shared.setDND(enabled: false)
        }
        
        phase = .idle
        completedSessions = 0
        currentGoal = ""
        secondsRemaining = workDuration
        updateMood()
    }

    // MARK: - Internal

    private var lastTickDate: Date?

    private func startTicking() {
        timer?.cancel()
        lastTickDate = Date()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        guard isRunning else { return }
        
        let now = Date()
        let elapsed = Int(now.timeIntervalSince(lastTickDate ?? now))
        lastTickDate = now
        
        // Handle potential background sleep by jumping seconds if needed
        let decrement = max(1, elapsed)
        
        if secondsRemaining > 0 {
            secondsRemaining = max(0, secondsRemaining - decrement)
            if secondsRemaining == 0 {
                advancePhase()
            }
        }
        
        // Periodically check for day reset (e.g., at midnight)
        if secondsRemaining % 60 == 0 {
            checkDayReset()
        }
    }

    private func advancePhase() {
        let previousPhase = phase
        
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
            
            // Turn off DND when break starts
            if BuddySettings.shared.enableDNDSync {
                DNDManager.shared.setDND(enabled: false)
            }
            
            mood = .celebrating
            sendNotification(title: "¡Sesión completada! 🎉", body: "Iniciando descanso automático.")
            
            // Auto-start the break
            isRunning = true
            startTicking()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.updateMood()
            }

        case .breakTime, .longBreak:
            phase = .working
            secondsRemaining = workDuration
            
            // Turn on DND when returning to work from break
            if BuddySettings.shared.enableDNDSync {
                DNDManager.shared.setDND(enabled: true)
            }
            
            isRunning = false // STOP: Wait for user to start next work session
            timer?.cancel()
            updateMood()
            sendNotification(title: "Descanso terminado ⏱️", body: "Haz click en 'Iniciar' para volver a enfocarte.")

        case .idle:
            break
        }
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
        let elapsedSeconds = workDuration - secondsRemaining
        let elapsedMinutes = max(1, elapsedSeconds / 60) // At least 1 min if any work was done
        
        let session = FocusSession(
            id: UUID(),
            date: Date(),
            goal: currentGoal.isEmpty ? "Sesión sin nombre" : currentGoal,
            durationInMinutes: elapsedMinutes
        )
        sessionsHistory.append(session)
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
