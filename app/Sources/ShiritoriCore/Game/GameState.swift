import Foundation
import Combine

/// ゲーム実行時の状態管理クラス
@Observable
public final class GameState {
    public let gameData: GameSetupData
    public private(set) var currentTurnIndex: Int = 0
    public private(set) var isGameActive: Bool = true
    public private(set) var usedWords: [String] = []
    public private(set) var timeRemaining: Int
    public private(set) var eliminatedPlayers: Set<String> = []
    public private(set) var eliminationHistory: [(playerId: String, reason: String, order: Int)] = []
    public private(set) var winner: GameParticipant?
    
    private let ruleEngine: ShiritoriRuleEngine
    private let dictionaryService: WordDictionaryService
    private var timer: Timer?
    
    public init(gameData: GameSetupData) {
        AppLogger.shared.info("GameState初期化開始: 参加者\(gameData.participants.count)人, 制限時間\(gameData.rules.timeLimit)秒")
        
        AppLogger.shared.debug("GameSetupData検証開始")
        guard !gameData.participants.isEmpty else {
            AppLogger.shared.error("参加者が空です")
            fatalError("参加者が空です")
        }
        
        guard gameData.rules.timeLimit >= 0 else {
            AppLogger.shared.error("制限時間が不正です: \(gameData.rules.timeLimit)")
            fatalError("制限時間が不正です")
        }
        
        AppLogger.shared.debug("GameSetupData検証完了")
        
        self.gameData = gameData
        self.timeRemaining = gameData.rules.timeLimit
        
        AppLogger.shared.debug("ShiritoriRuleEngine初期化開始")
        self.ruleEngine = ShiritoriRuleEngine()
        AppLogger.shared.debug("ShiritoriRuleEngine初期化完了")
        
        AppLogger.shared.debug("WordDictionaryService初期化開始")
        self.dictionaryService = WordDictionaryService()
        AppLogger.shared.debug("WordDictionaryService初期化完了")
        
        AppLogger.shared.info("GameState初期化完了")
    }
    
    deinit {
        stopTimer()
    }
    
    // MARK: - Public Methods
    
    public var currentParticipant: GameParticipant {
        AppLogger.shared.debug("currentParticipant取得開始")
        
        let activeParticipants = gameData.participants.filter { !eliminatedPlayers.contains($0.id) }
        AppLogger.shared.debug("currentParticipant: 全参加者=\(gameData.participants.count)人, アクティブ参加者=\(activeParticipants.count)人, currentTurnIndex=\(currentTurnIndex)")
        
        guard !activeParticipants.isEmpty else {
            AppLogger.shared.error("アクティブ参加者が0人です")
            // 最初の参加者を安全に返す
            guard let firstParticipant = gameData.participants.first else {
                AppLogger.shared.error("参加者が一人もいません")
                fatalError("参加者が一人もいません")
            }
            return firstParticipant
        }
        
        let index = currentTurnIndex % activeParticipants.count
        let participant = activeParticipants[index]
        AppLogger.shared.debug("現在のプレイヤー: \(participant.name) (インデックス=\(index), 参加者タイプ=\(participant.type.displayName))")
        return participant
    }
    
    public var lastWord: String? {
        usedWords.last
    }
    
