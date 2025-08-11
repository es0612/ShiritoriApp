import SwiftUI

/// アニメーション付きタイトルテキスト
public struct AnimatedTitleText: View {
    public let title: String
    public let isAnimated: Bool
    
    // UIState統合によるアニメーション管理
    @State private var uiState = UIState.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private var colorShift: Bool {
        uiState.getTransitionPhase("animatedTitle_colorShift_\(title)") == "shifted"
    }
    
    private var scaleEffect: CGFloat {
        CGFloat(uiState.animationValues["animatedTitle_scale_\(title)"] ?? 1.0)
    }
    
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
                    colors: adaptiveGradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(color: adaptiveShadowColor, radius: 4, x: 2, y: 2)
            .scaleEffect(scaleEffect)
            .onAppear {
                if isAnimated {
                    startColorAnimation()
                    startScaleAnimation()
                }
            }
    }
    
    private var adaptiveGradientColors: [Color] {
        if colorScheme == .dark {
            return colorShift ? [.cyan, .indigo, .purple] : [.orange, .pink, .yellow]
        } else {
            return colorShift ? [.blue, .purple, .pink] : [.orange, .red, .yellow]
        }
    }
    
    private var adaptiveShadowColor: Color {
        colorScheme == .dark ? .white.opacity(0.2) : .black.opacity(0.3)
    }
    
    private func startColorAnimation() {
        let colorKey = "animatedTitle_colorShift_\(title)"
        
        uiState.setTransitionPhase("normal", for: colorKey)
        
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            uiState.setTransitionPhase("shifted", for: colorKey)
        }
    }
    
    private func startScaleAnimation() {
        let scaleKey = "animatedTitle_scale_\(title)"
        
        uiState.setAnimationValue(1.0, for: scaleKey)
        uiState.startAnimation(scaleKey)
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            uiState.setAnimationValue(1.05, for: scaleKey)
        }
    }
}