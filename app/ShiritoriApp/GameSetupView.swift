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
                MainGameView(
                    gameData: gameData,
                    onGameEnd: { winner, usedWords, gameDuration, eliminationHistory in
                        AppLogger.shared.info("ゲーム終了: 勝者=\(winner?.name ?? "なし")")
                        // ゲーム終了時はNavigationStackを通じてゲーム設定画面に戻る
                        navigationPath.removeLast()
                        // さらに設定画面も閉じてタイトル画面に戻る
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            AppLogger.shared.debug("ゲーム終了: タイトル画面に戻ります")
                            isPresented = false
                        }
                    }
                )
                .onAppear {
                    AppLogger.shared.debug("NavigationStack: MainGameView作成開始")
                }
            }
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
}

/// ゲーム結果画面（仮実装）
private struct GameResultsView: View {
    let winner: GameParticipant?
    let gameData: GameSetupData
    let onReturnToTitle: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Text("🎉 ゲーム終了")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let winner = winner {
                VStack(spacing: 16) {
                    Text("🏆 勝者")
                        .font(.title)
                        .foregroundColor(.orange)
                    
                    Text(winner.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            } else {
                Text("引き分け")
                    .font(.title)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            ChildFriendlyButton(
                title: "タイトルに もどる",
                backgroundColor: .blue,
                foregroundColor: .white
            ) {
                onReturnToTitle()
            }
        }
        .padding()
        .background(ChildFriendlyBackground())
    }
}

#Preview {
    GameSetupWrapperView(isPresented: .constant(true))
}