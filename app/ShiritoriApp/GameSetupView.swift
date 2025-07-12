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
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🎮 メインゲーム")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("参加者: \(gameData.participants.count)人")
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(gameData.participants, id: \.id) { participant in
                    Text("• \(participant.name) (\(participant.type.displayName))")
                        .font(.body)
                }
            }
            
            Text("制限時間: \(gameData.rules.timeLimit)秒")
                .font(.body)
            
            Text("勝利条件: \(gameData.rules.winCondition.description)")
                .font(.body)
            
            Spacer()
            
            ChildFriendlyButton(
                title: "タイトルに もどる",
                backgroundColor: .gray,
                foregroundColor: .white
            ) {
                isPresented = false
            }
        }
        .padding()
        .background(
            ChildFriendlyBackground()
        )
    }
}

#Preview {
    GameSetupWrapperView(isPresented: .constant(true))
}