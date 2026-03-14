//
//  AppDelegate.swift
//
//  Created by Sebastián Vidal Aedo on 13-03-26.
//

import AppKit
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var petWindow: NSWindow?
    var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // No Dock icon
        
        // Pedir permiso de notificaciones
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        setupMenuBarItem()
        setupPetWindow()
    }

    // MARK: - Menu Bar

    func setupMenuBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            let icon = NSImage(named: "MenuBarIcon")
            icon?.isTemplate = true
            button.image = icon
            button.action = #selector(togglePopover)
            button.target = self
        }

        setupPopover()
    }

    func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 280, height: 320)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(PomodoroTimer.shared)
        )
    }

    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }

        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    // MARK: - Floating Pet Window

    func setupPetWindow() {
        let screen = NSScreen.main?.visibleFrame ?? .zero
        let windowSize = CGSize(width: 130, height: 170)
        let origin = CGPoint(
            x: screen.maxX - windowSize.width - 20,
            y: screen.minY + 20
        )

        petWindow = NSWindow(
            contentRect: NSRect(origin: origin, size: windowSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        petWindow?.isOpaque = false
        petWindow?.backgroundColor = .clear
        petWindow?.level = .floating
        petWindow?.collectionBehavior = [.canJoinAllSpaces, .stationary]
        petWindow?.ignoresMouseEvents = false
        petWindow?.contentView = NSHostingView(
            rootView: BuddyView()
                .environmentObject(PomodoroTimer.shared)
        )
        petWindow?.makeKeyAndOrderFront(nil)
    }
}
