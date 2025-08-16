//
//  ShiritoriAppApp.swift
//  ShiritoriApp
//  
//  Created on 2025/07/11
//


import SwiftUI
import SwiftData
import ShiritoriCore

@main
struct ShiritoriAppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Player.self,
            GameSession.self,
            Word.self,
            AppSettings.self,  // 設定モデルを追加
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainAppView()
                .onAppear {
                    // 🔧 UIState状態のリセット（前回セッションのアニメーション状態をクリア）
                    UIState.shared.resetAll()
                    AppLogger.shared.info("UIState状態リセット完了")
                    
                    // SettingsManagerを初期化
                    SettingsManager.shared.initialize(with: sharedModelContainer.mainContext)
                    AppLogger.shared.info("アプリケーション開始: SettingsManager初期化完了")
                    
                    // チュートリアル管理を初期化
                    TutorialManager.shared.initializeOnAppLaunch()
                    AppLogger.shared.info("TutorialManager初期化完了")
                    
                    // 既存ゲームデータのマイグレーション実行
                    GameSession.migrateExistingData(modelContext: sharedModelContainer.mainContext)
                    AppLogger.shared.info("GameSessionデータマイグレーション完了")
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
