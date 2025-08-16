import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// メインゲーム画面（UI表示専用）
/// ビジネスロジックはGameControllerに分離済み
public struct MainGameView: View {
    // MARK: - Game Controller
    @State private var gameController: GameController
    
    // MARK: - UI State
    @State private var errorMessage = ""
    @Environment(\.modelContext) private var modelContext
    
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
        onNavigateToResults: ((GameResultsData) -> Void)? = nil,
        onQuitToTitle: (() -> Void)? = nil,
        onQuitToSettings: (() -> Void)? = nil
    ) {
        AppLogger.shared.debug("MainGameView初期化開始")
        AppLogger.shared.debug("参加者数: \(gameData.participants.count)")
        AppLogger.shared.debug("参加者詳細: \(gameData.participants.map { "\($0.name)(\($0.type.displayName))" }.joined(separator: ", "))")
        AppLogger.shared.debug("ルール設定: 制限時間=\(gameData.rules.timeLimit)秒, 勝利条件=\(gameData.rules.winCondition)")
        
        // GameControllerを初期化
        let gameController = GameController(
            gameData: gameData,
            onGameEnd: onGameEnd,
            onGameAbandoned: onGameAbandoned,
            onNavigateToResults: onNavigateToResults,
            onQuitToTitle: onQuitToTitle,
            onQuitToSettings: onQuitToSettings
        )
        self._gameController = State(initialValue: gameController)
        
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
                        if gameController.gameData.participants.count > 1 {
                            PlayerStatusBar(
                                participants: gameController.gameData.participants,
                                currentTurnIndex: gameController.gameState.currentTurnIndex,
                                eliminatedPlayers: gameController.gameState.eliminatedPlayers
                            )
                            .onAppear {
                                AppLogger.shared.debug("PlayerStatusBar表示完了")
                            }
                        }
                        
                        // ヘッダー: 現在のプレイヤーと時間
                        CurrentPlayerDisplay(
                            participant: gameController.activePlayer,
                            timeRemaining: gameController.timeRemaining
                        )
                        .onAppear {
                            AppLogger.shared.debug("CurrentPlayerDisplay表示完了")
                        }
                        
                        // 前の単語表示
                        WordDisplayCard(
                            word: gameController.lastWord,
                            isHighlighted: true
                        )
                        .onAppear {
                            AppLogger.shared.debug("WordDisplayCard表示完了")
                        }
                        
                        // 進行状況
                        GameProgressBar(
                            usedWordsCount: gameController.usedWords.count,
                            totalTurns: gameController.gameData.participants.count * 3 // 推定総ターン数
                        )
                        .onAppear {
                            AppLogger.shared.debug("GameProgressBar表示完了")
                        }
                        
                        // 単語履歴（スクロールエリアに移動）
                        WordHistoryView(words: gameController.usedWords)
                            .frame(maxHeight: GameUIHelpers.adaptiveHistoryHeight(for: geometry))
                        
                        // 入力エリア用のスペーサー（固定エリアと重ならないように）
                        Spacer()
                            .frame(height: GameUIHelpers.calculateInputAreaHeight(for: geometry))
                    }
                    .safeAreaPadding(.horizontal)
                    .safeAreaPadding(.top)
                }
                
                // 入力エリア（固定位置に配置）
                VStack {
                    Spacer()
                    
                    Group {
                        if case .human = gameController.activePlayer.type {
                            WordInputView(
                                isEnabled: gameController.isGameActive,
                                currentPlayerId: gameController.activePlayer.id,
                                onSubmit: { word in
                                    gameController.submitWord(word) { errorMessage in
                                        showError(errorMessage)
                                    }
                                }
                            )
                        } else {
                            ComputerThinkingView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        GameUIHelpers.backgroundColorForCurrentPlatform
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
                    newPlayer: gameController.activePlayer,
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
                    gameController.pauseGame()
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
            gameController.startGame()
        }
        .onChange(of: gameController.gameState.isGameActive) { _, isActive in
            if !isActive {
                gameController.handleGameEnd(modelContext: modelContext)
            }
        }
        .onChange(of: gameController.gameState.activePlayer.id) { _, newPlayerId in
            gameController.handlePlayerChange(newPlayerId: newPlayerId)
        }
        .alert("エラー", isPresented: showWordErrorBinding) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: showPauseMenuBinding) {
            PauseMenuView(
                onResume: {
                    gameController.resumeGame()
                },
                onQuit: {
                    gameController.quitGame()
                },
                onQuitToTitle: {
                    gameController.quitToTitle()
                },
                onQuitToSettings: {
                    gameController.quitToSettings(modelContext: modelContext)
                }
            )
        }
        #if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            gameController.handleBackgroundTransition(modelContext: modelContext)
        }
        #endif
    }
    
    // MARK: - UI Error Handling
    
    private func showError(_ message: String) {
        errorMessage = message
        uiState.setTransitionPhase("shown", for: "mainGame_wordError")
        AppLogger.shared.warning("ゲームエラー表示: \(message)")
    }
}