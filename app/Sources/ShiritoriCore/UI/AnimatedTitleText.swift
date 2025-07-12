import SwiftUI

/// アニメーション付きタイトルテキスト
public struct AnimatedTitleText: View {
    public let title: String
    public let isAnimated: Bool
    
    @State private var colorShift: Bool = false
    @State private var scaleEffect: CGFloat = 1.0
    
    public init(
        title: String,
        isAnimated: Bool = true
    ) {
        AppLogger.shared.debug("AnimatedTitleText初期化: タイトル=\(title), アニメーション=\(isAnimated)")
        self.title = title
        self.isAnimated = isAnimated
    }
    
    public var body: some View {
        Text(title)
            .font(.system(size: 42, weight: .black, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: colorShift ? [.blue, .purple, .pink] : [.orange, .red, .yellow],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
            .scaleEffect(scaleEffect)
            .onAppear {
                if isAnimated {
                    startColorAnimation()
                    startScaleAnimation()
                }
            }
    }
    
    private func startColorAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            colorShift.toggle()
        }
    }
    
    private func startScaleAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            scaleEffect = 1.05
        }
    }
}