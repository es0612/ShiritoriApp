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
    @State private var showGameSetup = false
    @State private var showSettings = false
    
    var body: some View {
        EnhancedTitleView(
            isAnimationEnabled: true,
            onStartGame: {
                AppLogger.shared.info("ゲーム開始ボタンがタップされました")
                showGameSetup = true
            },
            onManagePlayers: {
                AppLogger.shared.info("プレイヤー管理ボタンがタップされました")
                showPlayerManagement = true
            },
            onShowSettings: {
                AppLogger.shared.info("設定ボタンがタップされました")
                showSettings = true
            }
        )
        .sheet(isPresented: $showPlayerManagement) {
            PlayerManagementWrapperView(isPresented: $showPlayerManagement)
        }
        .sheet(isPresented: $showGameSetup) {
            GameSetupWrapperView(isPresented: $showGameSetup)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(onDismiss: {
                showSettings = false
            })
        }
    }
}

#Preview {
    TitleView()
}
