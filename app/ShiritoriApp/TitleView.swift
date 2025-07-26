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
                navigationPath.removeLast()
            }
        )
        .navigationDestination(for: GameSetupData.self) { gameData in
            GameWrapperWithDataPersistence(
                gameData: gameData,
                onGameEnd: { winner, usedWords, gameDuration, eliminationHistory in
                    AppLogger.shared.info("ゲーム終了: 勝者=\(winner?.name ?? "なし") - タイトルに戻る")
                    // タイトル画面まで戻る（ゲーム画面→設定画面→タイトル画面）
                    navigationPath.removeAll()
                }
            )
        }
        .navigationTitle("ゲーム設定")
        .navigationBarBackButtonHidden(false)
    }
}

#Preview {
    TitleView()
}
