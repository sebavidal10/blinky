import SwiftUI
import Combine

struct ConfettiView: View {
    @State private var particles: [Particle] = []
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var color: Color
        var size: CGFloat
        var speed: CGFloat
        var opacity: Double = 1.0
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
            }
        }
        .onReceive(timer) { _ in
            updateParticles()
        }
        .onAppear {
            spawnParticles()
        }
    }
    
    private func spawnParticles() {
        for _ in 0..<30 {
            particles.append(createParticle())
        }
    }
    
    private func createParticle() -> Particle {
        let colors: [Color] = [.blue, .teal, .purple, .pink, .yellow, .orange]
        return Particle(
            x: CGFloat.random(in: 50...150),
            y: CGFloat.random(in: 200...250),
            color: colors.randomElement()!,
            size: CGFloat.random(in: 4...8),
            speed: CGFloat.random(in: 2...5)
        )
    }
    
    private func updateParticles() {
        for i in 0..<particles.count {
            particles[i].y -= particles[i].speed
            particles[i].x += CGFloat.random(in: -2...2)
            particles[i].opacity -= 0.02
        }
        
        particles.removeAll { $0.opacity <= 0 || $0.y < 0 }
        
        if particles.count < 10 {
            // Stop spawning after a bit to make it an "effect" not a constant rain
        }
    }
}

struct ConfettiView_Previews: PreviewProvider {
    static var previews: some View {
        ConfettiView()
            .frame(width: 200, height: 280)
            .background(Color.black)
    }
}
