import Foundation

/// プレイヤーランキング情報
public struct PlayerRanking: Hashable {
    public let participant: GameParticipant
    public let wordsContributed: Int
    public let rank: Int
    public let eliminationOrder: Int? // 脱落順（1が最初、nilは脱落していない）
    public let eliminationReason: String? // 脱落理由
    public let isWinner: Bool // 勝者かどうか
    
    public init(
        participant: GameParticipant, 
        wordsContributed: Int, 
        rank: Int,
        eliminationOrder: Int? = nil,
        eliminationReason: String? = nil,
        isWinner: Bool = false
    ) {
        AppLogger.shared.debug("PlayerRanking初期化: \(participant.name), 単語数=\(wordsContributed), 順位=\(rank), 脱落順=\(eliminationOrder?.description ?? "なし"), 理由=\(eliminationReason ?? "なし")")
        self.participant = participant
        self.wordsContributed = wordsContributed
        self.rank = rank
        self.eliminationOrder = eliminationOrder
        self.eliminationReason = eliminationReason
        self.isWinner = isWinner
    }
}

/// ゲーム統計情報
public struct GameStats: Hashable {
    public let totalWords: Int
    public let gameDuration: Int // 秒数
    public let averageWordTime: Double // 1単語あたりの平均時間
    public let longestWord: String?
    public let uniqueStartingCharacters: Int
    
    public init(
        totalWords: Int,
        gameDuration: Int,
        averageWordTime: Double,
        longestWord: String? = nil,
        uniqueStartingCharacters: Int = 0
    ) {
        AppLogger.shared.debug("GameStats初期化: 総単語数=\(totalWords), ゲーム時間=\(gameDuration)秒")
        self.totalWords = totalWords
        self.gameDuration = gameDuration
        self.averageWordTime = averageWordTime
        self.longestWord = longestWord
        self.uniqueStartingCharacters = uniqueStartingCharacters
    }
}

/// ゲーム結果データ
public struct GameResultsData: Hashable {
    public let winner: GameParticipant?
    public let rankings: [PlayerRanking]
    public let gameStats: GameStats
    public let usedWords: [String]
    public let gameData: GameSetupData
    
    public init(
        winner: GameParticipant?,
        rankings: [PlayerRanking],
        gameStats: GameStats,
        usedWords: [String],
        gameData: GameSetupData
    ) {
        AppLogger.shared.info("ゲーム結果データ作成: 勝者=\(winner?.name ?? "なし"), 参加者\(rankings.count)人")
        self.winner = winner
        self.rankings = rankings
        self.gameStats = gameStats
        self.usedWords = usedWords
        self.gameData = gameData
    }
}