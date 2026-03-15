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
    var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?

    static private(set) var shared: AppDelegate!

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        NSApp.setActivationPolicy(.accessory) // No Dock icon
        
        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        setupMenuBarItem()
        setupPetWindow()
        
        if !UserDefaults.standard.bool(forKey: "hasFinishedOnboarding") {
            showOnboarding()
        }

        setupVisibilityObservation()
        setupTimerObserver()
        setupWakeObservation()
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
        popover?.contentSize = NSSize(width: 320, height: 480)
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
        let windowSize = CGSize(width: 200, height: 280)
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
        petWindow?.isMovableByWindowBackground = true
        petWindow?.contentView = NSHostingView(
            rootView: BuddyView()
                .environmentObject(PomodoroTimer.shared)
        )
        
        if BuddySettings.shared.isBuddyVisible {
            petWindow?.makeKeyAndOrderFront(nil)
        }
    }

    private func setupTimerObserver() {
        PomodoroTimer.shared.$secondsRemaining
            .removeDuplicates()
            .combineLatest(
                PomodoroTimer.shared.$isRunning.removeDuplicates(),
                PomodoroTimer.shared.$phase.removeDuplicates()
            )
            .receive(on: RunLoop.main)
            .sink { [weak self] _, isRunning, phase in
                self?.updateStatusItemTitle(isRunning: isRunning, phase: phase)
            }
            .store(in: &cancellables)
    }

    private func updateStatusItemTitle(isRunning: Bool, phase: TimerPhase) {
        let button = statusItem?.button
        if phase != .idle {
            let title = PomodoroTimer.shared.timeString
            
            // Only update if text actually changed to save CPU
            if button?.title != title {
                let font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .baselineOffset: -0.5
                ]
                button?.attributedTitle = NSAttributedString(string: title, attributes: attrs)
            }
        } else {
            button?.attributedTitle = NSAttributedString(string: "")
            button?.title = ""
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
        let onboardingWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 450),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        onboardingWindow.center()
        onboardingWindow.titleVisibility = .hidden
        onboardingWindow.titlebarAppearsTransparent = true
        onboardingWindow.isMovableByWindowBackground = true
        onboardingWindow.contentView = NSHostingView(
            rootView: OnboardingView()
                .environmentObject(PomodoroTimer.shared)
        )
        
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow.makeKeyAndOrderFront(nil)
    }

    @objc func showSettings() {
        togglePopover()
    }
    
    @objc func showStats() {
        togglePopover()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Ensure DND is turned off if the app is closed during a session
        if BuddySettings.shared.enableDNDSync {
            DNDManager.shared.setDND(enabled: false)
        }
    }

    private func setupWakeObservation() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func handleWake() {
        PomodoroTimer.shared.checkDayReset()
    }
}
