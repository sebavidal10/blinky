//
//  InsomniaManager.swift
//  Blinky
//
//  Created by Sebastián Vidal Aedo on 14-03-26.
//

import Foundation
import IOKit.pwr_mgt

class InsomniaManager {
    static let shared = InsomniaManager()
    
    private var assertionID: IOPMAssertionID = 0
    private var isActive: Bool = false
    
    private init() {}
    
    func updateState(enabled: Bool) {
        if enabled {
            enable()
        } else {
            disable()
        }
    }
    
    private func enable() {
        guard !isActive else { return }
        
        let reason = "Blinky Insomnia Mode" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        
        if result == kIOReturnSuccess {
            isActive = true
        }
    }
    
    private func disable() {
        guard isActive else { return }
        
        let result = IOPMAssertionRelease(assertionID)
        if result == kIOReturnSuccess {
            isActive = false
            assertionID = 0
        }
    }
}
