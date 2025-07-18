//
//  GameSetupView.swift
//  ShiritoriApp
//  
//  Created on 2025/07/13
//

import SwiftUI
import SwiftData
import ShiritoriCore

struct GameSetupWrapperView: View {
    @Binding var isPresented: Bool
    @State private var navigationPath = NavigationPath()
    @State private var shouldReturnToTitle = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GameSetupView(
                onStartGame: { setupData, participants, rules in
                    AppLogger.shared.info("ゲーム開始: 参加者\(participants.count)人")
                    AppLogger.shared.debug("NavigationStack: ゲーム画面へ遷移開始")
                    
                    // NavigationStackを使って遷移（モーダル画面は開いたままにする）
                    navigationPath.append(setupData)
                    AppLogger.shared.debug("NavigationStack: パス追加完了")
                },
                onCancel: {
                    isPresented = false
                }
            )
            .navigationDestination(for: GameSetupData.self) { gameData in
                GameWrapperWithDataPersistence(
                    gameData: gameData,
                    onGameEnd: { winner, usedWords, gameDuration, eliminationHistory in
                        AppLogger.shared.info("ゲーム終了: 勝者=\(winner?.name ?? "なし")")
                        // 結果画面からユーザーが戻るボタンを押した時の処理
                        // NavigationStackを1つ戻す（ゲーム画面→設定画面）
                        navigationPath.removeLast()
                        AppLogger.shared.debug("ゲーム終了: ゲーム設定画面に戻る")
                    }
                )
                .onAppear {
                    AppLogger.shared.debug("NavigationStack: MainGameView作成開始")
                }
            }
        }
    }
}

/// GameSessionの保存処理付きのMainGameView Wrapper
struct GameWrapperWithDataPersistence: View {
    let gameData: GameSetupData
    let onGameEnd: (GameParticipant?, [String], Int, [(playerId: String, reason: String, order: Int)]) -> Void
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        MainGameView(
            gameData: gameData,
            onGameEnd: { winner, usedWords, gameDuration, eliminationHistory in
                AppLogger.shared.info("ゲーム終了コールバック: 勝者=\(winner?.name ?? "なし")")
                
                // GameSessionをSwiftDataに保存
                saveGameSession(
                    winner: winner,
                    usedWords: usedWords,
                    duration: Double(gameDuration)
                )
                
                // 上位のコールバックを実行
                onGameEnd(winner, usedWords, gameDuration, eliminationHistory)
            }
        )
    }
    
    private func saveGameSession(winner: GameParticipant?, usedWords: [String], duration: Double) {
        AppLogger.shared.info("GameSession保存開始: 勝者=\(winner?.name ?? "なし"), 単語数=\(usedWords.count), 時間=\(duration)秒")
        
        // プレイヤー名の配列を作成
        let playerNames = gameData.participants.map { $0.name }
        
        // GameSessionを作成
        let gameSession = GameSession(playerNames: playerNames)
        
        // 使用した単語を追加
        for (index, word) in usedWords.enumerated() {
            let playerIndex = index % playerNames.count
            let playerName = playerNames[playerIndex]
            gameSession.addWord(word, by: playerName)
        }
        
        // ゲームを完了状態にする
        if let winner = winner {
            gameSession.completeGame(winner: winner.name)
        } else {
            gameSession.completeDraw()
        }
        
        // SwiftDataに挿入
        modelContext.insert(gameSession)
        
        do {
            try modelContext.save()
            AppLogger.shared.info("GameSession保存成功")
        } catch {
            AppLogger.shared.error("GameSession保存失敗: \(error.localizedDescription)")
        }
    }
}

struct MainGameWrapperView: View {
    let gameData: GameSetupData
    @Binding var isPresented: Bool
    @State private var showResults = false
    @State private var winner: GameParticipant?
    @State private var usedWords: [String] = []
    @State private var gameDuration: Int = 0
    @State private var eliminationHistory: [(playerId: String, reason: String, order: Int)] = []
    @State private var isGameDataValid = true
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            VStack {
                if isGameDataValid {
                    MainGameView(
                        gameData: gameData,
                        onGameEnd: { winnerParticipant, gameUsedWords, duration, elimHistory in
                            AppLogger.shared.info("ゲーム終了: 勝者=\(winnerParticipant?.name ?? "なし")")
                            winner = winnerParticipant
                            usedWords = gameUsedWords
                            gameDuration = duration
                            eliminationHistory = elimHistory
                            
                            // GameSessionをSwiftDataに保存
                            saveGameSession(
                                winner: winnerParticipant,
                                usedWords: gameUsedWords,
                                duration: Double(duration)
                            )
                            
                            showResults = true
                        }
                    )
                } else {
                    VStack(spacing: 20) {
                        Text("ゲーム開始エラー")
                            .font(.title)
                            .foregroundColor(.red)
                        
                        Text("ゲームデータに問題があります")
                            .font(.caption)
                        
                        Button("戻る") {
                            isPresented = false
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .onAppear {
            AppLogger.shared.debug("MainGameWrapperView: 表示開始")
            validateGameData()
        }
        .sheet(isPresented: $showResults) {
            GameResultsView(
                winner: winner,
                gameData: gameData,
                usedWords: usedWords,
                gameDuration: gameDuration,
                eliminationHistory: eliminationHistory,
                onReturnToTitle: {
                    showResults = false
                    isPresented = false
                },
                onPlayAgain: {
                    showResults = false
                    // ゲームを再開始（現在の実装では設定画面に戻る）
                }
            )
        }
    }
    
    private func validateGameData() {
        AppLogger.shared.debug("ゲームデータバリデーション開始")
        
        guard !gameData.participants.isEmpty else {
            AppLogger.shared.error("参加者が空です")
            isGameDataValid = false
            return
        }
        
        guard gameData.rules.timeLimit >= 0 else {
            AppLogger.shared.error("制限時間が不正です: \(gameData.rules.timeLimit)")
            isGameDataValid = false
            return
        }
        
        AppLogger.shared.debug("ゲームデータバリデーション完了: 正常")
        isGameDataValid = true
    }
    
    private func saveGameSession(winner: GameParticipant?, usedWords: [String], duration: Double) {
        AppLogger.shared.info("GameSession保存開始: 勝者=\(winner?.name ?? "なし"), 単語数=\(usedWords.count), 時間=\(duration)秒")
        
        // プレイヤー名の配列を作成
        let playerNames = gameData.participants.map { $0.name }
        
        // GameSessionを作成
        let gameSession = GameSession(playerNames: playerNames)
        
        // 使用した単語を追加
        for (index, word) in usedWords.enumerated() {
            let playerIndex = index % playerNames.count
            let playerName = playerNames[playerIndex]
            gameSession.addWord(word, by: playerName)
        }
        
        // ゲームを完了状態にする
        if let winner = winner {
            gameSession.completeGame(winner: winner.name)
        } else {
            gameSession.completeDraw()
        }
        
        // SwiftDataに挿入
        modelContext.insert(gameSession)
        
        do {
            try modelContext.save()
            AppLogger.shared.info("GameSession保存成功")
        } catch {
            AppLogger.shared.error("GameSession保存失敗: \(error.localizedDescription)")
        }
    }
}


#Preview {
    GameSetupWrapperView(isPresented: .constant(true))
}