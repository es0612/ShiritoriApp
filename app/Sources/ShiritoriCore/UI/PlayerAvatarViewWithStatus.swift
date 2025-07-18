import SwiftUI

/// プレイヤーの状況を表す列挙型
public enum PlayerAvatarStatus {
    case normal
    case currentTurn
    case eliminated
}

/// 状態に応じて表示が変化するプレイヤーアバター表示用コンポーネント
public struct PlayerAvatarViewWithStatus: View {
    public let playerName: String
    public let imageData: Data?
    public let size: CGFloat
    public let status: PlayerAvatarStatus
    @Environment(\.colorScheme) private var colorScheme
    
    public init(
        playerName: String,
        imageData: Data?,
        size: CGFloat = 60,
        status: PlayerAvatarStatus = .normal
    ) {
        AppLogger.shared.debug("PlayerAvatarViewWithStatus初期化: プレイヤー=\(playerName), サイズ=\(size), 状態=\(status)")
        self.playerName = playerName
        self.imageData = imageData
        self.size = size
        self.status = status
    }
    
    // 状態に応じた色プロパティ
    private var avatarBackgroundColor: Color {
        switch status {
        case .normal:
            return colorScheme == .dark ? Color.blue.opacity(0.4) : Color.blue.opacity(0.2)
        case .currentTurn:
            return colorScheme == .dark ? Color.orange.opacity(0.6) : Color.orange.opacity(0.3)
        case .eliminated:
            return colorScheme == .dark ? Color.gray.opacity(0.4) : Color.gray.opacity(0.3)
        }
    }
    
    private var avatarTextColor: Color {
        switch status {
        case .normal:
            return colorScheme == .dark ? Color.white : Color.blue
        case .currentTurn:
            return colorScheme == .dark ? Color.white : Color.orange
        case .eliminated:
            return colorScheme == .dark ? Color.gray : Color.gray
        }
    }
    
    private var avatarStrokeColor: Color {
        switch status {
        case .normal:
            return colorScheme == .dark ? Color.blue.opacity(0.8) : Color.blue
        case .currentTurn:
            return Color.orange
        case .eliminated:
            return Color.red
        }
    }
    
    private var strokeLineWidth: CGFloat {
        switch status {
        case .normal:
            return 2
        case .currentTurn:
            return 4
        case .eliminated:
            return 3
        }
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // 統合された円（背景とストロークを組み合わせ）
                Circle()
                    .fill(avatarBackgroundColor)
                    .strokeBorder(avatarStrokeColor, lineWidth: strokeLineWidth)
                    .frame(width: size, height: size)
                    .scaleEffect(status == .currentTurn ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: status)
                
                // 脱落プレイヤーにX印をオーバーレイ
                if status == .eliminated {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: size * 0.4))
                        .foregroundColor(.red)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: size * 0.4, height: size * 0.4)
                        )
                } else {
                    // デフォルトアバター（プレイヤー名の頭文字）
                    Text(String(playerName.prefix(1)))
                        .font(.system(size: size * 0.3, weight: .bold))
                        .foregroundColor(avatarTextColor)
                }
            }
            .frame(width: size, height: size)
            
            Text(playerName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(status == .eliminated ? .gray : .primary)
                .lineLimit(1)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            PlayerAvatarViewWithStatus(
                playerName: "太郎",
                imageData: nil,
                size: 60,
                status: .normal
            )
            
            PlayerAvatarViewWithStatus(
                playerName: "花子",
                imageData: nil,
                size: 60,
                status: .currentTurn
            )
            
            PlayerAvatarViewWithStatus(
                playerName: "次郎",
                imageData: nil,
                size: 60,
                status: .eliminated
            )
        }
        
        // 異なるサイズでのテスト
        HStack(spacing: 20) {
            PlayerAvatarViewWithStatus(
                playerName: "小",
                imageData: nil,
                size: 40,
                status: .normal
            )
            
            PlayerAvatarViewWithStatus(
                playerName: "中",
                imageData: nil,
                size: 60,
                status: .currentTurn
            )
            
            PlayerAvatarViewWithStatus(
                playerName: "大",
                imageData: nil,
                size: 80,
                status: .eliminated
            )
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}