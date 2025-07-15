import SwiftUI

/// プレイヤーのアバター表示用コンポーネント
public struct PlayerAvatarView: View {
    public let playerName: String
    public let imageData: Data?
    public let size: CGFloat
    @Environment(\.colorScheme) private var colorScheme
    
    public init(
        playerName: String,
        imageData: Data?,
        size: CGFloat = 60
    ) {
        AppLogger.shared.debug("PlayerAvatarView初期化: プレイヤー=\(playerName), サイズ=\(size)")
        self.playerName = playerName
        self.imageData = imageData
        self.size = size
    }
    
    // 適応的なアバター色プロパティ
    private var avatarBackgroundColor: Color {
        colorScheme == .dark ? Color.blue.opacity(0.4) : Color.blue.opacity(0.2)
    }
    
    private var avatarTextColor: Color {
        colorScheme == .dark ? Color.white : Color.blue
    }
    
    private var avatarStrokeColor: Color {
        colorScheme == .dark ? Color.blue.opacity(0.8) : Color.blue
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(avatarBackgroundColor)
                    .frame(width: size, height: size)
                
                // デフォルトアバター（プレイヤー名の頭文字）
                Text(String(playerName.prefix(1)))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(avatarTextColor)
            }
            .overlay(
                Circle()
                    .stroke(avatarStrokeColor, lineWidth: 3)
            )
            
            Text(playerName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
}