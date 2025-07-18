import SwiftUI

/// 勝者専用の特別なアバター表示コンポーネント（金色のリングアニメーション付き）
public struct WinnerAvatarView: View {
    public let playerName: String
    public let imageData: Data?
    public let size: CGFloat
    public let pulseScale: CGFloat
    @Environment(\.colorScheme) private var colorScheme
    
    public init(
        playerName: String,
        imageData: Data?,
        size: CGFloat = 60,
        pulseScale: CGFloat = 1.0
    ) {
        AppLogger.shared.debug("WinnerAvatarView初期化: プレイヤー=\(playerName), サイズ=\(size)")
        self.playerName = playerName
        self.imageData = imageData
        self.size = size
        self.pulseScale = pulseScale
    }
    
    // 勝者用の特別な色プロパティ
    private var avatarBackgroundColor: LinearGradient {
        LinearGradient(
            colors: [
                .yellow.opacity(colorScheme == .dark ? 0.7 : 0.8),
                .orange.opacity(colorScheme == .dark ? 0.5 : 0.6)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var avatarTextColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    private var winnerRingGradient: LinearGradient {
        LinearGradient(
            colors: [.yellow, .orange, .yellow],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // 統合された勝者円（背景とアニメーションリング）
                Circle()
                    .fill(avatarBackgroundColor)
                    .strokeBorder(winnerRingGradient, lineWidth: 6)
                    .frame(width: size, height: size)
                    .scaleEffect(pulseScale)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseScale)
                
                // デフォルトアバター（プレイヤー名の頭文字）
                Text(String(playerName.prefix(1)))
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundColor(avatarTextColor)
                
                // 王冠アイコン
                Image(systemName: "crown.fill")
                    .font(.system(size: size * 0.2))
                    .foregroundColor(.yellow)
                    .offset(x: 0, y: -size * 0.15)
                    .rotationEffect(.degrees(-15))
            }
            .frame(width: size, height: size)
            
            Text(playerName)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(winnerRingGradient)
                .lineLimit(1)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        WinnerAvatarView(
            playerName: "勝者",
            imageData: nil,
            size: 140,
            pulseScale: 1.1
        )
        
        WinnerAvatarView(
            playerName: "チャンピオン",
            imageData: nil,
            size: 100,
            pulseScale: 1.0
        )
        
        WinnerAvatarView(
            playerName: "優勝者",
            imageData: nil,
            size: 80,
            pulseScale: 0.9
        )
    }
    .padding()
    .background(Color.purple.opacity(0.1))
}