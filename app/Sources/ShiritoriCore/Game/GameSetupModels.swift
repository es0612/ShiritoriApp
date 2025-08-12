import Foundation
import SwiftUI

/// ゲーム勝利条件
public enum WinCondition: String, CaseIterable, Hashable, Codable {
    case lastPlayerStanding = "最後の一人"
    case firstToEliminate = "一人脱落で終了"
    
    public var description: String {
        switch self {
        case .lastPlayerStanding:
            return "最後の一人になるまでゲーム継続"
        case .firstToEliminate:
            return "一人脱落したらゲーム終了（短時間向け）"
        }
    }
    
    /// 具体的なシナリオ例を含む詳細説明
    public var detailedDescription: String {
        switch self {
        case .lastPlayerStanding:
            return "3人で開始 → 1人脱落 → 2人で継続 → さらに1人脱落 → 最後の1人が勝利"
        case .firstToEliminate:
            return "3人で開始 → 1人脱落 → 残り2人の内1人が勝利してゲーム終了"
        }
    }
    
    /// 参加者数に基づく推奨度を返す
    public func recommendationLevel(for participantCount: Int) -> RecommendationLevel {
        switch self {
        case .lastPlayerStanding:
            // 3人以上では強く推奨
            return participantCount >= 3 ? .highlyRecommended : .recommended
        case .firstToEliminate:
            // 2人ゲームや短時間ゲーム向け
            return participantCount == 2 ? .recommended : .optional
        }
    }
    
    public var emoji: String {
        switch self {
        case .lastPlayerStanding:
            return "👑"
        case .firstToEliminate:
            return "⏰"
        }
    }
}

/// 推奨度レベル
public enum RecommendationLevel {
    case highlyRecommended  // 強く推奨
    case recommended        // 推奨
    case optional          // オプション
    
    public var displayText: String {
        switch self {
        case .highlyRecommended:
            return "おすすめ！"
        case .recommended:
            return "おすすめ"
        case .optional:
            return ""
        }
    }
    
    public var color: Color {
        switch self {
        case .highlyRecommended:
            return .green
        case .recommended:
            return .blue
        case .optional:
            return .gray
        }
    }
}

/// ゲームルール設定
public struct GameRulesConfig: Hashable, Codable {
    public let timeLimit: Int // 秒数
    public let maxPlayers: Int
    public let winCondition: WinCondition
    
    public init(
        timeLimit: Int = 60,
        maxPlayers: Int = 5,
        winCondition: WinCondition = .lastPlayerStanding
    ) {
        AppLogger.shared.debug("GameRulesConfig初期化: 制限時間=\(timeLimit)秒, 最大プレイヤー=\(maxPlayers), 勝利条件=\(winCondition.rawValue)")
        self.timeLimit = timeLimit
        self.maxPlayers = maxPlayers
        self.winCondition = winCondition
    }
}

/// ゲーム参加者の情報
public struct GameParticipant: Hashable, Identifiable, Codable {
    public let id: String
    public let name: String
    public let type: ParticipantType
    
    public init(id: String, name: String, type: ParticipantType) {
        self.id = id
        self.name = name
        self.type = type
    }
}

/// 参加者タイプ
public enum ParticipantType: Hashable, Codable {
    case human
    case computer(difficulty: DifficultyLevel)
    
    public var displayName: String {
        switch self {
        case .human:
            return "プレイヤー"
        case .computer(let difficulty):
            return "コンピュータ(\(difficulty.displayName))"
        }
    }
}

/// ゲーム設定データ
public struct GameSetupData: Hashable, Codable {
    public let participants: [GameParticipant]
    public let rules: GameRulesConfig
    public let turnOrder: [String] // participant IDs in turn order
    
    public init(participants: [GameParticipant], rules: GameRulesConfig, turnOrder: [String]) {
        AppLogger.shared.info("ゲーム設定データ作成: 参加者\(participants.count)人, 制限時間\(rules.timeLimit)秒")
        self.participants = participants
        self.rules = rules
        self.turnOrder = turnOrder
    }
}