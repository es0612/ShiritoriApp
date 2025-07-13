import SwiftUI

/// メインゲーム画面
public struct MainGameView: View {
    public let gameData: GameSetupData
    private let onGameEnd: (GameParticipant?) -> Void
    
    @State private var gameState: GameState
    @State private var showPauseMenu = false
    @State private var inputText = ""
    @State private var showWordError = false
    @State private var errorMessage = ""
    
    public init(
        gameData: GameSetupData,
        onGameEnd: @escaping (GameParticipant?) -> Void
    ) {
        AppLogger.shared.debug("MainGameView初期化: 参加者\(gameData.participants.count)人")
        self.gameData = gameData
        self.onGameEnd = onGameEnd
        self._gameState = State(initialValue: GameState(gameData: gameData))
    }
    
    public var body: some View {
        ZStack {
            ChildFriendlyBackground(animationSpeed: 0.5)
            
            VStack(spacing: 20) {
                // ヘッダー: 現在のプレイヤーと時間
                CurrentPlayerDisplay(
                    participant: gameState.currentParticipant,
                    timeRemaining: gameState.timeRemaining
                )
                
                // 前の単語表示
                WordDisplayCard(
                    word: gameState.lastWord,
                    isHighlighted: true
                )
                
                // 進行状況
                GameProgressBar(
                    usedWordsCount: gameState.usedWords.count,
                    totalTurns: gameState.gameData.participants.count * 3 // 推定総ターン数
                )
                
                Spacer()
                
                // 入力エリア
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
                
                // 単語履歴
                WordHistoryView(words: gameState.usedWords)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("🎮 しりとり")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                ChildFriendlyButton(
                    title: "⏸️ いちじ ていし",
                    backgroundColor: .orange,
                    foregroundColor: .white
                ) {
                    showPauseMenu = true
                    gameState.pauseGame()
                }
            }
        }
        .onAppear {
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
                    onGameEnd(nil)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onGameEnd(gameState.winner)
        }
    }
}