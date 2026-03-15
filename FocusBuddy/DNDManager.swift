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
    
    /// Activa o desactiva el modo "No Molestar" (Focus Mode) en macOS.
    /// - Parameter enabled: true para activar, false para desactivar.
    func setDND(enabled: Bool) {
        let script = """
        tell application "System Events"
            tell process "ControlCenter"
                try
                    set focusItem to (first menu bar item whose (description contains "Focus" or description contains "No Molestar" or description contains "Do Not Disturb" or value of attribute "AXIdentifier" is "com.apple.controlcenter.focus")) of menu bar 1
                    
                    -- Obtener el estado actual (si es posible)
                    set currentState to value of focusItem
                    -- Nota: En Sonoma, el valor suele ser "1" si hay un Focus activo
                    
                    if "\(enabled)" is "true" then
                        if currentState is not "1" and currentState is not 1 then
                            click focusItem
                        end if
                    else
                        if currentState is "1" or currentState is 1 then
                            click focusItem
                        end if
                    end if
                on error err
                    log "DND Error: " & err
                end try
            end tell
        end tell
        """
        executeAppleScript(script)
    }
    
    private func executeAppleScript(_ source: String) {
        if let script = NSAppleScript(source: source) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
            if let err = error {
                print("DND AppleScript Error: \(err)")
            }
        }
    }
}
