//
//  CalendarSettingsView.swift
//
//  Created by Sebastián Vidal Aedo on 14-03-17.
//

import SwiftUI
import EventKit

struct CalendarSettingsView: View {
    @ObservedObject var calendar = CalendarManager.shared
    @ObservedObject var buddySettings = BuddySettings.shared
    @State private var availableCalendars: [EKCalendar] = []

    let browsers = ["System Default", "Safari", "Google Chrome", "Firefox", "Arc"]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Browser Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text(Localization.defaultBrowser)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "safari")
                                .foregroundColor(.secondary)
                                .frame(width: 16)
                            Text(Localization.selectBrowser)
                                .font(.system(size: 11, weight: .medium))
                            Spacer()
                            Picker("", selection: $buddySettings.preferredBrowser) {
                                ForEach(browsers, id: \.self) { browser in
                                    Text(browser).tag(browser)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 140)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)

                    // Calendar Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text(Localization.settingsCalendars)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        if !calendar.isAuthorized {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(Localization.calendarAccessDenied)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    let status = EKEventStore.authorizationStatus(for: .event)
                                    if status == .notDetermined {
                                        calendar.requestAccess()
                                    } else {
                                        calendar.openSystemSettings()
                                    }
                                }) {
                                    Text(EKEventStore.authorizationStatus(for: .event) == .notDetermined ? Localization.grantAccess : Localization.openSystemSettings)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .background(Color.green)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            VStack(spacing: 8) {
                                ForEach(availableCalendars, id: \.calendarIdentifier) { cal in
                                    Toggle(isOn: Binding(
                                        get: { calendar.selectedCalendarIDs.contains(cal.calendarIdentifier) },
                                        set: { _ in calendar.toggleCalendar(cal.calendarIdentifier) }
                                    )) {
                                        HStack(spacing: 10) {
                                            Circle()
                                                .fill(Color(nsColor: cal.color))
                                                .frame(width: 8, height: 8)
                                            Text(cal.title)
                                                .font(.system(size: 11, weight: .medium))
                                            Spacer()
                                        }
                                    }
                                    .toggleStyle(.switch)
                                    .tint(.green)
                                    .controlSize(.small)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    
                    // Sync Button
                    Button(action: { calendar.refresh() }) {
                        HStack {
                            if calendar.isFetching {
                                ProgressView()
                                    .controlSize(.mini)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text(Localization.syncNow)
                        }
                        .font(.system(size: 11, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(calendar.isFetching)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .padding(.top, 16)
            }
        }
        .onAppear {
            loadCalendars()
        }
        .onChange(of: calendar.isAuthorized) {
            loadCalendars()
        }
    }

    private func loadCalendars() {
        DispatchQueue.global(qos: .userInitiated).async {
            let calendars = calendar.getAllCalendars()
            DispatchQueue.main.async {
                self.availableCalendars = calendars
            }
        }
    }
}
