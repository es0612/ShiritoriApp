import SwiftUI

/// 子供向けに強化されたタイトル画面
public struct EnhancedTitleView: View {
    public let isAnimationEnabled: Bool
    private let onStartGame: () -> Void
    private let onManagePlayers: () -> Void
    private let onShowSettings: (() -> Void)?
    private let onShowHistory: (() -> Void)?
    
    // UIState統合によるアニメーション管理
    @State private var uiState = UIState.shared
    
    private var titleOffset: CGFloat {
        CGFloat(uiState.animationValues["enhancedTitle_offset"] ?? -100.0)
    }
    
    private var buttonsOpacity: Double {
        uiState.animationValues["enhancedTitle_buttonsOpacity"] ?? 0.0
    }
    
    private var bounceAnimation: Bool {
        uiState.getTransitionPhase("enhancedTitle_bounce") == "active"
    }
    
    public init(
        isAnimationEnabled: Bool = true,
        onStartGame: @escaping () -> Void,
        onManagePlayers: @escaping () -> Void,
        onShowSettings: (() -> Void)? = nil,
        onShowHistory: (() -> Void)? = nil
    ) {
        AppLogger.shared.debug("EnhancedTitleView初期化: アニメーション=\(isAnimationEnabled)")
        self.isAnimationEnabled = isAnimationEnabled
        self.onStartGame = onStartGame
        self.onManagePlayers = onManagePlayers
        self.onShowSettings = onShowSettings
        self.onShowHistory = onShowHistory
    }
    
    public var body: some View {
        ZStack {
            // 背景
            ChildFriendlyBackground()
            
            VStack(spacing: 60) {
                // アニメーション付きタイトル
                AnimatedTitleText(
                    title: "しりとり あそび",
                    isAnimated: isAnimationEnabled
                )
                .offset(y: titleOffset)
                
                VStack(spacing: 24) {
                    // スタートボタン
                    ChildFriendlyButton(
                        title: "🎮 あそびはじめる",
                        backgroundColor: .green,
                        foregroundColor: .white
                    ) {
                        AppLogger.shared.info("スタートボタンタップ")
                        onStartGame()
                    }
                    .scaleEffect(bounceAnimation ? 1.05 : 1.0)
                    
                    // プレイヤー管理ボタン
                    ChildFriendlyButton(
                        title: "👤 プレイヤー とうろく",
                        backgroundColor: .orange,
                        foregroundColor: .white
                    ) {
                        AppLogger.shared.info("プレイヤー管理ボタンタップ")
                        onManagePlayers()
                    }
                    
                    // 履歴ボタン（履歴コールバックが提供されている場合のみ表示）
                    if let onShowHistory = onShowHistory {
                        ChildFriendlyButton(
                            title: "📈 ゲーム れきし",
                            backgroundColor: .purple,
                            foregroundColor: .white
                        ) {
                            AppLogger.shared.info("ゲーム履歴ボタンタップ")
                            onShowHistory()
                        }
                    }
                    
                    // 設定ボタン（設定コールバックが提供されている場合のみ表示）
                    if let onShowSettings = onShowSettings {
                        ChildFriendlyButton(
                            title: "⚙️ せってい",
                            backgroundColor: .blue,
                            foregroundColor: .white
                        ) {
                            AppLogger.shared.info("設定ボタンタップ")
                            onShowSettings()
                        }
                    }
                }
                .opacity(buttonsOpacity)
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding(.top, 100)
        }
        .onAppear {
            if isAnimationEnabled {
                startEntryAnimation()
            } else {
                uiState.setAnimationValue(0.0, for: "enhancedTitle_offset")
                uiState.setAnimationValue(1.0, for: "enhancedTitle_buttonsOpacity")
            }
        }
    }
    
    private func startEntryAnimation() {
        // UIState統合によるアニメーション開始
        uiState.setAnimationValue(-100.0, for: "enhancedTitle_offset")
        uiState.setAnimationValue(0.0, for: "enhancedTitle_buttonsOpacity")
        uiState.setTransitionPhase("inactive", for: "enhancedTitle_bounce")
        
        // タイトルのスライドイン
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0)) {
            uiState.setAnimationValue(0.0, for: "enhancedTitle_offset")
        }
        
        // 🎯 UIState自動遷移による遅延処理（DispatchQueue.main.asyncAfter の代替）
        uiState.scheduleAutoTransition(for: "enhancedTitle_buttonsIn", after: 0.5) {
            withAnimation(.easeOut(duration: 0.6)) {
                uiState.setAnimationValue(1.0, for: "enhancedTitle_buttonsOpacity")
            }
        }
        
        // 🎯 UIState自動遷移によるバウンスエフェクト開始
        uiState.scheduleAutoTransition(for: "enhancedTitle_bounceStart", after: 1.5) {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                uiState.setTransitionPhase("active", for: "enhancedTitle_bounce")
            }
        }
    }
}