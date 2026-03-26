//
//  BuddySettings.swift
//
//  Created by Sebastián Vidal Aedo on 14-03-26.
//

import Foundation
import Combine
import ServiceManagement

class BuddySettings: ObservableObject {
    static let shared = BuddySettings()

    @Published var buddyOpacity: Double = 1.0 {
        didSet { UserDefaults.standard.set(buddyOpacity, forKey: "buddyOpacity") }
    }

    @Published var isBuddyVisible: Bool = true {
        didSet { UserDefaults.standard.set(isBuddyVisible, forKey: "isBuddyVisible") }
    }

    @Published var showAura: Bool = true {
        didSet { UserDefaults.standard.set(showAura, forKey: "showAura") }
    }

    @Published var appLanguage: AppLanguage = .spanish {
        didSet { UserDefaults.standard.set(appLanguage.rawValue, forKey: "appLanguage") }
    }

    @Published var preferredBrowser: String = "System Default" {
        didSet { UserDefaults.standard.set(preferredBrowser, forKey: "preferredBrowser") }
    }

    @Published var meetingCountdownThreshold: Int = 5 {
        didSet { UserDefaults.standard.set(meetingCountdownThreshold, forKey: "meetingCountdownThreshold") }
    }

    @Published var showNextEventInMenuBar: Bool = true {
        didSet { UserDefaults.standard.set(showNextEventInMenuBar, forKey: "showNextEventInMenuBar") }
    }


    @Published var isInsomniaEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isInsomniaEnabled, forKey: "isInsomniaEnabled")
            InsomniaManager.shared.updateState(enabled: isInsomniaEnabled)
        }
    }

    @Published var launchAtLogin: Bool = false {
        didSet {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update login item: \(error)")
            }
        }
    }

    private init() {
        let savedOpacity = UserDefaults.standard.double(forKey: "buddyOpacity")
        if savedOpacity > 0 { 
            buddyOpacity = savedOpacity 
        } else {
            buddyOpacity = 1.0
        }

        isBuddyVisible = UserDefaults.standard.object(forKey: "isBuddyVisible") as? Bool ?? true
        showAura = UserDefaults.standard.object(forKey: "showAura") as? Bool ?? true
        isInsomniaEnabled = true
        InsomniaManager.shared.updateState(enabled: true)
        
        if let langString = UserDefaults.standard.string(forKey: "appLanguage"),
           let lang = AppLanguage(rawValue: langString) {
            appLanguage = lang
        } else {
            appLanguage = .spanish
        }

        preferredBrowser = UserDefaults.standard.string(forKey: "preferredBrowser") ?? "System Default"
        
        let savedThreshold = UserDefaults.standard.integer(forKey: "meetingCountdownThreshold")
        meetingCountdownThreshold = savedThreshold > 0 ? savedThreshold : 5
        
        showNextEventInMenuBar = UserDefaults.standard.object(forKey: "showNextEventInMenuBar") as? Bool ?? true
        
        // Sync launchAtLogin with system status
        launchAtLogin = SMAppService.mainApp.status == .enabled
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name("BlinkyDataImported"), object: nil)
    }
    
    @objc func reloadData() {
        let savedOpacity = UserDefaults.standard.double(forKey: "buddyOpacity")
        if savedOpacity > 0 { 
            buddyOpacity = savedOpacity 
        }
        
        isBuddyVisible = UserDefaults.standard.object(forKey: "isBuddyVisible") as? Bool ?? true
        showAura = UserDefaults.standard.object(forKey: "showAura") as? Bool ?? true
        isInsomniaEnabled = UserDefaults.standard.object(forKey: "isInsomniaEnabled") as? Bool ?? true
        
        if let langString = UserDefaults.standard.string(forKey: "appLanguage"),
           let lang = AppLanguage(rawValue: langString) {
            appLanguage = lang
        }
        
        preferredBrowser = UserDefaults.standard.string(forKey: "preferredBrowser") ?? "System Default"
        
        let savedThreshold = UserDefaults.standard.integer(forKey: "meetingCountdownThreshold")
        meetingCountdownThreshold = savedThreshold > 0 ? savedThreshold : 5
        
        showNextEventInMenuBar = UserDefaults.standard.object(forKey: "showNextEventInMenuBar") as? Bool ?? true
        
        InsomniaManager.shared.updateState(enabled: isInsomniaEnabled)
    }
}
