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
    @State private var showMainGame = false
    @State private var gameData: GameSetupData?
    
    var body: some View {
        GameSetupView(
            onStartGame: { setupData, participants, rules in
                AppLogger.shared.info("ゲーム開始: 参加者\(participants.count)人")
                gameData = setupData
                isPresented = false
                showMainGame = true
            },
            onCancel: {
                isPresented = false
            }
        )
        .fullScreenCover(isPresented: $showMainGame) {
            if let gameData = gameData {
                MainGameWrapperView(
                    gameData: gameData,
                    isPresented: $showMainGame
                )
            }
        }
    }
}

struct MainGameWrapperView: View {
    let gameData: GameSetupData
    @Binding var isPresented: Bool
    @State private var showResults = false
    @State private var winner: GameParticipant?
    
    var body: some View {
        NavigationView {
            MainGameView(
                gameData: gameData,
                onGameEnd: { winnerParticipant in
                    AppLogger.shared.info("ゲーム終了: 勝者=\(winnerParticipant?.name ?? "なし")")
                    winner = winnerParticipant
                    showResults = true
                }
            )
        }
        .sheet(isPresented: $showResults) {
            GameResultsView(
                winner: winner,
                gameData: gameData,
                onReturnToTitle: {
                    showResults = false
                    isPresented = false
                }
            )
        }
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