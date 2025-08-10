import SwiftUI

/// 紙吹雪アニメーションコンポーネント
public struct ConfettiAnimation: View {
    public let isActive: Bool
    
    // UIState統合による状態管理
    @State private var uiState = UIState.shared
    @State private var confettiPieces: [ConfettiPiece] = []
    
    private let confettiKey = UIState.Keys.confetti
    
    public init(isActive: Bool) {
        AppLogger.shared.debug("ConfettiAnimation初期化: アクティブ=\(isActive)")
        self.isActive = isActive
    }
    
    public var body: some View {
        ZStack {
            if isActive && uiState.getTransitionPhase(confettiKey) == "animating" {
                ForEach(confettiPieces, id: \.id) { piece in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(piece.color)
                        .frame(width: piece.size.width, height: piece.size.height)
                        .position(
                            x: piece.position.x + piece.velocity.x * animationPhase,
                            y: piece.position.y + piece.velocity.y * animationPhase + 0.5 * 500 * animationPhase * animationPhase // 重力効果
                        )
                        .rotationEffect(.degrees(piece.rotation + animationPhase * piece.rotationSpeed))
                        .opacity(max(0, 1 - animationPhase / 3))
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if isActive {
                startConfettiAnimation()
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startConfettiAnimation()
            } else {
                stopConfettiAnimation()
            }
        }
        .onChange(of: uiState.getTransitionPhase(confettiKey)) { _, phase in
            handlePhaseChange(phase)
        }
    }
    
    /// UIStateからのアニメーション段階値を取得
    private var animationPhase: Double {
        uiState.animationValues["confettiPhase"] ?? 0.0
    }
    
    /// 紙吹雪アニメーション開始
    private func startConfettiAnimation() {
        AppLogger.shared.debug("紙吹雪アニメーション開始")
        
        // 紙吹雪を生成
        generateConfetti()
        
        // UIStateで段階管理
        uiState.setTransitionPhase("preparing", for: confettiKey)
        uiState.setAnimationValue(0.0, for: "confettiPhase")
        uiState.startAnimation(confettiKey)
        
        // アニメーション実行
        withAnimation(.linear(duration: 3.0)) {
            uiState.setAnimationValue(1.0, for: "confettiPhase")
        }
        
        // 段階を「アニメーション中」に変更
        uiState.setTransitionPhase("animating", for: confettiKey)
        
        // 🎯 UIState自動遷移による遅延処理（DispatchQueue.main.asyncAfter の代替）
        uiState.scheduleAutoTransition(for: "\(confettiKey)_cleanup", after: 3.0) {
            self.cleanupConfettiAnimation()
        }
    }
    
    /// 紙吹雪アニメーション停止
    private func stopConfettiAnimation() {
        AppLogger.shared.debug("紙吹雪アニメーション停止")
        
        uiState.endAnimation(confettiKey)
        uiState.setTransitionPhase("stopped", for: confettiKey)
        uiState.cancelAutoTransition(for: "\(confettiKey)_cleanup")
        
        confettiPieces.removeAll()
        uiState.setAnimationValue(0.0, for: "confettiPhase")
    }
    
    /// アニメーション完了後のクリーンアップ
    private func cleanupConfettiAnimation() {
        AppLogger.shared.debug("紙吹雪アニメーション完了・クリーンアップ")
        
        uiState.endAnimation(confettiKey)
        uiState.setTransitionPhase("completed", for: confettiKey)
        
        confettiPieces.removeAll()
        uiState.setAnimationValue(0.0, for: "confettiPhase")
    }
    
    /// 段階変更処理
    private func handlePhaseChange(_ phase: String?) {
        guard let phase = phase else { return }
        
        AppLogger.shared.debug("紙吹雪段階変更: \(phase)")
        
        switch phase {
        case "preparing":
            break // 準備中は特に何もしない
        case "animating":
            break // アニメーション中は既に設定済み
        case "completed", "stopped":
            // 完了・停止時は自動でクリーンアップ済み
            break
        default:
            break
        }
    }
    
    private func generateConfetti() {
        confettiPieces = (0..<50).map { _ in
            ConfettiPiece(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: -20
                ),
                velocity: CGPoint(
                    x: CGFloat.random(in: -50...50),
                    y: CGFloat.random(in: 100...200)
                ),
                size: CGSize(
                    width: CGFloat.random(in: 8...16),
                    height: CGFloat.random(in: 8...16)
                ),
                color: confettiColors.randomElement() ?? .blue,
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -180...180)
            )
        }
        AppLogger.shared.debug("紙吹雪生成完了: \(confettiPieces.count)個")
    }
    
    private var confettiColors: [Color] {
        [
            .red, .blue, .green, .yellow, .orange, .pink, .purple,
            Color(red: 1.0, green: 0.8, blue: 0.0), // ゴールド
            Color(red: 0.0, green: 0.8, blue: 1.0), // シアン
            Color(red: 1.0, green: 0.4, blue: 0.8)  // マゼンタ
            ]
    }
}

/// 紙吹雪の個別ピース
private struct ConfettiPiece {
    let id: UUID
    let position: CGPoint
    let velocity: CGPoint
    let size: CGSize
    let color: Color
    let rotation: Double
    let rotationSpeed: Double
}

// UIScreen.main.bounds の代替として固定値を使用（テスト環境対応）
private extension ConfettiAnimation {
    var screenWidth: CGFloat {
        #if targetEnvironment(simulator) || DEBUG
        return 400 // テスト/シミュレーター環境での固定値
        #else
        return UIScreen.main.bounds.width
        #endif
    }
}