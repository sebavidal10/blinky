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
            title: "¡Bienvenido a FocusBuddy!",
            description: "Tu nuevo compañero de productividad que vive en tu escritorio.",
            image: "🐱",
            color: .blue
        ),
        OnboardingPage(
            title: "Enfócate con Pomodoro",
            description: "Trabaja en bloques de 25 minutos. Tu Buddy reaccionará en tiempo real a tu esfuerzo.",
            image: "🤓",
            color: .orange
        ),
        OnboardingPage(
            title: "Evoluciona a tu Buddy",
            description: "Gana XP por cada sesión. Sube de nivel y desbloquea nuevas reacciones y secretos.",
            image: "🏆",
            color: .yellow
        ),
        OnboardingPage(
            title: "Muévelo con Libertad",
            description: "Arrastra desde el pequeño icono superior para posicionarlo donde quieras.",
            image: "🎯",
            color: .green
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(0..<pages.count, id: \.self) { i in
                    if currentPage == i {
                        VStack(spacing: 30) {
                            Text(pages[i].image)
                                .font(.system(size: 100))
                                .shadow(color: pages[i].color.opacity(0.3), radius: 20)
                            
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
                // Page Indicator
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
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("¡Empezar!") {
                        UserDefaults.standard.set(true, forKey: "hasFinishedOnboarding")
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
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
    let color: Color
}

#Preview {
    OnboardingView()
}
