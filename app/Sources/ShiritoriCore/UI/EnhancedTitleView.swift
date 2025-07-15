import SwiftUI

/// 子供向けに強化されたタイトル画面
public struct EnhancedTitleView: View {
    public let isAnimationEnabled: Bool
    private let onStartGame: () -> Void
    private let onManagePlayers: () -> Void
    private let onShowSettings: (() -> Void)?
    
    @State private var titleOffset: CGFloat = -100
    @State private var buttonsOpacity: Double = 0.0
    @State private var bounceAnimation: Bool = false
    
    public init(
        isAnimationEnabled: Bool = true,
        onStartGame: @escaping () -> Void,
        onManagePlayers: @escaping () -> Void,
        onShowSettings: (() -> Void)? = nil
    ) {
        AppLogger.shared.debug("EnhancedTitleView初期化: アニメーション=\(isAnimationEnabled)")
        self.isAnimationEnabled = isAnimationEnabled
        self.onStartGame = onStartGame
        self.onManagePlayers = onManagePlayers
        self.onShowSettings = onShowSettings
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
                titleOffset = 0
                buttonsOpacity = 1.0
            }
        }
    }
    
    private func startEntryAnimation() {
        // タイトルのスライドイン
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0)) {
            titleOffset = 0
        }
        
        // ボタンのフェードイン
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.6)) {
                buttonsOpacity = 1.0
            }
        }
        
        // ボタンのバウンス効果
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                bounceAnimation = true
            }
        }
    }
}