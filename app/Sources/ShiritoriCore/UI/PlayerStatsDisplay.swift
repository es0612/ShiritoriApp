import SwiftUI

/// プレイヤーの統計情報を表示するコンポーネント
public struct PlayerStatsDisplay: View {
    public let gamesPlayed: Int
    public let gamesWon: Int
    public let winRate: Double
    
    public init(
        gamesPlayed: Int,
        gamesWon: Int,
        winRate: Double
    ) {
        AppLogger.shared.debug("PlayerStatsDisplay初期化: \(gamesPlayed)戦\(gamesWon)勝")
        self.gamesPlayed = gamesPlayed
        self.gamesWon = gamesWon
        self.winRate = winRate
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                StatsItem(
                    icon: "gamecontroller.fill",
                    label: "ゲーム数",
                    value: "\(gamesPlayed)",
                    color: .blue
                )
                
                StatsItem(
                    icon: "crown.fill",
                    label: "勝利数",
                    value: "\(gamesWon)",
                    color: .orange
                )
            }
            
            HStack(spacing: 8) {
                Image(systemName: "percent")
                    .font(.caption2)
                    .foregroundColor(.green)
                
                Text("勝率: \(Int(winRate * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                
                Spacer()
                
                // 勝率バー
                ProgressView(value: winRate)
                    .frame(width: 60)
                    .tint(.green)
            }
        }
    }
}

/// 統計項目の表示コンポーネント
private struct StatsItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}