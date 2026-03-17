//
//  BlinkyApp.swift
//
//  Created by Sebastián Vidal Aedo on 13-03-26.
//

import SwiftUI

@main
struct BlinkyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No main window — lives only in menu bar
        Settings {
            SettingsView()
                .environmentObject(SessionManager.shared)
        }
    }
}
