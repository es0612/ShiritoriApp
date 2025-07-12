import Foundation

/// ゲーム勝利条件
public enum WinCondition: String, CaseIterable {
    case lastPlayerStanding = "最後の一人"
    case firstToEliminate = "一人脱落で終了"
    
    public var description: String {
        switch self {
        case .lastPlayerStanding:
            return "最後の一人になるまで"
        case .firstToEliminate:
            return "一人脱落したら終了"
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

/// ゲームルール設定
public struct GameRulesConfig {
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
public struct GameParticipant {
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
public enum ParticipantType {
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
public struct GameSetupData {
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