import SwiftUI

/// プレイヤー遷移時専用のアバター表示コンポーネント
/// 重なりのない単一円でエフェクトを統合し、レイアウト問題を解決
public struct TransitionPlayerAvatarView: View {
    public let player: GameParticipant
    public let size: CGFloat
    public let animationPhase: AnimationPhase
    @Environment(\.colorScheme) private var colorScheme
    
    public init(
        player: GameParticipant,
        size: CGFloat = 120,
        animationPhase: AnimationPhase = .showing
    ) {
        AppLogger.shared.debug("TransitionPlayerAvatarView初期化: プレイヤー=\(player.name), サイズ=\(size)")
        self.player = player
        self.size = size
        self.animationPhase = animationPhase
    }
    
    // MARK: - プレイヤータイプ別色定義
    
    private var playerTypeColor: Color {
        switch player.type {
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
    
    private var adaptiveBackgroundColor: Color {
        colorScheme == .dark ? playerTypeColor.opacity(0.3) : playerTypeColor.opacity(0.2)
    }
    
    private var adaptiveTextColor: Color {
        colorScheme == .dark ? Color.white : playerTypeColor
    }
    
    // MARK: - アニメーション設定
    
    private var borderWidth: CGFloat {
        switch animationPhase {
        case .highlighted:
            return 6
        default:
            return 4
        }
    }
    
    private var scaleEffect: CGFloat {
        switch animationPhase {
        case .highlighted:
            return 1.05
        default:
            return 1.0
        }
    }
    
    private var shadowRadius: CGFloat {
        switch animationPhase {
        case .highlighted:
            return 12
        default:
            return 8
        }
    }
    
    private var shadowY: CGFloat {
        switch animationPhase {
        case .highlighted:
            return 6
        default:
            return 4
        }
    }
    
    public var body: some View {
        ZStack {
            // 統合された単一円（フィル + ボーダー + エフェクト）
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            adaptiveBackgroundColor,
                            adaptiveBackgroundColor.opacity(0.8)
                        ],
                        center: .center,
                        startRadius: size * 0.1,
                        endRadius: size * 0.5
                    )
                )
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            playerTypeColor,
                            playerTypeColor.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: borderWidth
                )
                .frame(width: size, height: size)
                .scaleEffect(scaleEffect)
                .shadow(
                    color: playerTypeColor.opacity(0.4),
                    radius: shadowRadius,
                    x: 0,
                    y: shadowY
                )
            
            // プレイヤー名の頭文字
            Text(String(player.name.prefix(1)))
                .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                .foregroundColor(adaptiveTextColor)
        }
        .animation(.easeInOut(duration: 0.5), value: animationPhase)
        .animation(.easeInOut(duration: 0.5), value: scaleEffect)
        .animation(.easeInOut(duration: 0.5), value: borderWidth)
    }
}

/// アニメーションの段階を表す列挙型
public enum AnimationPhase: Equatable {
    case hidden     // 非表示
    case entering   // 登場中
    case highlighted // ハイライト中
    case showing    // 表示中
    case leaving    // 退場中
}

// MARK: - Preview

#Preview("Human Player") {
    TransitionPlayerAvatarView(
        player: GameParticipant(
            id: "1",
            name: "ひなま",
            type: .human
        ),
        animationPhase: .highlighted
    )
    .padding()
}

#Preview("Computer Easy") {
    TransitionPlayerAvatarView(
        player: GameParticipant(
            id: "2",
            name: "AI",
            type: .computer(difficulty: .easy)
        ),
        animationPhase: .showing
    )
    .padding()
}

#Preview("Computer Hard") {
    TransitionPlayerAvatarView(
        player: GameParticipant(
            id: "3",
            name: "AI",
            type: .computer(difficulty: .hard)
        ),
        animationPhase: .highlighted
    )
    .padding()
}