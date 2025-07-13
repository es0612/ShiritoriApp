import SwiftUI

/// 紙吹雪アニメーションコンポーネント
public struct ConfettiAnimation: View {
    public let isActive: Bool
    
    @State private var animationPhase = 0.0
    @State private var confettiPieces: [ConfettiPiece] = []
    
    public init(isActive: Bool) {
        AppLogger.shared.debug("ConfettiAnimation初期化: アクティブ=\(isActive)")
        self.isActive = isActive
    }
    
    public var body: some View {
        ZStack {
            if isActive {
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
                generateConfetti()
                startAnimation()
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                generateConfetti()
                startAnimation()
            } else {
                confettiPieces.removeAll()
            }
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
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 3.0)) {
            animationPhase = 1.0
        }
        
        // アニメーション終了後にクリーンアップ
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            confettiPieces.removeAll()
            animationPhase = 0.0
        }
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