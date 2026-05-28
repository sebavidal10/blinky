//
//  SettingsView.swift
//
//  Created by Sebastián Vidal Aedo on 14-03-26.
//

import SwiftUI
import EventKit

struct SettingsView: View {
    @EnvironmentObject var timer: SessionManager
    @ObservedObject var buddySettings = BuddySettings.shared
    @ObservedObject var calendar = CalendarManager.shared

    var body: some View {
        VStack(spacing: 0) {
            ViewHeader(title: Localization.settings)

            ScrollView {
                VStack(spacing: 24) {
                    // 1. General & Startup
                    VStack(alignment: .leading, spacing: 16) {
                        Text(Localization.generalStartup)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 12) {
                            AppearanceToggle(title: Localization.launchAtLogin, icon: "power", isOn: $buddySettings.launchAtLogin)
                            
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.secondary)
                                    .frame(width: 16)
                                Text(Localization.settingsLanguage)
                                    .font(.system(size: 11, weight: .medium))
                                Spacer()
                                Picker("", selection: $buddySettings.appLanguage) {
                                    ForEach(AppLanguage.allCases) { lang in
                                        Text(lang.displayName).tag(lang)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 120)
                            }

                            HStack {
                                Image(systemName: "safari")
                                    .foregroundColor(.secondary)
                                    .frame(width: 16)
                                Text(Localization.selectBrowser)
                                    .font(.system(size: 11, weight: .medium))
                                Spacer()
                                Picker("", selection: $buddySettings.preferredBrowser) {
                                    ForEach(["System Default", "Safari", "Google Chrome", "Firefox", "Arc"], id: \.self) { browser in
                                        Text(browser).tag(browser)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    
                    // 2. Buddy Configuration
                    VStack(alignment: .leading, spacing: 16) {
                        Text(Localization.buddyConfiguration)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 12) {
                            AppearanceToggle(title: Localization.showBuddy, icon: buddySettings.isBuddyVisible ? "eye.fill" : "eye.slash.fill", isOn: $buddySettings.isBuddyVisible)
                            AppearanceToggle(title: Localization.lightingEffect, icon: buddySettings.showAura ? "sun.max.fill" : "sun.max", isOn: $buddySettings.showAura)
                            AppearanceToggle(title: Localization.insomniaMode, icon: buddySettings.isInsomniaEnabled ? "bolt.fill" : "bolt", isOn: $buddySettings.isInsomniaEnabled)
                            AppearanceToggle(title: Localization.showNextEvent, icon: buddySettings.showNextEventInMenuBar ? "calendar.badge.clock" : "calendar", isOn: $buddySettings.showNextEventInMenuBar)
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(.secondary)
                                    .frame(width: 16)
                                Text(Localization.at("Min. aviso reunión.", "Min. aviso reunión."))
                                    .font(.system(size: 11, weight: .medium))
                                
                                Spacer()
                                
                                Picker("", selection: $buddySettings.meetingCountdownThreshold) {
                                    Text("5").tag(5)
                                    Text("10").tag(10)
                                    Text("15").tag(15)
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                                .frame(width: 60)
                                .controlSize(.small)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)


                    // 4. Calendar Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text(Localization.settingsCalendars)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        if !CalendarManager.shared.isAuthorized {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(Localization.calendarAccessDenied)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    let status = EKEventStore.authorizationStatus(for: .event)
                                    if status == .notDetermined {
                                        CalendarManager.shared.requestAccess()
                                    } else {
                                        CalendarManager.shared.openSystemSettings()
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
                                ForEach(CalendarManager.shared.getAllCalendars(), id: \.calendarIdentifier) { cal in
                                    Toggle(isOn: Binding(
                                        get: { CalendarManager.shared.selectedCalendarIDs.contains(cal.calendarIdentifier) },
                                        set: { _ in CalendarManager.shared.toggleCalendar(cal.calendarIdentifier) }
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

                                Divider()
                                    .padding(.vertical, 8)

                                // Sync Button
                                Button(action: { 
                                    calendar.refresh() 
                                }) {
                                    HStack(spacing: 8) {
                                        SyncIcon(isFetching: calendar.isFetching, color: .primary.opacity(0.8))
                                        
                                        Text(calendar.isFetching ? Localization.at("Loading...", "Cargando...") : Localization.syncNow)
                                    }
                                    .font(.system(size: 11, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.primary.opacity(0.05))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                                .disabled(CalendarManager.shared.isFetching)
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)

                    // About Section (Integrated)
                    VStack(spacing: 8) {
                        Divider()
                            .padding(.bottom, 8)
                        
                        Text(Localization.aboutTitle)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(Localization.aboutVersion)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        Text(Localization.aboutCopyright)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity)

                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .padding(.top, 16) 
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SessionManager.shared)
}
