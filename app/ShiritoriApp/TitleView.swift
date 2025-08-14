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
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                Text("🎮 しりとりアプリ")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Button("ゲーム開始") {
                    navigationPath.append("GameSetup")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "GameSetup" {
                    GameSetupNavigationWrapperView(navigationPath: $navigationPath)
                } else {
                    Text("不明な画面")
                }
            }
        }
    }
}

/// NavigationStack用のゲーム設定画面ラッパー
struct GameSetupNavigationWrapperView: View {
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        GameSetupView(
            onStartGame: { setupData, participants, rules in
                // 簡略化されたゲーム開始処理
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

#Preview {
    TitleView()
}