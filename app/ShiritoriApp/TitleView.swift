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
                            gameSetupData: gameData
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
                    // 🔧 結果画面遷移の追加
                    if let gameData = gameSetupData {
                        GameResultsNavigationWrapperView(
                            navigationPath: $navigationPath,
                            gameSetupData: gameData
                        )
                    } else {
                        VStack(spacing: 20) {
                            Text("結果データが見つかりません")
                                .font(.title)
                                .foregroundColor(.red)
                            
                            ChildFriendlyButton(
                                title: "🏠 メニューに戻る",
                                backgroundColor: .blue,
                                foregroundColor: .white
                            ) {
                                navigationPath = NavigationPath()
                            }
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
    let gameSetupData: GameSetupData
    
    init(navigationPath: Binding<NavigationPath>, gameSetupData: GameSetupData) {
        self._navigationPath = navigationPath
        self.gameSetupData = gameSetupData
    }
    
    var body: some View {
        MainGameView(
            gameData: gameSetupData,
            onGameEnd: { winner, usedWords, gameDuration, eliminationHistory in
                AppLogger.shared.info("ゲーム終了: 勝者=\(winner?.name ?? "なし")")
                navigationPath.append("GameResults")
            },
            onGameAbandoned: { usedWords, gameDuration, eliminationHistory in
                AppLogger.shared.info("ゲーム途中終了")
                navigationPath = NavigationPath()
            },
            onNavigateToResults: { resultsData in
                AppLogger.shared.info("結果画面への遷移")
                navigationPath.append("GameResults")
            },
            onQuitToTitle: {
                AppLogger.shared.info("ゲーム終了してメニューに戻る")
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
    let gameSetupData: GameSetupData
    
    var body: some View {
        GameResultsView(
            onBackToTitle: {
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
}

#Preview {
    TitleView()
}