//
//  TitleView.swift
//  ShiritoriApp
//  
//  Created on 2025/07/11
//

import SwiftUI
import SwiftData
import ShiritoriCore

struct TitleView: View {
    @State private var navigationPath = NavigationPath()
    @State private var uiState = UIState.shared
    @State private var gameSetupData: GameSetupData? = nil
    // 🔧 ゲーム結果データの状態管理を追加
    @State private var gameResultsData: GameResultsData? = nil
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // 背景
                ChildFriendlyBackground()
                
                VStack(spacing: 60) {
                    // アニメーション付きタイトル
                    AnimatedTitleText(
                        title: "しりとり あそび",
                        isAnimated: true
                    )
                    
                    VStack(spacing: 24) {
                        // スタートボタン
                        ChildFriendlyButton(
                            title: "🎮 あそびはじめる",
                            backgroundColor: .green,
                            foregroundColor: .white
                        ) {
                            AppLogger.shared.info("スタートボタンタップ")
                            navigationPath.append("GameSetup")
                        }
                        
                        // プレイヤー管理ボタン
                        ChildFriendlyButton(
                            title: "👤 プレイヤー とうろく",
                            backgroundColor: .orange,
                            foregroundColor: .white
                        ) {
                            AppLogger.shared.info("プレイヤー管理ボタンタップ")
                            navigationPath.append("PlayerManagement")
                        }
                        
                        // 履歴ボタン
                        ChildFriendlyButton(
                            title: "📈 ゲーム れきし",
                            backgroundColor: .purple,
                            foregroundColor: .white
                        ) {
                            AppLogger.shared.info("ゲーム履歴ボタンタップ")
                            navigationPath.append("GameHistory")
                        }
                        
                        // 設定ボタン
                        ChildFriendlyButton(
                            title: "⚙️ せってい",
                            backgroundColor: .blue,
                            foregroundColor: .white
                        ) {
                            AppLogger.shared.info("設定ボタンタップ")
                            navigationPath.append("Settings")
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .padding(.top, 100)
            }
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "GameSetup":
                    GameSetupNavigationWrapperView(
                        navigationPath: $navigationPath,
                        gameSetupData: $gameSetupData
                    )
                case "PlayerManagement":
                    PlayerManagementNavigationWrapperView(navigationPath: $navigationPath)
                case "Settings":
                    SettingsNavigationWrapperView(navigationPath: $navigationPath)
                case "GameHistory":
                    GameHistoryNavigationWrapperView(navigationPath: $navigationPath)
                case "Game":
                    if let gameData = gameSetupData {
                        MainGameNavigationWrapperView(
                            navigationPath: $navigationPath,
                            gameSetupData: gameData,
                            gameResultsData: $gameResultsData  // 🔧 結果データのBindingを渡す
                        )
                    } else {
                        // 🔧 エラー状態を改善: ログ出力とタイトルに戻る処理を追加
                        VStack(spacing: 20) {
                            Text("ゲームデータが見つかりません")
                                .font(.title)
                                .foregroundColor(.red)
                            
                            ChildFriendlyButton(
                                title: "🏠 メニューに戻る",
                                backgroundColor: .blue,
                                foregroundColor: .white
                            ) {
                                AppLogger.shared.warning("ゲームデータ未設定のためタイトルに戻る")
                                navigationPath = NavigationPath()
                            }
                        }
                        .onAppear {
                            AppLogger.shared.error("ゲームデータが未設定でゲーム画面に遷移しようとしました")
                        }
                    }
                case "GameResults":
                    // 🔧 結果画面遷移の改善 - 実際のゲーム結果データを使用
                    if let resultsData = gameResultsData {
                        GameResultsNavigationWrapperView(
                            navigationPath: $navigationPath,
                            gameResultsData: resultsData
                        )
                    } else {
                        VStack(spacing: 20) {
                            Text("ゲーム結果データが見つかりません")
                                .font(.title)
                                .foregroundColor(.red)
                            
                            Text("ゲームが正常に終了していない可能性があります")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            ChildFriendlyButton(
                                title: "🏠 メニューに戻る",
                                backgroundColor: .blue,
                                foregroundColor: .white
                            ) {
                                AppLogger.shared.warning("ゲーム結果データ未設定のためタイトルに戻る")
                                navigationPath = NavigationPath()
                            }
                        }
                        .onAppear {
                            AppLogger.shared.error("ゲーム結果データが未設定で結果画面に遷移しようとしました")
                        }
                    }
                default:
                    VStack(spacing: 20) {
                        Text("不明な画面")
                            .font(.title)
                            .foregroundColor(.red)
                        
                        ChildFriendlyButton(
                            title: "🏠 メニューに戻る",
                            backgroundColor: .blue,
                            foregroundColor: .white
                        ) {
                            AppLogger.shared.warning("不明な画面への遷移: \(destination)")
                            navigationPath = NavigationPath()
                        }
                    }
                }
            }
        }
        .onAppear {
            AppLogger.shared.info("メインタイトル画面表示")
        }
    }
}

