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

    @Published var appLanguage: AppLanguage = .system {
        didSet { UserDefaults.standard.set(appLanguage.rawValue, forKey: "appLanguage") }
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
        enableDNDSync = UserDefaults.standard.bool(forKey: "enableDNDSync")
        
        if let langString = UserDefaults.standard.string(forKey: "appLanguage"),
           let lang = AppLanguage(rawValue: langString) {
            appLanguage = lang
        } else {
            appLanguage = .system
        }
        
        // Sync launchAtLogin with system status
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}
