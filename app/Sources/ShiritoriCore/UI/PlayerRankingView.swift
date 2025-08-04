import SwiftUI

/// プレイヤーランキング表示コンポーネント
public struct PlayerRankingView: View {
    public let rankings: [PlayerRanking]
    
    public init(rankings: [PlayerRanking]) {
        AppLogger.shared.debug("PlayerRankingView初期化: \(rankings.count)人のランキング")
        self.rankings = rankings
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            if rankings.isEmpty {
                emptyState
            } else {
                ForEach(Array(rankings.enumerated()), id: \.offset) { index, ranking in
                    RankingCard(ranking: ranking, isTopRank: index == 0)
                        .transition(.asymmetric(
                            insertion: .slide.combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.1))
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3")
                .font(.largeTitle)
                .foregroundColor(.gray.opacity(0.5))
            
            Text("ランキングデータがありません")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(height: 80)
    }
}

/// ランキングカードコンポーネント
private struct RankingCard: View {
    let ranking: PlayerRanking
    let isTopRank: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var adaptiveCardBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color.white
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 順位表示
            rankBadge
            
            // プレイヤー情報
            HStack(spacing: 12) {
                PlayerAvatarView(
                    playerName: ranking.participant.name,
                    imageData: nil,
                    size: 40
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(ranking.participant.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(ranking.participant.type.displayName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 統計情報
                VStack(alignment: .trailing, spacing: 4) {
                    // 単語数
                    Text("\(ranking.wordsContributed)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(isTopRank ? .orange : .blue)
                    
                    Text("たんご")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // 脱落情報
                    if let eliminationOrder = ranking.eliminationOrder {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("脱落順: \(eliminationOrder)番目")
                                .font(.caption2)
                                .foregroundColor(.red)
                                .fontWeight(.semibold)
                            
                            if let reason = ranking.eliminationReason {
                                Text(reason)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    } else if ranking.isWinner {
                        Text("🏆 勝者")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .fontWeight(.bold)
                    } else {
                        Text("完走")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isTopRank ? Color.yellow.opacity(0.2) : adaptiveCardBackgroundColor)
                .stroke(isTopRank ? Color.orange : Color.gray.opacity(0.3), lineWidth: isTopRank ? 2 : 1)
                .shadow(color: .gray.opacity(0.2), radius: isTopRank ? 4 : 2, x: 0, y: 2)
        )
    }
    
    private var rankBadge: some View {
        ZStack {
            Circle()
                .fill(rankColor)
                .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                .frame(width: 40, height: 40)
            
            Group {
                if ranking.rank <= 3 {
                    Text(rankEmoji)
                        .font(.title2)
                } else {
                    Text("\(ranking.rank)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var rankColor: Color {
        switch ranking.rank {
        case 1:
            return .yellow
        case 2:
            return Color(red: 0.7, green: 0.7, blue: 0.7) // シルバー
        case 3:
            return Color(red: 0.8, green: 0.5, blue: 0.2) // ブロンズ
        default:
            return .blue
        }
    }
    
    private var rankEmoji: String {
        switch ranking.rank {
        case 1:
            return "🥇"
        case 2:
            return "🥈"
        case 3:
            return "🥉"
        default:
            return ""
        }
    }
}