/// NavigationStack用のゲーム設定画面ラッパー
struct GameSetupNavigationWrapperView: View {
    @Binding var navigationPath: NavigationPath
    @Binding var gameSetupData: GameSetupData?
    
    var body: some View {
        GameSetupView(
            onStartGame: { setupData, participants, rules in
                AppLogger.shared.info("ゲーム開始: 参加者\(participants.count)人")
                gameSetupData = setupData
                navigationPath.append("Game")
            },
            onCancel: {
                if !navigationPath.isEmpty {
                    navigationPath.removeLast()
                }
            }
        )
    }
}

/// NavigationStack用のプレイヤー管理画面ラッパー
struct PlayerManagementNavigationWrapperView: View {
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        PlayerManagementView(onDismiss: {
            if !navigationPath.isEmpty {
                navigationPath.removeLast()
            }
        })
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// NavigationStack用の設定画面ラッパー
struct SettingsNavigationWrapperView: View {
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        SettingsView(onDismiss: {
            if !navigationPath.isEmpty {
                navigationPath.removeLast()
            }
        })
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// NavigationStack用のゲーム履歴画面ラッパー
struct GameHistoryNavigationWrapperView: View {
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        GameHistoryView(onDismiss: {
            if !navigationPath.isEmpty {
                navigationPath.removeLast()
            }
        })
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// NavigationStack用のメインゲーム画面ラッパー
struct MainGameNavigationWrapperView: View {
    @Binding var navigationPath: NavigationPath
    @Binding var gameResultsData: GameResultsData?  // 🔧 ゲーム結果データのBindingを追加
    let gameSetupData: GameSetupData
    
    init(navigationPath: Binding<NavigationPath>, gameSetupData: GameSetupData, gameResultsData: Binding<GameResultsData?>) {
        self._navigationPath = navigationPath
        self._gameResultsData = gameResultsData
        self.gameSetupData = gameSetupData
    }
    
    var body: some View {
        MainGameView(
            gameData: gameSetupData,
            // 🔧 レガシーonGameEnd: onNavigateToResults未提供時のフォールバック
            onGameEnd: { winner, usedWords, gameDuration, eliminationHistory in
                AppLogger.shared.warning("レガシーonGameEnd実行: onNavigateToResultsが未提供のため、メニューに戻ります")
                navigationPath = NavigationPath()
            },
            onGameAbandoned: { usedWords, gameDuration, eliminationHistory in
                AppLogger.shared.info("ゲーム途中終了")
                gameResultsData = nil  // 結果データをクリア
                navigationPath = NavigationPath()
            },
            // 🔧 GameResultsDataを受け取って状態に設定してから遷移
            onNavigateToResults: { resultsData in
                AppLogger.shared.info("結果画面への遷移: 勝者=\(resultsData.winner?.name ?? "なし"), 単語数=\(resultsData.usedWords.count)")
                gameResultsData = resultsData  // 🔧 重要: 結果データを設定
                navigationPath.append("GameResults")
            },
            onQuitToTitle: {
                AppLogger.shared.info("ゲーム終了してメニューに戻る")
                gameResultsData = nil  // 結果データをクリア
                navigationPath = NavigationPath()
            },
            onQuitToSettings: {
                AppLogger.shared.info("設定画面への遷移")
                navigationPath.append("Settings")
            }
        )
        // 🔧 中断ボタン表示問題を修正: navigationBarHidden(true)を削除
        .navigationBarBackButtonHidden(true)
    }
}

/// NavigationStack用のゲーム結果画面ラッパー
struct GameResultsNavigationWrapperView: View {
    @Binding var navigationPath: NavigationPath
    let gameResultsData: GameResultsData  // 🔧 実際のゲーム結果データを受け取る
    
    var body: some View {
        GameResultsView(
            // 🔧 必須パラメータを全て提供
            winner: gameResultsData.winner,
            gameData: gameResultsData.gameData,
            usedWords: gameResultsData.usedWords,
            gameDuration: gameResultsData.gameStats.gameDuration,
            eliminationHistory: generateEliminationHistory(),
            // 🔧 正しいパラメータ名に修正
            onReturnToTitle: {
                AppLogger.shared.info("結果画面からタイトルに戻る")
                navigationPath = NavigationPath()
            },
            onPlayAgain: {
                AppLogger.shared.info("もう一度遊ぶ")
                navigationPath = NavigationPath()
                navigationPath.append("GameSetup")
            }
        )
        .navigationBarBackButtonHidden(true)
    }
    
    // 🔧 GameResultsDataから脱落履歴を生成するヘルパー関数
    private func generateEliminationHistory() -> [(playerId: String, reason: String, order: Int)] {
        // GameResultsDataのランキングから脱落履歴を復元
        return gameResultsData.rankings.compactMap { ranking in
            if let order = ranking.eliminationOrder,
               let reason = ranking.eliminationReason {
                return (playerId: ranking.participant.id, reason: reason, order: order)
            }
            return nil
        }.sorted { $0.order < $1.order }
    }
}

#Preview {
    TitleView()
}