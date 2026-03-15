import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case spanish = "es"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return Localization.at("Select Language", "Seleccionar Idioma")
        case .english: return "English"
        case .spanish: return "Español"
        }
    }
}

class Localization {
    static var currentLanguage: AppLanguage {
        BuddySettings.shared.appLanguage
    }
    
    static var resolvedLanguage: String {
        if currentLanguage == .system {
            let locale = Locale.current.language.languageCode?.identifier ?? "en"
            return locale == "es" ? "es" : "en"
        }
        return currentLanguage.rawValue
    }
    
    static func at(_ en: String, _ es: String) -> String {
        return resolvedLanguage == "es" ? es : en
    }
    
    // MARK: - Strings Cabinet
    
    static var appName: String { at("FocusBuddy", "FocusBuddy") }
    
    // MenuBar
    static var today: String { at("Today", "Hoy") }
    static var readyToWork: String { at("Ready to work", "Listo para trabajar") }
    static var activeFocus: String { at("Active Focus", "Enfoque activo") }
    static var breakTime: String { at("Break time", "Tiempo de descanso") }
    static var robotWaiting: String { at("Blinky is waiting for you", "Blinky está esperando por ti") }
    static var newSession: String { at("New Session", "Nueva Sesión") }
    static var whatIsYourGoal: String { at("What is your goal?", "¿Cuál es tu objetivo?") }
    static var start: String { at("Start", "Comenzar") }
    static var pauseLabel: String { at("Pause", "Pausar") }
    static var continueLabel: String { at("Continue", "Continuar") }
    static var endCycle: String { at("End Cycle", "Terminar Ciclo") }
    static var finishSession: String { at("Finish session", "Finalizar sesión") }
    static var skipBreak: String { at("Skip break", "Omitir descanso") }
    static var sessionOf: String { at("Session", "Sesión") } // Use with "X of Y"
    static var of: String { at("of", "de") }
    static var showBuddy: String { at("Show Buddy", "Mostrar Buddy") }
    static var lightingEffect: String { at("Lighting Effect", "Efecto de Iluminación") }
    
    // Alerts
    static var quitTitle: String { at("Are you sure you want to quit?", "¿Estás seguro que deseas salir?") }
    static var quitButton: String { at("Quit FocusBuddy", "Salir de FocusBuddy") }
    static var cancelButton: String { at("Cancel", "Cancelar") }
    static var quitMessage: String { at("The progress of the current session will be lost.", "Se perderá el progreso de la sesión actual.") }
    
    static var endCycleTitle: String { at("End full cycle?", "¿Terminar ciclo completo?") }
    static var endCycleButton: String { at("Yes, end all", "Sí, terminar todo") }
    static var endCycleMessage: String { at("Your progress for today will be cleared and settings reset.", "Se borrará el progreso de hoy y volverás a la configuración inicial.") }
    
    static var finishSessionTitle: String { at("Finish focus session?", "¿Finalizar sesión de enfoque?") }
    static var finishSessionButton: String { at("Yes, finish session", "Sí, finalizar sesión") }
    static var finishSessionMessage: String { at("You will advance to the next break.", "Avanzarás al siguiente descanso.") }
    
    // Tooltips
    static var quitHelp: String { at("Quit ⌘Q", "Salir ⌘Q") }
    
    // Phases
    static var phaseReady: String { at("Ready", "Listo") }
    static var phaseFocus: String { at("Focus", "Enfoque") }
    static var phaseShortBreak: String { at("Short break", "Descanso corto") }
    static var phaseLongBreak: String { at("Long break", "Descanso largo") }
    
    // Stats
    static var achievements: String { at("Achievements", "Mis Logros") }
    static var statToday: String { at("Today", "Hoy") }
    static var statTotal: String { at("Total", "Total") }
    static var statStreak: String { at("Streak", "Racha") }
    static var recentHistory: String { at("RECENT HISTORY", "HISTORIAL RECIENTE") }
    static var noSessions: String { at("No sessions recorded yet.\nStart your first pomodoro!", "Aún no hay sesiones registradas.\n¡Empieza tu primer pomodoro!") }
    static var unnamedSession: String { at("Unnamed Session", "Sesión sin nombre") }
    
