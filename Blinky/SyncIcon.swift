import SwiftUI

struct SyncIcon: View {
    let isFetching: Bool
    let color: Color
    let size: CGFloat
    
    @State private var rotation: Double = 0
    
    init(isFetching: Bool, color: Color = .secondary.opacity(0.6), size: CGFloat = 11) {
        self.isFetching = isFetching
        self.color = color
        self.size = size
    }
    
    var body: some View {
        Image(systemName: "arrow.clockwise")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(isFetching ? .accentColor : color)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                if isFetching {
                    startRotating()
                }
            }
            .onChange(of: isFetching) { _, fetching in
                if fetching {
                    startRotating()
                } else {
                    stopRotating()
                }
            }
    }
    
    private func startRotating() {
        rotation = 0
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }
    
    private func stopRotating() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            rotation = 0
        }
    }
}
