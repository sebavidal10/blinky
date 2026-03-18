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
        
        UserDefaults.standard.set(true, forKey: "hasFinishedOnboarding")

        setupVisibilityObservation()
        setupTimerObserver()
        setupWakeObservation()
        setupInsomniaObservation()
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
                .environmentObject(SessionManager.shared)
                .environmentObject(CalendarManager.shared)
        )
    }

    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }

        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
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

        petWindow = BuddyWindow(
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
                .environmentObject(SessionManager.shared)
                .environmentObject(CalendarManager.shared)
        )
        
        if BuddySettings.shared.isBuddyVisible {
            petWindow?.makeKeyAndOrderFront(nil)
        }
    }

    private func setupTimerObserver() {
        Publishers.CombineLatest4(
            SessionManager.shared.$secondsRemaining.removeDuplicates(),
            SessionManager.shared.$secondsElapsed.removeDuplicates(),
            SessionManager.shared.$isRunning.removeDuplicates(),
            SessionManager.shared.$phase.removeDuplicates()
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _, _, isRunning, phase in
            self?.updateStatusItemTitle(isRunning: isRunning, phase: phase)
        }
        .store(in: &cancellables)
    }

    private func updateStatusItemTitle(isRunning: Bool, phase: TimerPhase) {
        let button = statusItem?.button
        
        // Ensure everything is cleared first
        button?.contentTintColor = nil
        button?.title = ""
        button?.attributedTitle = NSAttributedString(string: "")

        if phase != .idle {
            let title = SessionManager.shared.timeString
            
            let font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .baselineOffset: -0.5
            ]
            button?.attributedTitle = NSAttributedString(string: title, attributes: attrs)
        }
    }

    private func setupInsomniaObservation() {
        BuddySettings.shared.$isInsomniaEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusItemTitle(
                    isRunning: SessionManager.shared.isRunning,
                    phase: SessionManager.shared.phase
                )
            }
            .store(in: &cancellables)
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


    @objc func showSettings() {
        togglePopover()
    }
    
    @objc func showStats() {
        togglePopover()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // App cleanup
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
        SessionManager.shared.checkDayReset()
    }
}