    // Settings
    static var settingsTimer: String { at("Timer", "Temporizador") }
    static var settingsGeneral: String { at("General", "General") }
    static var settingsCycles: String { at("Cycles", "Ciclos") }
    static var launchAtLogin: String { at("Launch at login", "Abrir al iniciar sesión") }
    static var autoDND: String { at("Automatic Do Not Disturb", "No Molestar automático") }
    static var sessionsBeforeLongBreak: String { at("Sessions before long break", "Sesiones antes del descanso largo") }
    static var settingsLanguage: String { at("Language", "Idioma") }
    
    // Pet Moods
    static var moodIdle: String { at("Ready to work", "Listo para trabajar") }
    static var moodFocused: String { at("Focused...", "Concentrado...") }
    static var moodRelaxing: String { at("Taking a break", "Tomando un respiro") }
    static var moodCelebrating: String { at("Great session!", "¡Gran sesión!") }
    
    // Notifications
    static var notifSessionCompeleted: String { at("Session completed! 🎉", "¡Sesión completada! 🎉") }
    static var notifStartingBreak: String { at("Starting automatic break.", "Iniciando descanso automático.") }
    static var notifBreakEnded: String { at("Break ended ⏱️", "Descanso terminado ⏱️") }
    static var notifClickStart: String { at("Click 'Start' to focus again.", "Haz click en 'Iniciar' para volver a enfocarte.") }
    
    // Buddy Reminders
    static var reminderDeepBreath: String { at("Take a deep breath 🌬️", "Respira profundo 🌬️") }
    static var reminderStretchBack: String { at("Stretch your back 🧘", "Estira la espalda 🧘") }
    static var reminderDrinkWater: String { at("Drink some water 💧", "Bebe agua 💧") }
    static var reminderLookAway: String { at("Look away for bit 👁️", "Mira a lo lejos 👁️") }
    static var reminderTeaCoffee: String { at("Tea or coffee? ☕️", "Té o café? ☕️") }
    static var reminderShouldersRelaxed: String { at("Shoulders relaxed 🧘", "Hombros relajados 🧘") }
    static var reminderKeepItUp: String { at("Keep it up 🚀", "Mantén el ritmo 🚀") }
    static var reminderStayHydrated: String { at("Stay hydrated 💧", "Un sorbo de agua 💧") }
    static var reminderZeroDistractions: String { at("Zero distractions 🤫", "Cero distracciones 🤫") }
    static var reminderReadyFocus: String { at("Ready to focus? 🤖", "¿Listo para enfocarte? 🤖") }
    static var buddyAccessibilityLabel: String { at("Blinky, your focus companion", "Blinky, tu compañero de enfoque") }
    static func buddyAccessibilityValue(phase: String, time: String) -> String {
        return at("\(phase), \(time) remaining", "\(phase), \(time) restantes")
    }
    
    // Onboarding
    static var obTitle1: String { at("FocusBuddy Pro", "FocusBuddy Pro") }
    static var obDesc1: String { at("Your minimalist productivity companion. Designed to live on your desktop without distracting.", "Tu compañero de productividad minimalista. Diseñado para vivir en tu escritorio sin distraer.") }
    
    static var obTitle2: String { at("Focus with Pomodoro", "Enfócate con Pomodoro") }
    static var obDesc2: String { at("Work in blocks of 25 minutes. The Buddy reacts subtly to your progress.", "Trabaja en bloques de 25 minutos. El Buddy reacciona sutilmente a tu progreso.") }
    
    static var obTitle3: String { at("Total Control", "Control Total") }
    static var obDesc3: String { at("Hide the Buddy when you need space or move it freely using the top handle.", "Oculta el Buddy cuando necesites espacio o muévelo libremente usando el tirador superior.") }
    
    static var obTitle4: String { at("Privacy First", "Privacidad Primero") }
    static var obDesc4: String { at("No keyboard or mouse monitoring. FocusBuddy only depends on your timer.", "Sin monitoreo de teclado ni mouse. FocusBuddy solo depende de tu temporizador.") }
    
    static var next: String { at("Next", "Siguiente") }
    static var getStarted: String { at("Get Started!", "¡Empezar!") }
}
