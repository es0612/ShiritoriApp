import SwiftUI

/// メインゲーム画面
public struct MainGameView: View {
    public let gameData: GameSetupData
    private let onGameEnd: (GameParticipant?, [String], Int, [(playerId: String, reason: String, order: Int)]) -> Void
    private let onNavigateToResults: ((GameResultsData) -> Void)?
    
    @State private var gameState: GameState
    @State private var showPauseMenu = false
    @State private var inputText = ""
    @State private var showWordError = false
    @State private var errorMessage = ""
    @State private var showPlayerTransition = false
    @State private var previousPlayerId: String?
    // 結果画面用の状態変数は削除（ナビゲーション遷移に変更）
    @State private var gameStartTime: Date?
    
    public init(
        gameData: GameSetupData,
        onGameEnd: @escaping (GameParticipant?, [String], Int, [(playerId: String, reason: String, order: Int)]) -> Void,
        onNavigateToResults: ((GameResultsData) -> Void)? = nil
    ) {
        AppLogger.shared.debug("MainGameView初期化開始")
        AppLogger.shared.debug("参加者数: \(gameData.participants.count)")
        AppLogger.shared.debug("参加者詳細: \(gameData.participants.map { "\($0.name)(\($0.type.displayName))" }.joined(separator: ", "))")
        AppLogger.shared.debug("ルール設定: 制限時間=\(gameData.rules.timeLimit)秒, 勝利条件=\(gameData.rules.winCondition)")
        
        self.gameData = gameData
        self.onGameEnd = onGameEnd
        self.onNavigateToResults = onNavigateToResults
        
        AppLogger.shared.debug("GameState初期化前")
        let gameState = GameState(gameData: gameData)
        self._gameState = State(initialValue: gameState)
        AppLogger.shared.debug("GameState初期化成功")
        
        AppLogger.shared.debug("MainGameView初期化完了")
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                ChildFriendlyBackground(animationSpeed: 0.5)
                
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.standard) {
                        // プレイヤー状況表示バー（複数人プレイ時のみ）
                        if gameData.participants.count > 1 {
                            PlayerStatusBar(
                                participants: gameData.participants,
                                currentTurnIndex: gameState.currentTurnIndex,
                                eliminatedPlayers: gameState.eliminatedPlayers
                            )
                            .onAppear {
                                AppLogger.shared.debug("PlayerStatusBar表示完了")
                            }
                        }
                        
                        // ヘッダー: 現在のプレイヤーと時間
                        CurrentPlayerDisplay(
                            participant: gameState.activePlayer,
                            timeRemaining: gameState.timeRemaining
                        )
                        .onAppear {
                            AppLogger.shared.debug("CurrentPlayerDisplay表示完了")
                        }
                        
                        // 前の単語表示
                        WordDisplayCard(
                            word: gameState.lastWord,
                            isHighlighted: true
                        )
                        .onAppear {
                            AppLogger.shared.debug("WordDisplayCard表示完了")
                        }
                        
                        // 進行状況
                        GameProgressBar(
                            usedWordsCount: gameState.usedWords.count,
                            totalTurns: gameState.gameData.participants.count * 3 // 推定総ターン数
                        )
                        .onAppear {
                            AppLogger.shared.debug("GameProgressBar表示完了")
                        }
                        
                        // 動的スペーサー（小画面では小さく、大画面では大きく）
                        Spacer()
                            .frame(height: adaptiveSpacerHeight(for: geometry))
                        
                        // 入力エリア
                        Group {
                            if case .human = gameState.activePlayer.type {
                                WordInputView(
                                    isEnabled: gameState.isGameActive,
                                    onSubmit: { word in
                                        submitWord(word)
                                    }
                                )
                            } else {
                                ComputerThinkingView()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // 単語履歴
                        WordHistoryView(words: gameState.usedWords)
                            .frame(maxHeight: adaptiveHistoryHeight(for: geometry))
                    }
                    .safeAreaPadding()
                }
            }
        }
        .overlay {
            // プレイヤー遷移アニメーション
            if showPlayerTransition {
                PlayerTransitionView(
                    newPlayer: gameState.activePlayer,
                    isVisible: showPlayerTransition,
                    onAnimationComplete: {
                        showPlayerTransition = false
                    }
                )
                .zIndex(1)
            }
        }
        .navigationTitle("🎮 しりとり")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    AppLogger.shared.info("ポーズボタンタップ")
                    gameState.pauseGame()
                    showPauseMenu = true
                }) {
                    Image(systemName: "pause.circle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
                .accessibilityLabel("ゲームを一時停止")
            }
        }
        .onAppear {
            AppLogger.shared.info("MainGameView画面表示完了")
            AppLogger.shared.debug("gameState.startGame()を呼び出します")
            gameStartTime = Date()
            previousPlayerId = gameState.activePlayer.id
            gameState.startGame()
            AppLogger.shared.debug("ゲーム開始時刻を記録: \(gameStartTime!)")
        }
        .onChange(of: gameState.isGameActive) { _, isActive in
            if !isActive {
                handleGameEnd()
            }
        }
        .onChange(of: gameState.activePlayer.id) { _, newPlayerId in
            // 🔒 防御的実装: ゲーム終了後のプレイヤー変更は無視
            guard gameState.isGameActive else {
                AppLogger.shared.debug("ゲーム終了後のプレイヤー変更を無視: \(newPlayerId)")
                return
            }
            handlePlayerChange(newPlayerId: newPlayerId)
        }
        .alert("エラー", isPresented: $showWordError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showPauseMenu) {
            PauseMenuView(
                onResume: {
                    showPauseMenu = false
                    gameState.resumeGame()
                },
                onQuit: {
                    gameState.endGame()
                    prepareGameResults(winner: nil)
                    showGameResults = true
                }
            )
        }
    }
    
    private func submitWord(_ word: String) {
        let result = gameState.submitWord(word, by: gameState.activePlayer.id)
        
        switch result {
        case .accepted:
            inputText = ""
            
        case .eliminated(let reason):
            showError(reason)
            
        case .duplicateWord(let message):
            showError(message)
            
        case .invalidWord(let message):
            showError(message)
            
        case .wrongTurn:
            showError("あなたの番ではありません")
            
        case .gameNotActive:
            showError("ゲームが終了しています")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showWordError = true
        AppLogger.shared.warning("ゲームエラー表示: \(message)")
    }
    
    private func handleGameEnd() {
        AppLogger.shared.info("ゲーム終了処理: 勝者=\(gameState.winner?.name ?? "なし")")
        
        // ゲーム結果データを作成
        let winner = gameState.winner
        let usedWords = gameState.usedWords
        let gameDuration = calculateGameDuration()
        let eliminationHistory = gameState.eliminationHistory
        
        // 既存のコールバック呼び出し（互換性維持）
        onGameEnd(winner, usedWords, gameDuration, eliminationHistory)
        
        // ナビゲーション用の結果データを作成して遷移
        if let navigateToResults = onNavigateToResults {
            let gameStats = GameStats(
                totalWords: usedWords.count,
                gameDuration: gameDuration,
                averageWordTime: calculateAverageWordTime(),
                longestWord: usedWords.max(by: { $0.count < $1.count }),
                uniqueStartingCharacters: Set(usedWords.compactMap { $0.first }).count
            )
            
            let rankings = generateRankings(winner: winner, eliminationHistory: eliminationHistory)
            
            let resultsData = GameResultsData(
                winner: winner,
                rankings: rankings,
                gameStats: gameStats,
                usedWords: usedWords,
                gameData: gameData
            )
            
            AppLogger.shared.debug("ナビゲーション遷移: 結果画面へ")
            navigateToResults(resultsData)
        }
    }
    
    
    private func calculateGameDuration() -> Int {
        guard let startTime = gameStartTime else {
            AppLogger.shared.warning("ゲーム開始時刻が記録されていません - フォールバック計算を使用")
            return gameState.usedWords.count * 10 // フォールバック: 1単語あたり10秒と仮定
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        let durationInSeconds = Int(duration)
        
        AppLogger.shared.info("ゲーム実際の経過時間: \(String(format: "%.2f", duration))秒 (\(durationInSeconds)秒)")
        AppLogger.shared.debug("開始時刻: \(startTime), 終了時刻: \(endTime)")
        
        return durationInSeconds
    }
    
    private func calculateAverageWordTime() -> Double {
        guard gameState.usedWords.count > 0 else { return 0.0 }
        return Double(calculateGameDuration()) / Double(gameState.usedWords.count)
    }
    
    private func generateRankings(winner: GameParticipant?, eliminationHistory: [(playerId: String, reason: String, order: Int)]) -> [PlayerRanking] {
        var rankings: [PlayerRanking] = []
        
        for (index, participant) in gameData.participants.enumerated() {
            // 各プレイヤーの貢献単語数を計算（簡易版）
            let wordsCount = max(1, gameState.usedWords.count / gameData.participants.count)
            
            // 脱落情報を検索
            let eliminationInfo = eliminationHistory.first { $0.playerId == participant.id }
            let eliminationOrder = eliminationInfo?.order
            let eliminationReason = eliminationInfo?.reason
            
            // 勝者判定
            let isWinner = winner?.id == participant.id
            
            // ランク計算：勝者が1位、脱落順によって順位を決定
            let rank: Int
            if isWinner {
                rank = 1
            } else if let elimOrder = eliminationOrder {
                // 脱落順に基づいて順位決定（最後に脱落した人が最高順位）
                rank = gameData.participants.count - elimOrder + 1
            } else {
                // 脱落していない場合（引き分けなど）
                rank = index + 1
            }
            
            let ranking = PlayerRanking(
                participant: participant,
                wordsContributed: wordsCount,
                rank: rank,
                eliminationOrder: eliminationOrder,
                eliminationReason: eliminationReason,
                isWinner: isWinner
            )
            
            rankings.append(ranking)
        }
        
        // ランクでソート（1位が最初）
        return rankings.sorted { $0.rank < $1.rank }
    }
    
    /// プレイヤー変更時の処理
    private func handlePlayerChange(newPlayerId: String) {
        // 🔒 防御的実装: ゲーム終了後は一切の処理をスキップ
        guard gameState.isGameActive else {
            AppLogger.shared.debug("ゲーム終了状態のためプレイヤー変更処理をスキップ: \(newPlayerId)")
            return
        }
        
        // 前回のプレイヤーIDと異なる場合のみアニメーション実行
        guard let previousId = previousPlayerId, previousId != newPlayerId else {
            previousPlayerId = newPlayerId
            return
        }
        
        AppLogger.shared.info("プレイヤー変更検出: \(previousId) -> \(newPlayerId)")
        previousPlayerId = newPlayerId
        
        // 複数人プレイ時のみ遷移アニメーションを表示
        if gameData.participants.count > 1 {
            showPlayerTransition = true
        }
    }
    
    /// 画面サイズに応じた動的スペーサーの高さを計算
    private func adaptiveSpacerHeight(for geometry: GeometryProxy) -> CGFloat {
        let screenHeight = geometry.size.height
        
        // iPhone SE (568pt) などの小さな画面では最小限のスペース
        if screenHeight < 600 {
            return DesignSystem.Spacing.small
        }
        // iPhone (667pt-736pt) などの標準的な画面では適度なスペース
        else if screenHeight < 800 {
            return DesignSystem.Spacing.standard
        }
        // iPhone Pro Max (926pt) やiPad などの大きな画面ではゆとりのあるスペース
        else {
            return DesignSystem.Spacing.large
        }
    }
    
    /// 画面サイズに応じた単語履歴表示エリアの最大高さを計算
    private func adaptiveHistoryHeight(for geometry: GeometryProxy) -> CGFloat {
        let screenHeight = geometry.size.height
        
        // 小さな画面では画面の25%
        if screenHeight < 600 {
            return screenHeight * 0.25
        }
        // 標準的な画面では画面の30%
        else if screenHeight < 800 {
            return screenHeight * 0.30
        }
        // 大きな画面では画面の35%（ただし最大300pt）
        else {
            return min(screenHeight * 0.35, 300)
        }
    }
}