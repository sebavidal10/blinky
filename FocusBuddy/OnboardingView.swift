//
//  OnboardingView.swift
//  FocusBuddy
//
//  Created by Sebastián Vidal Aedo on 14-03-26.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPage = 0
    
    var pages: [OnboardingPage] {
        [
            OnboardingPage(
                title: Localization.obTitle1,
                description: Localization.obDesc1,
                image: "RobotBuddy",
                isAsset: true
            ),
            OnboardingPage(
                title: Localization.obTitle2,
                description: Localization.obDesc2,
                image: "brain.head.profile",
                isAsset: false
            ),
            OnboardingPage(
                title: Localization.obTitle3,
                description: Localization.obDesc3,
                image: "eye.fill",
                isAsset: false
            ),
            OnboardingPage(
                title: Localization.obTitle4,
                description: Localization.obDesc4,
                image: "lock.shield.fill",
                isAsset: false
            )
        ]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(0..<pages.count, id: \.self) { i in
                    if currentPage == i {
                        VStack(spacing: 30) {
                            if pages[i].isAsset {
                                RobotFace(mood: .relaxing, isBlinking: false)
                                    .frame(width: 120, height: 120)
                                    .shadow(radius: 10)
                            } else {
                                Image(systemName: pages[i].image)
                                    .font(.system(size: 80))
                                    .foregroundColor(.accentColor)
                            }
                            
                            VStack(spacing: 12) {
                                Text(pages[i].title)
                                    .font(.system(size: 24, weight: .bold))
                                
                                Text(pages[i].description)
                                    .font(.system(size: 15))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 40)
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Footer
            HStack {
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Circle()
                            .fill(currentPage == i ? Color.accentColor : Color.primary.opacity(0.1))
                            .frame(width: 8, height: 8)
                    }
                }
                
                Spacer()
                
                if currentPage < pages.count - 1 {
                    Button(Localization.next) {
                        withAnimation { currentPage += 1 }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button(Localization.getStarted) {
                        UserDefaults.standard.set(true, forKey: "hasFinishedOnboarding")
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(30)
        }
        .frame(width: 500, height: 450)
        .background(.ultraThinMaterial)
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let image: String
    let isAsset: Bool
}
