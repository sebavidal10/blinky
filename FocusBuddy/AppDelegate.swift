//
//  AppDelegate.swift
//
//  Created by Sebastián Vidal Aedo on 13-03-26.
//

import AppKit
import SwiftUI
import UserNotifications
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var petWindow: NSWindow?
    var settingsWindow: NSWindow?
    var onboardingWindow: NSWindow?
    var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()

    static private(set) var shared: AppDelegate!

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        NSApp.setActivationPolicy(.accessory) // No Dock icon
        
        // Pedir permiso de notificaciones
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        setupMenuBarItem()
        setupPetWindow()
        
        if !UserDefaults.standard.bool(forKey: "hasFinishedOnboarding") {
            showOnboarding()
        }

        setupVisibilityObservation()
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
        let windowSize = CGSize(width: 200, height: 200)
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
        petWindow?.hasShadow = false
        petWindow?.backgroundColor = .clear
        petWindow?.level = .floating
        petWindow?.collectionBehavior = [.canJoinAllSpaces, .stationary]
        petWindow?.ignoresMouseEvents = false
        petWindow?.isMovableByWindowBackground = false
        petWindow?.contentView = NSHostingView(
            rootView: BuddyView()
                .environmentObject(PomodoroTimer.shared)
        )
        
        if BuddySettings.shared.isBuddyVisible {
            petWindow?.makeKeyAndOrderFront(nil)
        }
    }

    private func setupVisibilityObservation() {
        BuddySettings.shared.$isBuddyVisible
            .receive(on: RunLoop.main)
            .sink { [weak self] isVisible in
                if isVisible {
                    self?.petWindow?.makeKeyAndOrderFront(nil)
                } else {
                    self?.petWindow?.orderOut(nil)
                }
            }
            .store(in: &cancellables)
    }

    func showOnboarding() {
        if onboardingWindow == nil {
            onboardingWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 450),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            onboardingWindow?.center()
            onboardingWindow?.titleVisibility = .hidden
            onboardingWindow?.titlebarAppearsTransparent = true
            onboardingWindow?.isMovableByWindowBackground = true
            onboardingWindow?.contentView = NSHostingView(rootView: OnboardingView())
        }
        
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow?.makeKeyAndOrderFront(nil)
    }

    @objc func showSettings() {
        if settingsWindow == nil {
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 440),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.center()
            settingsWindow?.title = "Ajustes de FocusBuddy"
            settingsWindow?.titleVisibility = .visible
            settingsWindow?.titlebarAppearsTransparent = true
            settingsWindow?.isMovableByWindowBackground = true
            settingsWindow?.contentView = NSHostingView(
                rootView: SettingsView()
                    .environmentObject(PomodoroTimer.shared)
            )
        }
        
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
