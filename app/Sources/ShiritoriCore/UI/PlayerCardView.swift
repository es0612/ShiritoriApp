import SwiftUI

/// 個別プレイヤー情報を表示するカードコンポーネント
public struct PlayerCardView: View {
    public let playerName: String
    public let gamesPlayed: Int
    public let gamesWon: Int
    private let onEdit: () -> Void
    private let onDelete: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    public init(
        playerName: String,
        gamesPlayed: Int,
        gamesWon: Int,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        AppLogger.shared.debug("PlayerCardView初期化: プレイヤー=\(playerName)")
        self.playerName = playerName
        self.gamesPlayed = gamesPlayed
        self.gamesWon = gamesWon
        self.onEdit = onEdit
        self.onDelete = onDelete
    }
    
    // 適応的な背景色プロパティ
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color.white
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // プレイヤーアバター
                PlayerAvatarView(
                    playerName: playerName,
                    imageData: nil,
                    size: 80
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(playerName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    PlayerStatsDisplay(
                        gamesPlayed: gamesPlayed,
                        gamesWon: gamesWon,
                        winRate: calculateWinRate()
                    )
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Button(action: {
                        AppLogger.shared.info("プレイヤー編集: \(playerName)")
                        onEdit()
                    }) {
                        Image(systemName: "pencil")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(22)
                    }
                    
                    Button(action: {
                        AppLogger.shared.warning("プレイヤー削除: \(playerName)")
                        onDelete()
                    }) {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundColor(.red)
                            .frame(width: 44, height: 44)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(22)
                    }
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBackgroundColor)
                .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 4)
    }
    
    private func calculateWinRate() -> Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(gamesWon) / Double(gamesPlayed)
    }
}