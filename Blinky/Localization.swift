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
            let locale = Locale.current.language.languageCode?.identifier ?? "es"
            return locale == "en" ? "en" : "es"
        }
        return currentLanguage.rawValue
    }
    
    static func at(_ en: String, _ es: String) -> String {
        return resolvedLanguage == "es" ? es : en
    }
    
    static var unnamedSession: String { at("Unnamed Session", "Sesión sin nombre") }
    static var aboutTitle: String { at("About Blinky", "Acerca de Blinky") }
    static var aboutVersion: String { 
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.3"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "11"
        return at("Version \(v) (\(b))", "Versión \(v) (\(b))")
    }
    static var aboutCopyright: String { 
        let year = Calendar.current.component(.year, from: Date())
        return at("© \(year) Sebastián Vidal", "© \(year) Sebastián Vidal") 
    }
    static var aboutHelp: String { at("Technical Information", "Información técnica") }
    
    static var startWork: String { at("Start Working", "Iniciar trabajo") }
    static var infiniteSession: String { at("Open session (Stopwatch)", "Sesión abierta (Cronómetro)") }
    static var upcomingMeetings: String { at("Upcoming meetings", "Próximas reuniones") }
    
    static var appName: String { at("Blinky", "Blinky") }
    
    // MenuBar
    static var today: String { at("Today", "Hoy") }
    static var readyToWork: String { at("Ready to work", "Listo para trabajar") }
    static var activeFocus: String { at("Active Focus", "Enfoque activo") }
    static var breakTime: String { at("Break time", "Tiempo de descanso") }
    static var robotWaiting: String { at("Blinky is waiting for you", "Blinky está esperando por ti") }
    static var newSession: String { at("New Session", "Nueva Sesión") }
    static var whatIsYourGoal: String { at("What is your goal?", "¿Cuál es tu objetivo?") }
    static var start: String { at("Start", "Comenzar") }
    static var pauseLabel: String { at("Pause", "Pausa") }
    static var continueLabel: String { at("Continue", "Continuar") }
    static var endCycle: String { at("End Cycle", "Terminar Ciclo") }
    static var finishSession: String { at("Finish session", "Finalizar sesión") }
    static var skipBreak: String { at("Skip break", "Omitir descanso") }
    static var sessionOf: String { at("Session", "Sesión") } // Use with "X of Y"
    static var of: String { at("of", "de") }
    static var showBuddy: String { at("Show Buddy", "Mostrar Buddy") }
    static var lightingEffect: String { at("Lighting Effect", "Efecto de Iluminación") }
    static var insomniaMode: String { at("Insomnia Mode", "Modo Insomnio") }
    static var insomniaDescription: String { at("Keep computer awake", "Mantener equipo despierto") }
    
    // Alerts
    static var quitTitle: String { at("Are you sure you want to quit?", "¿Estás seguro que deseas salir?") }
    static var quitButton: String { at("Quit Blinky", "Salir de Blinky") }
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
    static var achievements: String { at("History", "Historial") }
    static var statToday: String { at("Today", "Hoy") }
    static var statTotal: String { at("Total", "Total") }
    static var recentHistory: String { at("SESSIONS", "SESIONES") }
    static var noSessions: String { at("No sessions recorded yet.\nStart your first session!", "Aún no hay sesiones registradas.\n¡Empieza tu primera sesión!") }
    
    // Settings
    static var settingsTimer: String { at("Timer", "Temporizador") }
    static var settingsGeneral: String { at("General", "General") }
    static var settingsAppearance: String { at("Appearance", "Apariencia") }
    static var settingsCycles: String { at("Cycles", "Ciclos") }
    static var launchAtLogin: String { at("Launch at login", "Abrir al iniciar sesión") }
    static var sessionsBeforeLongBreak: String { at("Sessions before long break", "Sesiones antes del descanso largo") }
    static var settingsLanguage: String { at("Language", "Idioma") }
    static var settingsCalendars: String { at("Calendars", "Calendarios") }
    static var readCalendars: String { at("Read meetings from:", "Leer reuniones de:") }
    static var grantAccess: String { at("Grant Calendar Access", "Permitir acceso al Calendario") }
    static var openSystemSettings: String { at("Open System Settings", "Abrir Ajustes del Sistema") }
    static var calendarAccessDenied: String { at("Blinky needs calendar access to show your meetings.", "Blinky necesita acceso al calendario para mostrar tus reuniones.") }
    static var defaultBrowser: String { at("Default Browser", "Navegador predeterminado") }
    static var selectBrowser: String { at("Open links with:", "Abrir enlaces con:") }
    static var syncNow: String { at("Sync Now", "Sincronizar ahora") }
    static var noEventsToday: String { at("All set for today! 🚀", "¡Todo listo por hoy! 🚀") }
    static var noEventsTomorrow: String { at("No events scheduled", "Sin eventos agendados") }
    static var noEventsNext2Days: String { at("No events for today or tomorrow. Free days! ⚡️", "Sin eventos hoy ni mañana. ¡Días libres! ⚡️") }
    static var todayLabel: String { at("Today", "Hoy") }
    static var tomorrowLabel: String { at("Tomorrow", "Mañana") }
    static var settingsGeneralAppearance: String { at("General & Appearance", "General y Apariencia") }
    static var settings: String { at("Settings", "Configuración") }
    static var generalStartup: String { at("General & Startup", "General e Inicio") }
    static var buddyConfiguration: String { at("Buddy Configuration", "Configuración de Buddy") }
    
    static var countdownThreshold: String { at("Countdown", "Cuenta regresiva") }
    static var minutesBefore: String { at("minutes before", "minutos antes") }

    // System Stats
    static var systemStats: String { at("System Health", "Salud del Sistema") }
    static var ramUsage: String { at("Memory (RAM)", "Memoria (RAM)") }
    static var cpuUsage: String { at("Processor (CPU)", "Procesador (CPU)") }
    static var diskUsage: String { at("Storage (Disk)", "Almacenamiento") }
    static var uptime: String { at("Uptime", "Tiempo de actividad") }

    static func remainingTime(_ minutes: Int) -> String {
        return at("\(minutes) min remaining", "\(minutes) min restantes")
    }
    
    // Pet Moods
    static var moodIdle: String { at("Ready to work", "Listo para trabajar") }
    static var moodFocused: String { at("Focused...", "Concentrado...") }
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
    static var obTitle1: String { at("Blinky Pro", "Blinky Pro") }
    static var obDesc1: String { at("Your minimalist productivity companion. Designed to live on your desktop without distracting.", "Tu compañero de productividad minimalista. Diseñado para vivir en tu escritorio sin distraer.") }
    
    static var obTitle2: String { at("Focus with Blinky", "Enfócate con Blinky") }
    static var obDesc2: String { at("Track your work sessions with a stopwatch or sync with your calendar for meetings.", "Rastrea tus sesiones de trabajo con un cronómetro o sincroniza con tu calendario para reuniones.") }
    
    static var obTitle3: String { at("Total Control", "Control Total") }
    static var obDesc3: String { at("Hide the Buddy when you need space or move it freely using the top handle.", "Oculta el Buddy cuando necesites espacio o muévelo libremente usando el tirador superior.") }
    
    static var obTitle4: String { at("Privacy First", "Privacidad Primero") }
    static var obDesc4: String { at("Blinky only depends on your sessions. No tracking, no data sent, just deep focus.", "Blinky solo depende de tus sesiones. Sin rastreo, sin datos enviados, solo enfoque profundo.") }
    
    static var next: String { at("Next", "Siguiente") }
    static var getStarted: String { at("Get Started!", "¡Empezar!") }
    
    // Quick Notes
    static var notesTitle: String { at("Quick Notes", "Notas Rápidas") }
    static var noNotes: String { at("No notes yet.\nJot down your thoughts!", "Aún no hay notas.\n¡Escribe tus pensamientos!") }
    static var typeSomething: String { at("Type something...", "Escribe algo...") }
    static var quickNoteShortcut: String { at("New Note", "Nueva Nota") }
    static var nextEvent: String { at("Next Event", "Próximo") }
    
    // Smart Reminders
    static var reminderTooManyMeetings: String { at("Many meetings today! Focus time? ⚡️", "¡Muchas reuniones! ¿Hora de enfocar? ⚡️") }
    static func reminderGreatProgress(_ mins: Int) -> String {
        return at("Great progress! \(mins)m focused 🚀", "¡Gran progreso! \(mins)m de enfoque 🚀")
    }
    
    static var showNextEvent: String { at("Show Next Event in Menu Bar", "Mostrar próximo evento en barra") }
}
