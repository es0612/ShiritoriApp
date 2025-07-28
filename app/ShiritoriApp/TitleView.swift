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
    @State private var showPlayerManagement = false
    @State private var showSettings = false
    @State private var showGameHistory = false
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            EnhancedTitleView(
                isAnimationEnabled: true,
                onStartGame: {
                    AppLogger.shared.info("ゲーム開始ボタンがタップされました - NavigationStackで遷移")
                    navigationPath.append("GameSetup")
                },
                onManagePlayers: {
                    AppLogger.shared.info("プレイヤー管理ボタンがタップされました")
                    showPlayerManagement = true
                },
                onShowSettings: {
                    AppLogger.shared.info("設定ボタンがタップされました")
                    showSettings = true
                },
                onShowHistory: {
                    AppLogger.shared.info("ゲーム履歴ボタンがタップされました")
                    showGameHistory = true
                }
            )
            .navigationDestination(for: String.self) { destination in
                if destination == "GameSetup" {
                    GameSetupNavigationWrapperView(navigationPath: $navigationPath)
                }
            }
            .navigationDestination(for: GameResultsData.self) { resultsData in
                GameResultsNavigationWrapperView(
                    resultsData: resultsData,
                    navigationPath: $navigationPath
                )
            }
        }
        .sheet(isPresented: $showPlayerManagement) {
            PlayerManagementWrapperView(isPresented: $showPlayerManagement)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(onDismiss: {
                showSettings = false
            })
        }
        .sheet(isPresented: $showGameHistory) {
            GameHistoryView(onDismiss: {
                showGameHistory = false
            })
        }
    }
}

/// NavigationStack用のゲーム設定画面ラッパー
struct GameSetupNavigationWrapperView: View {
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        GameSetupView(
            onStartGame: { setupData, participants, rules in
                AppLogger.shared.info("ゲーム開始: 参加者\(participants.count)人 - NavigationStackで遷移")
                navigationPath.append(setupData)
            },
            onCancel: {
                AppLogger.shared.info("ゲーム設定キャンセル - NavigationStackで戻る")
                if !navigationPath.isEmpty {
                    navigationPath.removeLast()
                }
            }
        )
        .navigationDestination(for: GameSetupData.self) { gameData in
            GameWrapperWithDataPersistence(
                gameData: gameData,
                onGameEnd: { winner, usedWords, gameDuration, eliminationHistory in
                    AppLogger.shared.info("ゲーム終了: 勝者=\(winner?.name ?? "なし") - タイトルに戻る")
                    // タイトル画面まで戻る（ゲーム画面→設定画面→タイトル画面）
                    navigationPath = NavigationPath()
                },
                onNavigateToResults: { resultsData in
                    AppLogger.shared.info("結果画面へナビゲーション遷移")
                    navigationPath.append(resultsData)
                }
            )
        }
        .navigationTitle("ゲーム設定")
        .navigationBarBackButtonHidden(false)
    }
}

/// NavigationStack用の結果画面ラッパー
struct GameResultsNavigationWrapperView: View {
    let resultsData: GameResultsData
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        GameResultsView(
            winner: resultsData.winner,
            gameData: resultsData.gameData,
            usedWords: resultsData.usedWords,
            gameDuration: Int(resultsData.gameStats.gameDuration),
            eliminationHistory: extractEliminationHistory(from: resultsData.rankings),
            onReturnToTitle: {
                AppLogger.shared.info("結果画面からタイトルに戻る - NavigationStackで遷移")
                navigationPath = NavigationPath()
            },
            onPlayAgain: {
                AppLogger.shared.info("結果画面からもう一度プレイ - NavigationStackで遷移")
                // ゲーム設定画面に戻る
                navigationPath = NavigationPath()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    navigationPath.append("GameSetup")
                }
            }
        )
        .navigationTitle("ゲーム結果")
        .navigationBarBackButtonHidden(false) // 戻るボタンを有効化
    }
    
    private func extractEliminationHistory(from rankings: [PlayerRanking]) -> [(playerId: String, reason: String, order: Int)] {
        return rankings.compactMap { ranking in
            guard let eliminationOrder = ranking.eliminationOrder,
                  let eliminationReason = ranking.eliminationReason else {
                return nil
            }
            return (playerId: ranking.participant.id, reason: eliminationReason, order: eliminationOrder)
        }
    }
}

#Preview {
    TitleView()
}
