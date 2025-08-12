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
    @State private var navigationManager = NavigationManager.shared
    @State private var showNavigationError = false
    @State private var navigationErrorMessage = ""
    @State private var showGameRestore = false
    @State private var snapshotManager = GameStateSnapshotManager.shared
    @State private var restorableSnapshots: [GameStateSnapshot] = []
    @State private var memoryManager = MemoryManager.shared
    @State private var showMemoryWarning = false
    @State private var memoryWarningMessage = ""
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            EnhancedTitleView(
                isAnimationEnabled: true,
                onStartGame: {
                    AppLogger.shared.info("ゲーム開始ボタンがタップされました - NavigationStackで遷移")
                    safeNavigate(to: "GameSetup")
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
                handleStringDestination(destination)
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
        .alert("ナビゲーション エラー", isPresented: $showNavigationError) {
            Button("タイトルに戻る") {
                navigationManager.safeReturnToTitle(reason: "User recovery", navigationPath: &navigationPath)
            }
            Button("詳細", role: .cancel) {
                AppLogger.shared.info("Navigation Debug Report:\n\(navigationManager.generateDebugReport())")
            }
        } message: {
            Text(navigationErrorMessage)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            handleBackgroundReturn()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
            handleMemoryWarning()
        }
        .onReceive(NotificationCenter.default.publisher(for: .memoryPressureLevelChanged)) { notification in
            handleMemoryPressureChange(notification)
        }
        .onAppear {
            checkForRestorableGames()
            
            // メモリ監視開始
            if !memoryManager.isMonitoring {
                memoryManager.startMonitoring()
            }
        }
        .sheet(isPresented: $showGameRestore) {
            GameRestoreView(
                snapshots: restorableSnapshots,
                onRestore: { snapshot in
                    handleGameRestore(snapshot)
                },
                onNewGame: {
                    showGameRestore = false
                    safeNavigate(to: "GameSetup")
                },
                onCancel: {
                    showGameRestore = false
                }
            )
        }
        .alert("メモリ警告", isPresented: $showMemoryWarning) {
            Button("最適化実行") {
                memoryManager.performManualOptimization()
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(memoryWarningMessage)
        },
                onNewGame: {
                    showGameRestore = false
                    safeNavigate(to: "GameSetup")
                },
                onCancel: {
                    showGameRestore = false
                }
            )
        }
    }
    
    /// 安全なナビゲーション処理
    private func safeNavigate(to destination: String) {
        do {
            // ナビゲーション前の状態検証
            if navigationPath.count > 5 {
                throw NavigationManager.NavigationError.pathCorruption(details: "Navigation path too deep: \(navigationPath.count)")
            }
            
            navigationPath.append(destination)
            navigationManager.currentState = destination == "GameSetup" ? .gameSetup : .title
            
            AppLogger.shared.debug("安全なナビゲーション実行: \(destination)")
            
        } catch let error as NavigationManager.NavigationError {
            navigationManager.handleError(error, navigationPath: &navigationPath)
            showNavigationErrorDialog(error)
        } catch {
            let navError = NavigationManager.NavigationError.unknownDestination(path: destination)
            navigationManager.handleError(navError, navigationPath: &navigationPath)
            showNavigationErrorDialog(navError)
        }
    }
    
    /// 文字列の目的地処理
    @ViewBuilder
    private func handleStringDestination(_ destination: String) -> some View {
        switch destination {
        case "GameSetup":
            GameSetupNavigationWrapperView(
                navigationPath: $navigationPath,
                onShowSettings: {
                    showSettings = true
                }
            )
        default:
            // 未知の目的地のエラー処理
            VStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("不明な画面")
                    .font(.title)
                    .padding()
                
                Text("指定された画面が見つかりません: \(destination)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
                
                ChildFriendlyButton(
                    title: "🏠 タイトルに戻る",
                    backgroundColor: .blue,
                    foregroundColor: .white
                ) {
                    let error = NavigationManager.NavigationError.unknownDestination(path: destination)
                    navigationManager.handleError(error, navigationPath: &navigationPath)
                }
            }
            .padding()
            .onAppear {
                let error = NavigationManager.NavigationError.unknownDestination(path: destination)
                navigationManager.handleError(error, navigationPath: &navigationPath)
            }
        }
    }
    
    /// バックグラウンド復帰処理
    private func handleBackgroundReturn() {
        AppLogger.shared.info("アプリがフォアグラウンドに復帰")
        navigationManager.handleBackgroundReturn(navigationPath: &navigationPath)
    }
    
    /// メモリ警告処理
    private func handleMemoryWarning() {
        AppLogger.shared.warning("システムメモリ警告を受信")
        
        // MemoryManagerに処理を委任
        memoryManager.performManualOptimization()
        
        // ユーザーに警告表示
        memoryWarningMessage = "メモリ不足が検出されました。アプリの動作を最適化しています。"
        showMemoryWarning = true
        
        // ナビゲーションエラーとしても記録
        let error = NavigationManager.NavigationError.memoryPressure(details: "System memory warning received")
        navigationManager.handleError(error, navigationPath: &navigationPath)
    }
    
    /// メモリ圧迫レベル変更の処理
    private func handleMemoryPressureChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let newLevel = userInfo["newLevel"] as? MemoryManager.MemoryPressureLevel,
              let currentUsage = userInfo["currentUsage"] as? Double else {
            return
        }
        
        AppLogger.shared.info("メモリ圧迫レベル変更検出: \(newLevel.displayName)")
        
        // 高い圧迫レベルの場合はユーザーに通知
        if newLevel.rawValue >= MemoryManager.MemoryPressureLevel.high.rawValue {
            memoryWarningMessage = "メモリ使用量が高くなっています（\(String(format: "%.1f", currentUsage))MB）。アプリの動作が遅くなる可能性があります。"
            showMemoryWarning = true
        }
    }
    
    /// ナビゲーションエラーダイアログの表示
    private func showNavigationErrorDialog(_ error: NavigationManager.NavigationError) {
        navigationErrorMessage = switch error.severity {
        case .critical:
            "重要なナビゲーションエラーが発生しました。安全のためタイトル画面に戻ります。"
        case .warning:
            "ナビゲーションで問題が発生しましたが、自動で修復されました。"
        case .info:
            "ナビゲーション情報: \(error.description)"
        }
        
        // 重要度が高い場合のみダイアログ表示
        if error.severity == .critical || error.severity == .warning {
            showNavigationError = true
        }
    }
    
    /// 復元可能なゲームのチェック
    private func checkForRestorableGames() {
        Task {
            do {
                let snapshots = try snapshotManager.getRestorableSnapshots(modelContext: modelContext)
                
                await MainActor.run {
                    self.restorableSnapshots = snapshots
                    
                    // 復元可能なゲームがある場合は復元選択画面を表示
                    if !snapshots.isEmpty {
                        AppLogger.shared.info("復元可能なゲーム発見: \(snapshots.count)件")
                        showGameRestore = true
                    }
                }
            } catch {
                AppLogger.shared.error("復元可能ゲーム確認エラー: \(error.localizedDescription)")
            }
        }
    }
    
    /// ゲーム復元処理
    private func handleGameRestore(_ snapshot: GameStateSnapshot) {
        AppLogger.shared.info("ゲーム復元開始: \(snapshot.snapshotId)")
        
        do {
            let (gameData, gameStateData) = try snapshotManager.restoreGameState(from: snapshot)
            
            // 復元されたゲームデータでゲームを開始
            showGameRestore = false
            navigationPath.append(gameData)
            
            AppLogger.shared.info("ゲーム復元成功: 参加者\(gameData.participants.count)人")
            
        } catch {
            AppLogger.shared.error("ゲーム復元失敗: \(error.localizedDescription)")
            
            // 復元失敗時のエラーハンドリング
            let navError = NavigationManager.NavigationError.stateInconsistency(
                expected: "Valid game restore",
                actual: "Restore failed: \(error.localizedDescription)"
            )
            navigationManager.handleError(navError, navigationPath: &navigationPath)
            showNavigationErrorDialog(navError)
        }
    }
}

/// NavigationStack用のゲーム設定画面ラッパー
struct GameSetupNavigationWrapperView: View {
    @Binding var navigationPath: NavigationPath
    let onShowSettings: (() -> Void)?
    
    init(navigationPath: Binding<NavigationPath>, onShowSettings: (() -> Void)? = nil) {
        self._navigationPath = navigationPath
        self.onShowSettings = onShowSettings
    }
    
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
                },
                onQuitToTitle: {
                    AppLogger.shared.info("PauseMenu: タイトルに直接戻る選択")
                    navigationPath = NavigationPath()
                },
                onQuitToSettings: onShowSettings.map { showSettings in
                    return {
                        AppLogger.shared.info("PauseMenu: 設定画面を開く選択")
                        // まずタイトル画面に戻る
                        navigationPath = NavigationPath()
                        // 設定画面を開く（少し遅延させて確実に実行）
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showSettings()
                        }
                    }
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
