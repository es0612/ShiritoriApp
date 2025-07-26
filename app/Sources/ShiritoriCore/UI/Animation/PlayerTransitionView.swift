import SwiftUI

/// プレイヤー切り替え時の遷移アニメーションビュー
public struct PlayerTransitionView: View {
    public let newPlayer: GameParticipant
    public let isVisible: Bool
    private let onAnimationComplete: () -> Void
    
    @State private var animationPhase: AnimationPhase = .hidden
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0.0
    @State private var rotation: Double = 0.0
    
    public init(
        newPlayer: GameParticipant,
        isVisible: Bool,
        onAnimationComplete: @escaping () -> Void = {}
    ) {
        self.newPlayer = newPlayer
        self.isVisible = isVisible
        self.onAnimationComplete = onAnimationComplete
        AppLogger.shared.debug("PlayerTransitionView初期化: \(newPlayer.name)")
    }
    
    public var body: some View {
        ZStack {
            if isVisible {
                // 背景オーバーレイ
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // タップで早期終了
                        dismissAnimation()
                    }
                
                // メイン遷移コンテンツ
                transitionContent
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .rotationEffect(.degrees(rotation))
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: scale)
                    .animation(.easeInOut(duration: 0.5), value: opacity)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: rotation)
            }
        }
        .onChange(of: isVisible) { _, visible in
            if visible {
                startAnimation()
            } else {
                hideAnimation()
            }
        }
        .onAppear {
            if isVisible {
                startAnimation()
            }
        }
    }
    
    @ViewBuilder
    private var transitionContent: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            // プレイヤーアバター（大きめ）
            VStack {
                // 自然なアニメーション効果付きアバター表示
                PlayerAvatarView(
                    playerName: newPlayer.name,
                    imageData: nil,
                    size: 120
                )
                .overlay(
                    // アニメーション用のオーバーレイリング - より自然な表現
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [playerTypeColor, playerTypeColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: animationPhase == .highlighted ? 6 : 4
                        )
                        .scaleEffect(animationPhase == .highlighted ? 1.08 : 1.0)
                        .opacity(animationPhase == .highlighted ? 0.8 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatCount(2, autoreverses: true), value: animationPhase)
                )
                .shadow(
                    color: playerTypeColor.opacity(0.4),
                    radius: animationPhase == .highlighted ? 12 : 8,
                    x: 0,
                    y: animationPhase == .highlighted ? 6 : 4
                )
                .animation(.easeInOut(duration: 0.5), value: animationPhase)
            }
            
            // ターン告知テキスト
            VStack(spacing: DesignSystem.Spacing.small) {
                Text(newPlayer.name)
                    .font(DesignSystem.Typography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("さんの番です！")
                    .font(DesignSystem.Typography.title)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                // プレイヤータイプ表示
                HStack {
                    Image(systemName: playerTypeIcon)
                        .foregroundColor(playerTypeColor)
                    
                    Text(newPlayer.type.displayName)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(playerTypeColor)
                }
                .padding(.horizontal, DesignSystem.Spacing.standard)
                .padding(.vertical, DesignSystem.Spacing.small)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
                        .fill(playerTypeColor.opacity(0.1))
                        .stroke(playerTypeColor, lineWidth: 2)
                )
            }
            
            // 進行表示（タップでスキップ）
            if animationPhase == .showing {
                Text("タップでスキップ")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
                    .opacity(0.7)
                    .padding(.top, DesignSystem.Spacing.small)
            }
        }
        .padding(DesignSystem.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(.regularMaterial)
                .stroke(playerTypeColor, lineWidth: 3)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding(DesignSystem.Spacing.standard)
    }
    
    private var playerTypeColor: Color {
        switch newPlayer.type {
        case .human:
            return .blue
        case .computer(let difficulty):
            switch difficulty {
            case .easy:
                return .green
            case .normal:
                return .orange
            case .hard:
                return .red
            }
        }
    }
    
    private var playerTypeIcon: String {
        switch newPlayer.type {
        case .human:
            return "person.fill"
        case .computer:
            return "desktopcomputer"
        }
    }
    
    // MARK: - Animation Control
    
    private func startAnimation() {
        AppLogger.shared.debug("PlayerTransition開始アニメーション: \(newPlayer.name)")
        
        // 初期状態
        scale = 0.3
        opacity = 0.0
        rotation = -10.0
        animationPhase = .entering
        
        // フェーズ1: 登場アニメーション
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            scale = 1.0
            opacity = 1.0
            rotation = 0.0
        }
        
        // フェーズ2: ハイライト表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animationPhase = .highlighted
            
            // フェーズ3: 通常表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                animationPhase = .showing
                
                // 3秒後に自動終了
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
                    dismissAnimation()
                }
            }
        }
    }
    
    private func hideAnimation() {
        AppLogger.shared.debug("PlayerTransition終了アニメーション")
        
        animationPhase = .leaving
        
        withAnimation(.easeInOut(duration: 0.4)) {
            scale = 0.8
            opacity = 0.0
            rotation = 5.0
        }
        
        // アニメーション完了を通知
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            animationPhase = .hidden
            onAnimationComplete()
        }
    }
    
    private func dismissAnimation() {
        guard animationPhase != .leaving && animationPhase != .hidden else { return }
        
        AppLogger.shared.info("PlayerTransition早期終了")
        hideAnimation()
    }
}

/// アニメーションの段階を表す列挙型
private enum AnimationPhase {
    case hidden     // 非表示
    case entering   // 登場中
    case highlighted // ハイライト中
    case showing    // 表示中
    case leaving    // 退場中
}

// MARK: - Preview

#Preview {
    PlayerTransitionView(
        newPlayer: GameParticipant(
            id: "1",
            name: "テストプレイヤー",
            type: .human
        ),
        isVisible: true
    )
}