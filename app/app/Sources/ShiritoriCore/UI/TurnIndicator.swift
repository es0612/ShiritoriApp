import SwiftUI

/// ターン表示用インジケーターコンポーネント
public struct TurnIndicator: View {
    public let currentPlayerName: String
    public let isAnimated: Bool
    
    @State private var animationScale: CGFloat = 1.0
    @State private var animationOpacity: Double = 1.0
    
    public init(
        currentPlayerName: String,
        isAnimated: Bool = true
    ) {
        AppLogger.shared.debug("TurnIndicator初期化: プレイヤー=\(currentPlayerName), アニメーション=\(isAnimated)")
        self.currentPlayerName = currentPlayerName
        self.isAnimated = isAnimated
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            Text("つぎのばん")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                Text(currentPlayerName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("ちゃん")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.yellow.opacity(0.3))
                    .stroke(Color.orange, lineWidth: 2)
            )
            .scaleEffect(animationScale)
            .opacity(animationOpacity)
            .onAppear {
                if isAnimated {
                    startPulseAnimation()
                }
            }
            .onChange(of: currentPlayerName) { _, _ in
                if isAnimated {
                    startTransitionAnimation()
                }
            }
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            animationScale = 1.05
        }
    }
    
    private func startTransitionAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            animationOpacity = 0.0
            animationScale = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeIn(duration: 0.3)) {
                animationOpacity = 1.0
                animationScale = 1.0
            }
        }
    }
}