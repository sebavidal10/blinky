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
    case idle, focused, tired, celebrating, sleeping, typing, distracted, exhausted

    var emoji: String {
        switch self {
        case .idle:        return "🐱"
        case .focused:     return "😤"
        case .tired:       return "😩"
        case .celebrating: return "🎉"
        case .sleeping:    return "😴"
        case .typing:      return "🤓"
        case .distracted:  return "🧐"
        case .exhausted:   return "🫠"
        }
    }

    var label: String {
        switch self {
        case .idle:        return "Listo para trabajar"
        case .focused:     return "Concentrado..."
        case .tired:       return "Necesitas descanso"
        case .celebrating: return "¡Excelente trabajo!"
        case .sleeping:    return "Zzz..."
        case .typing:      return "¡A tope! 🤓"
        case .distracted:  return "¿Sigues ahí? 🧐"
        case .exhausted:   return "¡Qué esfuerzo! 🫠"
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
    private var activityTimer: AnyCancellable?
    private var lastActivityTime: Date = Date()
    private var keypressHistory: [Date] = []
    private var typingStartTime: Date? = nil

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
        evaluateIntensity()
        startTicking()
        startActivityTracking()
        UserDefaults.standard.set(Date(), forKey: "lastActiveDate")
    }

    func pause() {
        isRunning = false
        timer?.cancel()
        mood = .idle
        evaluateIntensity()
    }

    func reset() {
        isRunning = false
        timer?.cancel()
        phase = .idle
        secondsRemaining = workDuration
        mood = .idle
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
            evaluateIntensity()
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
            
            // Award XP and Coins
            let baseXP = 25
            let baseCoins = 10
            let intensityBonusMultiplier = mood == .typing ? 1.5 : 1.0
            
            BuddySettings.shared.addXP(Int(Double(baseXP) * intensityBonusMultiplier))
            BuddySettings.shared.addCoins(Int(Double(baseCoins) * intensityBonusMultiplier))

            mood = .celebrating
            sendNotification(title: "¡Sesión completada! 🎉", body: "Tómate un descanso, lo mereces.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.evaluateIntensity()
            }

        case .breakTime, .longBreak:
            phase = .working
            secondsRemaining = workDuration
            mood = .focused
            sendNotification(title: "A trabajar 😤", body: "El descanso terminó. ¡Vamos!")

        case .idle:
            break
        }
        if isRunning { startTicking() }
    }

    private func startActivityTracking() {
        activityTimer = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.evaluateIntensity()
            }
    }

    private func evaluateIntensity() {
        let now = Date()
        let idleTime = now.timeIntervalSince(lastActivityTime)
        
        // 1. Sleeping: > 10 min inactividad total
        if idleTime > 600 {
            mood = .sleeping
            typingStartTime = nil
            return
        }

        switch phase {
        case .working:
            guard isRunning else {
                mood = .idle
                typingStartTime = nil
                return
            }

            // Limpiar historial de teclas (ventana de 30s)
            keypressHistory = keypressHistory.filter { now.timeIntervalSince($0) < 30 }
            
            // 2. Typing: constante (> 10 pulsaciones en 30s)
            if keypressHistory.count > 10 {
                if typingStartTime == nil { typingStartTime = now }
                
                // 3. Exhausted: typing por > 15 min
                if let start = typingStartTime, now.timeIntervalSince(start) > 900 {
                    mood = .exhausted
                } else {
                    mood = .typing
                }
            } else {
                typingStartTime = nil
                
                // 4. Distracted: working + 3 min sin tecleo
                if idleTime > 180 {
                    mood = .distracted
                } else {
                    // Cansancio base si ha pasado mucho tiempo
                    let elapsed = workDuration - secondsRemaining
                    if elapsed > workDuration / 2 {
                        mood = .tired
                    } else {
                        mood = .focused
                    }
                }
            }

        case .breakTime, .longBreak:
            mood = .celebrating
            typingStartTime = nil

        case .idle:
            if idleTime > 300 {
                mood = .sleeping
            } else {
                mood = .idle
            }
            typingStartTime = nil
        }
    }

    func registerActivity() {
        lastActivityTime = Date()
        keypressHistory.append(Date())
        
        // Notificar vibración inmediata si estamos en modo typing
        if mood == .typing {
            NotificationCenter.default.post(name: NSNotification.Name("BuddyDidType"), object: nil)
        }
        
        if mood == .sleeping || mood == .distracted {
            evaluateIntensity()
        }
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            print("Notificaciones: \(granted ? "permitidas" : "denegadas")")
        }
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