    public func startGame() {
        AppLogger.shared.info("ゲーム開始: 参加者\(gameData.participants.count)人, isGameActive=\(isGameActive)")
        AppLogger.shared.debug("初期状態: currentTurnIndex=\(currentTurnIndex), eliminatedPlayers=\(eliminatedPlayers)")
        
        isGameActive = true
        startTimer()
        
        AppLogger.shared.info("ゲーム開始完了: isGameActive=\(isGameActive)")
        
        // 最初のプレイヤーがコンピュータの場合、自動でターンを開始
        let firstPlayer = currentParticipant
        if case .computer(let difficulty) = firstPlayer.type {
            AppLogger.shared.info("最初のプレイヤーがコンピュータ: \(firstPlayer.name) - 2秒後に開始")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.executeComputerTurn(difficulty: difficulty)
            }
        }
    }
    
    public func submitWord(_ word: String, by participantId: String) -> WordSubmissionResult {
        AppLogger.shared.info("単語提出: '\(word)' by \(participantId)")
        
        guard isGameActive else {
            AppLogger.shared.warning("非アクティブなゲームへの単語提出")
            return .gameNotActive
        }
        
        guard currentParticipant.id == participantId else {
            AppLogger.shared.warning("順番違いの単語提出: \(participantId)")
            return .wrongTurn
        }
        
        // 単語の基本バリデーション
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedWord.isEmpty else {
            AppLogger.shared.warning("空の単語提出")
            return .invalidWord("単語を入力してください")
        }
        
        // しりとりルールチェック
        let allWords = usedWords + [trimmedWord]
        let validationResult = ruleEngine.validateShiritoriChain(allWords)
        
        if validationResult.isValid {
            acceptWord(trimmedWord)
            moveToNextTurn()
            return .accepted
        } else {
            switch validationResult.errorType {
            case .invalidConnection:
                return .invalidWord("つながらない単語です")
                
            case .endsWithN:
                eliminateCurrentPlayer(reason: "「ん」で終わる単語")
                return .eliminated("「ん」で終わる単語は負けです")
                
            case .duplicateWord:
                return .duplicateWord("その単語はもう使われています")
                
            case .emptyWord:
                return .invalidWord("単語を入力してください")
                
            default:
                return .invalidWord(validationResult.errorMessage ?? "無効な単語です")
            }
        }
    }
    
    public func skipTurn(reason: String) {
        AppLogger.shared.info("ターンスキップ: \(reason)")
        eliminateCurrentPlayer(reason: reason)
    }
    
    public func pauseGame() {
        AppLogger.shared.info("ゲーム一時停止")
        stopTimer()
    }
    
    public func resumeGame() {
        AppLogger.shared.info("ゲーム再開")
        startTimer()
    }
    
    public func endGame() {
        AppLogger.shared.info("ゲーム終了")
        isGameActive = false
        stopTimer()
    }
    
    // MARK: - Private Methods
    
    private func acceptWord(_ word: String) {
        usedWords.append(word)
        resetTimer()
        AppLogger.shared.debug("単語受理: '\(word)' (総単語数: \(usedWords.count))")
    }
    
    private func moveToNextTurn() {
        currentTurnIndex += 1
        AppLogger.shared.debug("次のターン: インデックス\(currentTurnIndex)")
        
        // 現在のプレイヤーを取得してログ出力
        let participant = currentParticipant
        AppLogger.shared.info("ターン移行: \(participant.name) (\(participant.type.displayName))")
        
        // コンピュータターンの場合は自動実行
        if case .computer(let difficulty) = participant.type {
            AppLogger.shared.info("コンピュータターン開始: \(difficulty) - 1秒後に実行")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.executeComputerTurn(difficulty: difficulty)
            }
        }
    }
    
    private func eliminateCurrentPlayer(reason: String) {
        let player = currentParticipant
        eliminatedPlayers.insert(player.id)
        
        // 脱落履歴に記録（脱落順は現在の脱落者数+1）
        let eliminationOrder = eliminationHistory.count + 1
        eliminationHistory.append((playerId: player.id, reason: reason, order: eliminationOrder))
        
        AppLogger.shared.warning("プレイヤー脱落: \(player.name) - \(reason) (脱落順: \(eliminationOrder))")
        
        checkGameEnd()
        if isGameActive {
            moveToNextTurn()
        }
    }
    
    private func checkGameEnd() {
        let activeParticipants = gameData.participants.filter { !eliminatedPlayers.contains($0.id) }
        AppLogger.shared.debug("checkGameEnd: 全参加者=\(gameData.participants.count)人, アクティブ=\(activeParticipants.count)人, 脱落=\(eliminatedPlayers.count)人")
        AppLogger.shared.debug("勝利条件: \(gameData.rules.winCondition), 最大プレイヤー数: \(gameData.rules.maxPlayers)")
        
        if activeParticipants.count <= 1 {
            // 最後の一人または全員脱落
            winner = activeParticipants.first
            AppLogger.shared.warning("ゲーム終了判定: 最後の一人/全員脱落 - 勝者=\(winner?.name ?? "なし")")
            endGame()
        } else if gameData.rules.winCondition == .firstToEliminate && !eliminatedPlayers.isEmpty {
            // 一人脱落で終了
            winner = activeParticipants.first
            AppLogger.shared.warning("ゲーム終了判定: 一人脱落ルール - 勝者=\(winner?.name ?? "なし")")
            endGame()
        } else {
            AppLogger.shared.debug("ゲーム継続: アクティブ参加者\(activeParticipants.count)人でゲーム続行")
        }
    }
    
    private func executeComputerTurn(difficulty: DifficultyLevel) {
        guard isGameActive else { return }
        
        AppLogger.shared.debug("コンピュータターン実行: 難易度=\(difficulty)")
        
        let lastChar = lastWord?.last.map(String.init) ?? "あ"
        
        if let computerWord = dictionaryService.getRandomWord(startingWith: lastChar, difficulty: difficulty),
           !usedWords.contains(computerWord) {
            let result = submitWord(computerWord, by: currentParticipant.id)
            AppLogger.shared.info("コンピュータ単語: '\(computerWord)' -> \(result)")
        } else {
            AppLogger.shared.warning("コンピュータが単語を見つけられませんでした")
            skipTurn(reason: "単語が見つからない")
        }
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        guard gameData.rules.timeLimit > 0 else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateTimer()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        timeRemaining = gameData.rules.timeLimit
    }
    
    private func updateTimer() {
        guard timeRemaining > 0 else {
            AppLogger.shared.warning("時間切れ")
            skipTurn(reason: "時間切れ")
            return
        }
        
        timeRemaining -= 1
    }
}

/// 単語提出結果
public enum WordSubmissionResult {
    case accepted
    case eliminated(String)
    case duplicateWord(String)
    case invalidWord(String)
    case wrongTurn
    case gameNotActive
}