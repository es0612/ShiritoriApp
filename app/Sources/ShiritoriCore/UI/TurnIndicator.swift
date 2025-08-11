import SwiftUI

/// ターン表示用インジケーターコンポーネント
public struct TurnIndicator: View {
    public let currentPlayerName: String
    public let isAnimated: Bool
    
    // UIState統合によるアニメーション管理
    @State private var uiState = UIState.shared
    
    private var animationScale: CGFloat {
        CGFloat(uiState.animationValues["turnIndicator_scale_\(currentPlayerName)"] ?? 1.0)
    }
    
    private var animationOpacity: Double {
        uiState.animationValues["turnIndicator_opacity_\(currentPlayerName)"] ?? 1.0
    }
    
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
        let scaleKey = "turnIndicator_scale_\(currentPlayerName)"
        
        uiState.setAnimationValue(1.0, for: scaleKey)
        uiState.startAnimation(scaleKey)
        
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            uiState.setAnimationValue(1.05, for: scaleKey)
        }
    }
    
    private func startTransitionAnimation() {
        let scaleKey = "turnIndicator_scale_\(currentPlayerName)"
        let opacityKey = "turnIndicator_opacity_\(currentPlayerName)"
        
        withAnimation(.easeOut(duration: 0.2)) {
            uiState.setAnimationValue(0.0, for: opacityKey)
            uiState.setAnimationValue(0.8, for: scaleKey)
        }
        
        // UIState自動遷移による遅延処理（DispatchQueue.main.asyncAfterの代替）
        uiState.scheduleAutoTransition(for: "turnIndicator_transition_\(currentPlayerName)", after: 0.2) {
            withAnimation(.easeIn(duration: 0.3)) {
                uiState.setAnimationValue(1.0, for: opacityKey)
                uiState.setAnimationValue(1.0, for: scaleKey)
            }
        }
    }
}