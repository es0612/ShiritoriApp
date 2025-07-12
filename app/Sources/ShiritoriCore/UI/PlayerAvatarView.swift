import SwiftUI

/// プレイヤーのアバター表示用コンポーネント
public struct PlayerAvatarView: View {
    public let playerName: String
    public let imageData: Data?
    public let size: CGFloat
    
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
    
    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: size, height: size)
                
                // デフォルトアバター（プレイヤー名の頭文字）
                Text(String(playerName.prefix(1)))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            .overlay(
                Circle()
                    .stroke(Color.blue, lineWidth: 3)
            )
            
            Text(playerName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
}