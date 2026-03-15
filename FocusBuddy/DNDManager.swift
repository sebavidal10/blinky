//
//  DNDManager.swift
//  FocusBuddy
//
//  Created by Sebastián Vidal Aedo on 14-03-26.
//

import Foundation

class DNDManager {
    static let shared = DNDManager()
    
    private init() {}
    
    /// Activates or deactivates "Do Not Disturb" (Focus Mode) on macOS.
    /// - Parameter enabled: true to activate, false to deactivate.
    func setDND(enabled: Bool) {
        let script = """
        with timeout of 1 second
            tell application "System Events"
                tell process "ControlCenter"
                    try
                        set focusItem to (first menu bar item whose (description contains "Focus" or description contains "No Molestar" or description contains "Do Not Disturb" or value of attribute "AXIdentifier" is "com.apple.controlcenter.focus")) of menu bar 1
                        
                        set currentState to value of focusItem
                        
                        if "\(enabled)" is "true" then
                            if currentState is not "1" and currentState is not 1 then
                                click focusItem
                            end if
                        else
                            if currentState is "1" or currentState is 1 then
                                click focusItem
                            end if
                        end if
                    end try
                end tell
            end tell
        end timeout
        """
        executeAppleScript(script)
    }
    
    private func executeAppleScript(_ source: String) {
        // Use Process instead of NSAppleScript to avoid blocking the main thread
        // This is especially important during application termination
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", source]
        
        let pipe = Pipe()
        task.standardError = pipe
        
        do {
            try task.run()
            // We don't wait for completion to avoid blocking
        } catch {
            print("DND Process Error: \(error)")
        }
    }
}
