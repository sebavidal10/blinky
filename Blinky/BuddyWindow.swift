//
//  BuddyWindow.swift
//  Blinky
//
//  Created by Sebastián Vidal Aedo on 17-03-17.
//

import AppKit

class BuddyWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}
