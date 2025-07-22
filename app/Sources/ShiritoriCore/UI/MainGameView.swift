import SwiftUI

/// メインゲーム画面
public struct MainGameView: View {
    public let gameData: GameSetupData
    private let onGameEnd: (GameParticipant?, [String], Int, [(playerId: String, reason: String, order: Int)]) -> Void
    
    @State private var gameState: GameState
    @State private var showPauseMenu = false
    @State private var inputText = ""
    @State private var showWordError = false
    @State private var errorMessage = ""
    @State private var showPlayerTransition = false
    @State private var previousPlayerId: String?
    @State private var showGameResults = false
    @State private var gameWinner: GameParticipant?
    @State private var finalUsedWords: [String] = []
    @State private var finalGameDuration: Int = 0
    @State private var finalEliminationHistory: [(playerId: String, reason: String, order: Int)] = []
    
    public init(
        gameData: GameSetupData,
        onGameEnd: @escaping (GameParticipant?, [String], Int, [(playerId: String, reason: String, order: Int)]) -> Void
    ) {
        AppLogger.shared.debug("MainGameView初期化開始")
        AppLogger.shared.debug("参加者数: \(gameData.participants.count)")
        AppLogger.shared.debug("参加者詳細: \(gameData.participants.map { "\($0.name)(\($0.type.displayName))" }.joined(separator: ", "))")
        AppLogger.shared.debug("ルール設定: 制限時間=\(gameData.rules.timeLimit)秒, 勝利条件=\(gameData.rules.winCondition)")
        
        self.gameData = gameData
        self.onGameEnd = onGameEnd
        
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
        .onAppear {
            AppLogger.shared.info("MainGameView画面表示完了")
            AppLogger.shared.debug("gameState.startGame()を呼び出します")
            previousPlayerId = gameState.activePlayer.id
            gameState.startGame()
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
        .sheet(isPresented: $showGameResults) {
            GameResultsView(
                winner: gameWinner,
                gameData: gameData,
                usedWords: finalUsedWords,
                gameDuration: finalGameDuration,
                eliminationHistory: finalEliminationHistory,
                onReturnToTitle: {
                    showGameResults = false
                    onGameEnd(gameWinner, finalUsedWords, finalGameDuration, finalEliminationHistory)
                },
                onPlayAgain: {
                    showGameResults = false
                    onGameEnd(gameWinner, finalUsedWords, finalGameDuration, finalEliminationHistory)
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
        // ゲーム結果データを準備
        prepareGameResults(winner: gameState.winner)
        // 結果画面を表示（自動遷移を削除）
        showGameResults = true
        AppLogger.shared.debug("結果画面表示: showGameResults=true")
    }
    
    private func prepareGameResults(winner: GameParticipant?) {
        gameWinner = winner
        finalUsedWords = gameState.usedWords
        finalGameDuration = calculateGameDuration()
        finalEliminationHistory = gameState.eliminationHistory
        AppLogger.shared.debug("ゲーム結果データ準備完了: 勝者=\(winner?.name ?? "なし"), 使用単語数=\(finalUsedWords.count)")
    }
    
    private func calculateGameDuration() -> Int {
        // 簡易的な計算（実際にはゲーム開始時間を記録して差分を計算すべき）
        return gameState.usedWords.count * 10 // 1単語あたり10秒と仮定
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