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
                            participant: gameState.currentParticipant,
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
                            if case .human = gameState.currentParticipant.type {
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
        .navigationTitle("🎮 しりとり")
        .navigationBarBackButtonHidden(true)
        .onAppear {
            AppLogger.shared.info("MainGameView画面表示完了")
            AppLogger.shared.debug("gameState.startGame()を呼び出します")
            gameState.startGame()
        }
        .onChange(of: gameState.isGameActive) { _, isActive in
            if !isActive {
                handleGameEnd()
            }
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
                    onGameEnd(nil, gameState.usedWords, calculateGameDuration(), gameState.eliminationHistory)
                }
            )
        }
    }
    
    private func submitWord(_ word: String) {
        let result = gameState.submitWord(word, by: gameState.currentParticipant.id)
        
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
        // 自動遷移を除去し、即座に結果画面へ遷移
        // 結果画面からの遷移はユーザー操作のみで行う
        onGameEnd(gameState.winner, gameState.usedWords, calculateGameDuration(), gameState.eliminationHistory)
    }
    
    private func calculateGameDuration() -> Int {
        // 簡易的な計算（実際にはゲーム開始時間を記録して差分を計算すべき）
        return gameState.usedWords.count * 10 // 1単語あたり10秒と仮定
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