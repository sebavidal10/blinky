//
//  CalendarManager.swift
//  Blinky
//
//  Created by Sebastián Vidal Aedo on 17-03-26.
//

import Foundation
import EventKit
import Combine
import AppKit
import SwiftUI

class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    
    private let eventStore = EKEventStore()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var events: [EKEvent] = []
    @Published var todayEvents: [EKEvent] = []
    @Published var tomorrowEvents: [EKEvent] = []
    @Published var isAuthorized: Bool = false
    @Published var isFetching: Bool = false
    
    @Published var selectedCalendarIDs: Set<String> = [] {
        didSet {
            UserDefaults.standard.set(Array(selectedCalendarIDs), forKey: "selectedCalendarIDs")
        }
    }
    
    private init() {
        if let saved = UserDefaults.standard.stringArray(forKey: "selectedCalendarIDs") {
            selectedCalendarIDs = Set(saved)
        }
        
        $selectedCalendarIDs
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.fetchEvents()
            }
            .store(in: &cancellables)
        
        checkAuthorization()
    }
    
    func checkAuthorization() {
        let status = EKEventStore.authorizationStatus(for: .event)
        let isAuthorizedStatus: Bool
        
        if #available(macOS 14.0, iOS 17.0, *) {
            isAuthorizedStatus = (status == .fullAccess)
        } else {
            isAuthorizedStatus = (status == .authorized)
        }

        DispatchQueue.main.async {
            self.isAuthorized = isAuthorizedStatus
            if isAuthorizedStatus {
                self.fetchEvents()
            } else if status == .notDetermined {
                self.requestAccess()
            }
        }
    }
    
    func requestAccess() {
        if #available(macOS 14.0, iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] (granted: Bool, error: Error?) in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.fetchEvents()
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] (granted: Bool, error: Error?) in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.fetchEvents()
                    }
                }
            }
        }
    }
    
    func fetchEvents() {
        let status = EKEventStore.authorizationStatus(for: .event)
        let isAuthorizedStatus: Bool
        if #available(macOS 14.0, iOS 17.0, *) {
            isAuthorizedStatus = (status == .fullAccess)
        } else {
            isAuthorizedStatus = (status == .authorized)
        }
        
        guard isAuthorizedStatus else { 
            DispatchQueue.main.async { self.isAuthorized = false }
            return 
        }
        
        DispatchQueue.main.async {
            self.isFetching = true
            self.isAuthorized = true
            print("CalendarManager: Starting fetchEvents...")
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Force refresh from system sources (iCloud, Google, etc.)
            self.eventStore.refreshSourcesIfNecessary()
            
            let now = Date()
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: now)
            let endOfTomorrow = calendar.date(byAdding: .day, value: 2, to: startOfToday)!
            
            let allCalendars = self.eventStore.calendars(for: .event)
            var calendarsToFetch = self.selectedCalendarIDs.isEmpty ? nil : allCalendars.filter { self.selectedCalendarIDs.contains($0.calendarIdentifier) }
            
            // Fallback: If user has selections but NONE are currently available, 
            // maybe they were deleted/renamed. Let's fetch all as fallback to avoid empty list.
            if self.selectedCalendarIDs.isEmpty == false && (calendarsToFetch == nil || calendarsToFetch!.isEmpty) {
                calendarsToFetch = nil 
            }
            
            // If user selected calendars but they are not found, return empty
            if !self.selectedCalendarIDs.isEmpty && (calendarsToFetch == nil || calendarsToFetch!.isEmpty) {
                print("CalendarManager: Selected IDs (\(self.selectedCalendarIDs)) not found in available calendars.")
                DispatchQueue.main.async {
                    self.events = []
                    self.todayEvents = []
                    self.tomorrowEvents = []
                    self.isFetching = false
                }
                return
            }

            print("CalendarManager: Fetching from \(calendarsToFetch?.count ?? allCalendars.count) calendars.")

            let predicate = self.eventStore.predicateForEvents(withStart: now, end: endOfTomorrow, calendars: calendarsToFetch)
            let allEvents = self.eventStore.events(matching: predicate)
            
            let filteredEvents = allEvents
                .filter { $0.endDate > now }
                .sorted { $0.startDate < $1.startDate }
                
            let today = filteredEvents.filter { calendar.isDateInToday($0.startDate) }
            let tomorrow = filteredEvents.filter { calendar.isDateInTomorrow($0.startDate) }

            // Add a slight minimum delay so the user can actually see the sync animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.events = filteredEvents
                self.todayEvents = today
                self.tomorrowEvents = tomorrow
                self.isFetching = false
                print("CalendarManager: Fetch complete. Found \(filteredEvents.count) events.")
            }
        }
    }

    func refresh() {
        fetchEvents()
    }

    func getAllCalendars() -> [EKCalendar] {
        return eventStore.calendars(for: .event).sorted { $0.title < $1.title }
    }

    func toggleCalendar(_ id: String) {
        if selectedCalendarIDs.contains(id) {
            selectedCalendarIDs.remove(id)
        } else {
            selectedCalendarIDs.insert(id)
        }
    }

    func openSystemSettings() {
        let urlString: String
        if #available(macOS 14.0, *) {
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
        } else {
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        }
        
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        } else if let fallback = URL(string: "x-apple.systempreferences:com.apple.Settings.Privacy-Security.extension?Privacy_Calendars") {
             NSWorkspace.shared.open(fallback)
        }
    }
}
