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

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Unified General & Appearance Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text(Localization.settingsGeneralAppearance)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 12) {
                            AppearanceToggle(title: Localization.launchAtLogin, icon: "power", isOn: $buddySettings.launchAtLogin)
                            
                            Divider()
                                .padding(.vertical, 4)
                            
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
                            
                            Divider()
                                .padding(.vertical, 4)

                            AppearanceToggle(title: Localization.showBuddy, icon: buddySettings.isBuddyVisible ? "eye.fill" : "eye.slash.fill", isOn: $buddySettings.isBuddyVisible)
                            AppearanceToggle(title: Localization.lightingEffect, icon: buddySettings.showAura ? "sun.max.fill" : "sun.max", isOn: $buddySettings.showAura)
                            AppearanceToggle(title: Localization.insomniaMode, icon: buddySettings.isInsomniaEnabled ? "bolt.fill" : "bolt", isOn: $buddySettings.isInsomniaEnabled)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
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
