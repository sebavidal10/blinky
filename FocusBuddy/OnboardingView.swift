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
    
    let pages = [
        OnboardingPage(
            title: "FocusBuddy Pro",
            description: "Tu compañero de productividad minimalista. Diseñado para vivir en tu escritorio sin distraer.",
            image: "RobotBuddy",
            isAsset: true
        ),
        OnboardingPage(
            title: "Enfócate con Pomodoro",
            description: "Trabaja en bloques de 25 minutos. El Buddy reacciona sutilmente a tu progreso.",
            image: "brain.head.profile",
            isAsset: false
        ),
        OnboardingPage(
            title: "Control Total",
            description: "Oculta el Buddy cuando necesites espacio o muévelo libremente usando el tirador superior.",
            image: "eye.fill",
            isAsset: false
        ),
        OnboardingPage(
            title: "Privacidad Primero",
            description: "Sin monitoreo de teclado ni mouse. FocusBuddy solo depende de tu temporizador.",
            image: "lock.shield.fill",
            isAsset: false
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(0..<pages.count, id: \.self) { i in
                    if currentPage == i {
                        VStack(spacing: 30) {
                            if pages[i].isAsset {
                                Image(pages[i].image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
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
                    Button("Siguiente") {
                        withAnimation { currentPage += 1 }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("¡Empezar!") {
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
