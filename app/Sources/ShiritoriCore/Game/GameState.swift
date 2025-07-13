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
    public private(set) var winner: GameParticipant?
    
    private let ruleEngine: ShiritoriRuleEngine
    private let dictionaryService: WordDictionaryService
    private var timer: Timer?
    
    public init(gameData: GameSetupData) {
        AppLogger.shared.info("ゲーム状態初期化: 参加者\(gameData.participants.count)人, 制限時間\(gameData.rules.timeLimit)秒")
        self.gameData = gameData
        self.timeRemaining = gameData.rules.timeLimit
        self.ruleEngine = ShiritoriRuleEngine()
        self.dictionaryService = WordDictionaryService()
    }
    
    deinit {
        stopTimer()
    }
    
    // MARK: - Public Methods
    
    public var currentParticipant: GameParticipant {
        let activeParticipants = gameData.participants.filter { !eliminatedPlayers.contains($0.id) }
        let index = currentTurnIndex % activeParticipants.count
        return activeParticipants[index]
    }
    
    public var lastWord: String? {
        usedWords.last
    }
    
    public func startGame() {
        AppLogger.shared.info("ゲーム開始")
        isGameActive = true
        startTimer()
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
                eliminateCurrentPlayer(reason: "つながらない単語")
                return .eliminated("つながらない単語です")
                
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
        
        // コンピュータターンの場合は自動実行
        if case .computer(let difficulty) = currentParticipant.type {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.executeComputerTurn(difficulty: difficulty)
            }
        }
    }
    
    private func eliminateCurrentPlayer(reason: String) {
        let player = currentParticipant
        eliminatedPlayers.insert(player.id)
        AppLogger.shared.warning("プレイヤー脱落: \(player.name) - \(reason)")
        
        checkGameEnd()
        if isGameActive {
            moveToNextTurn()
        }
    }
    
    private func checkGameEnd() {
        let activeParticipants = gameData.participants.filter { !eliminatedPlayers.contains($0.id) }
        
        if activeParticipants.count <= 1 {
            // 最後の一人または全員脱落
            winner = activeParticipants.first
            endGame()
            AppLogger.shared.info("ゲーム終了: 勝者=\(winner?.name ?? "なし")")
        } else if gameData.rules.winCondition == .firstToEliminate && !eliminatedPlayers.isEmpty {
            // 一人脱落で終了
            winner = activeParticipants.first
            endGame()
            AppLogger.shared.info("ゲーム終了(一人脱落ルール): 勝者=\(winner?.name ?? "なし")")
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