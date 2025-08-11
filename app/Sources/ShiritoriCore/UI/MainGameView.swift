import SwiftUI

/// メインゲーム画面
public struct MainGameView: View {
    public let gameData: GameSetupData
    private let onGameEnd: (GameParticipant?, [String], Int, [(playerId: String, reason: String, order: Int)]) -> Void
    private let onGameAbandoned: (([String], Int, [(playerId: String, reason: String, order: Int)]) -> Void)?
    private let onNavigateToResults: ((GameResultsData) -> Void)?
    
    @State private var gameState: GameState
    @State private var inputText = ""
    @State private var errorMessage = ""
    @State private var previousPlayerId: String?
    @State private var gameStartTime: Date?
    
    // UIState統合による状態管理
    @State private var uiState = UIState.shared
    
    private var showPauseMenu: Bool {
        uiState.getTransitionPhase("mainGame_pauseMenu") == "shown"
    }
    
    private var showWordError: Bool {
        uiState.getTransitionPhase("mainGame_wordError") == "shown"
    }
    
    private var showPlayerTransition: Bool {
        uiState.getTransitionPhase("mainGame_playerTransition") == "shown"
    }
    
    private var showPauseMenuBinding: Binding<Bool> {
        Binding(
            get: { showPauseMenu },
            set: { newValue in
                if newValue {
                    uiState.setTransitionPhase("shown", for: "mainGame_pauseMenu")
                } else {
                    uiState.setTransitionPhase("hidden", for: "mainGame_pauseMenu")
                }
            }
        )
    }
    
    private var showWordErrorBinding: Binding<Bool> {
        Binding(
            get: { showWordError },
            set: { newValue in
                if newValue {
                    uiState.setTransitionPhase("shown", for: "mainGame_wordError")
                } else {
                    uiState.setTransitionPhase("hidden", for: "mainGame_wordError")
                }
            }
        )
    }
    
    public init(
        gameData: GameSetupData,
        onGameEnd: @escaping (GameParticipant?, [String], Int, [(playerId: String, reason: String, order: Int)]) -> Void,
        onGameAbandoned: (([String], Int, [(playerId: String, reason: String, order: Int)]) -> Void)? = nil,
        onNavigateToResults: ((GameResultsData) -> Void)? = nil
    ) {
        AppLogger.shared.debug("MainGameView初期化開始")
        AppLogger.shared.debug("参加者数: \(gameData.participants.count)")
        AppLogger.shared.debug("参加者詳細: \(gameData.participants.map { "\($0.name)(\($0.type.displayName))" }.joined(separator: ", "))")
        AppLogger.shared.debug("ルール設定: 制限時間=\(gameData.rules.timeLimit)秒, 勝利条件=\(gameData.rules.winCondition)")
        
        self.gameData = gameData
        self.onGameEnd = onGameEnd
        self.onGameAbandoned = onGameAbandoned
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
                
                // メインコンテンツエリア（入力エリア分のスペースを確保）
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
                        
                        // 単語履歴（スクロールエリアに移動）
                        WordHistoryView(words: gameState.usedWords)
                            .frame(maxHeight: adaptiveHistoryHeight(for: geometry))
                        
                        // 入力エリア用のスペーサー（固定エリアと重ならないように）
                        Spacer()
                            .frame(height: calculateInputAreaHeight(for: geometry))
                    }
                    .safeAreaPadding(.horizontal)
                    .safeAreaPadding(.top)
                }
                
                // 入力エリア（固定位置に配置）
                VStack {
                    Spacer()
                    
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
                    .background(
                        backgroundColorForCurrentPlatform
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -4)
                    )
                }
                .safeAreaPadding(.horizontal)
                .safeAreaPadding(.bottom)
            }
        }
        .overlay {
            // プレイヤー遷移アニメーション
            if showPlayerTransition {
                PlayerTransitionView(
                    newPlayer: gameState.activePlayer,
                    isVisible: showPlayerTransition,
                    onAnimationComplete: {
                        uiState.setTransitionPhase("hidden", for: "mainGame_playerTransition")
                    }
                )
                .zIndex(1)
            }
        }
        .navigationTitle("🎮 しりとり")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    AppLogger.shared.info("ポーズボタンタップ")
                    gameState.pauseGame()
                    uiState.setTransitionPhase("shown", for: "mainGame_pauseMenu")
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
        .alert("エラー", isPresented: showWordErrorBinding) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: showPauseMenuBinding) {
            PauseMenuView(
                onResume: {
                    uiState.setTransitionPhase("hidden", for: "mainGame_pauseMenu")
                    gameState.resumeGame()
                },
                onQuit: {
                    gameState.endGame()
                    // ゲーム途中終了時は放棄として処理
                    let usedWords = gameState.usedWords
                    let gameDuration = calculateGameDuration()
                    let eliminationHistory = gameState.eliminationHistory
                    
                    if let onGameAbandoned = onGameAbandoned {
                        // 新しい放棄コールバックが提供されている場合
                        onGameAbandoned(usedWords, gameDuration, eliminationHistory)
                    } else {
                        // 後方互換性：古いコールバックを使用（引き分けとして処理）
                        onGameEnd(nil, usedWords, gameDuration, eliminationHistory)
                    }
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
        uiState.setTransitionPhase("shown", for: "mainGame_wordError")
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
            uiState.setTransitionPhase("shown", for: "mainGame_playerTransition")
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
    
    /// 画面サイズに応じた入力エリア用スペーサーの高さを計算
    /// 固定位置の入力エリアとスクロール内容が重ならないようにする
    private func calculateInputAreaHeight(for geometry: GeometryProxy) -> CGFloat {
        let screenHeight = geometry.size.height
        
        // 入力エリアの高さを推定（WordInputViewの高さ + パディング）
        // 音声入力時：約200pt、キーボード入力時：約160pt
        let estimatedInputAreaHeight: CGFloat = 220
        
        // 小さい画面では最小限の追加スペースを確保
        if screenHeight < 600 {
            return estimatedInputAreaHeight + DesignSystem.Spacing.small
        }
        // 標準的な画面では適度なスペースを確保
        else if screenHeight < 800 {
            return estimatedInputAreaHeight + DesignSystem.Spacing.standard
        }
        // 大きな画面では十分なスペースを確保
        else {
            return estimatedInputAreaHeight + DesignSystem.Spacing.large
        }
    }
    
    private var backgroundColorForCurrentPlatform: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #else
        return Color.white
        #endif
    }
}