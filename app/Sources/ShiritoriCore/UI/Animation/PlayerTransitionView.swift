import SwiftUI

/// プレイヤー切り替え時の遷移アニメーションビュー
public struct PlayerTransitionView: View {
    public let newPlayer: GameParticipant
    public let isVisible: Bool
    private let onAnimationComplete: () -> Void
    
    // UIState統合によるアニメーション管理
    @State private var uiState = UIState.shared
    
    private var animationPhase: String {
        uiState.getTransitionPhase("playerTransition_phase_\(newPlayer.id)") ?? "hidden"
    }
    
    private var scale: CGFloat {
        CGFloat(uiState.animationValues["playerTransition_scale_\(newPlayer.id)"] ?? 0.3)
    }
    
    private var opacity: Double {
        uiState.animationValues["playerTransition_opacity_\(newPlayer.id)"] ?? 0.0
    }
    
    private var rotation: Double {
        uiState.animationValues["playerTransition_rotation_\(newPlayer.id)"] ?? 0.0
    }
    
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
            // プレイヤーアバター（重なりのない統合デザイン）
            TransitionPlayerAvatarView(
                player: newPlayer,
                size: 120,
                animationPhase: .showing
            )
            
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
            if animationPhase == "showing" {
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
        
        let playerId = newPlayer.id
        let scaleKey = "playerTransition_scale_\(playerId)"
        let opacityKey = "playerTransition_opacity_\(playerId)"
        let rotationKey = "playerTransition_rotation_\(playerId)"
        let phaseKey = "playerTransition_phase_\(playerId)"
        
        // UIState統合による初期状態設定
        uiState.setAnimationValue(0.3, for: scaleKey)
        uiState.setAnimationValue(0.0, for: opacityKey)
        uiState.setAnimationValue(-10.0, for: rotationKey)
        uiState.setTransitionPhase("entering", for: phaseKey)
        
        // アニメーション開始マーク
        uiState.startAnimation(scaleKey)
        uiState.startAnimation(opacityKey)
        uiState.startAnimation(rotationKey)
        
        // フェーズ1: 登場アニメーション
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            uiState.setAnimationValue(1.0, for: scaleKey)
            uiState.setAnimationValue(1.0, for: opacityKey)
            uiState.setAnimationValue(0.0, for: rotationKey)
        }
        
        // 🎯 UIState自動遷移による段階的アニメーション（DispatchQueue.main.asyncAfter の代替）
        uiState.scheduleAutoTransition(for: "\(playerId)_highlight", after: 0.3) {
            uiState.setTransitionPhase("highlighted", for: phaseKey)
            
            uiState.scheduleAutoTransition(for: "\(playerId)_showing", after: 0.6) {
                uiState.setTransitionPhase("showing", for: phaseKey)
                
                uiState.scheduleAutoTransition(for: "\(playerId)_autoDismiss", after: 2.1) {
                    self.dismissAnimation()
                }
            }
        }
    }
    
    private func hideAnimation() {
        AppLogger.shared.debug("PlayerTransition終了アニメーション")
        
        let playerId = newPlayer.id
        let scaleKey = "playerTransition_scale_\(playerId)"
        let opacityKey = "playerTransition_opacity_\(playerId)"
        let rotationKey = "playerTransition_rotation_\(playerId)"
        let phaseKey = "playerTransition_phase_\(playerId)"
        
        // UIState統合による終了アニメーション
        uiState.setTransitionPhase("leaving", for: phaseKey)
        
        withAnimation(.easeInOut(duration: 0.4)) {
            uiState.setAnimationValue(0.8, for: scaleKey)
            uiState.setAnimationValue(0.0, for: opacityKey)
            uiState.setAnimationValue(5.0, for: rotationKey)
        }
        
        // 🎯 UIState自動遷移によるアニメーション完了処理（DispatchQueue.main.asyncAfter の代替）
        uiState.scheduleAutoTransition(for: "\(playerId)_hideComplete", after: 0.4) {
            uiState.setTransitionPhase("hidden", for: phaseKey)
            uiState.endAnimation(scaleKey)
            uiState.endAnimation(opacityKey)
            uiState.endAnimation(rotationKey)
            onAnimationComplete()
        }
    }
    
    private func dismissAnimation() {
        guard animationPhase != "leaving" && animationPhase != "hidden" else { return }
        
        AppLogger.shared.info("PlayerTransition早期終了")
        hideAnimation()
    }
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