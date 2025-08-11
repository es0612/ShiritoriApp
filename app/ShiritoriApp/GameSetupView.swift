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
    @State private var navigationPath = NavigationPath()
    @State private var shouldReturnToTitle = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GameSetupView(
                onStartGame: { setupData, participants, rules in
                    AppLogger.shared.info("ゲーム開始: 参加者\(participants.count)人")
                    AppLogger.shared.debug("NavigationStack: ゲーム画面へ遷移開始")
                    
                    // NavigationStackを使って遷移（モーダル画面は開いたままにする）
                    navigationPath.append(setupData)
                    AppLogger.shared.debug("NavigationStack: パス追加完了")
                },
                onCancel: {
                    isPresented = false
                }
            )
            .navigationDestination(for: GameSetupData.self) { gameData in
                GameWrapperWithDataPersistence(
                    gameData: gameData,
                    onGameEnd: { winner, usedWords, gameDuration, eliminationHistory in
                        AppLogger.shared.info("ゲーム終了: 勝者=\(winner?.name ?? "なし")")
                        // 結果画面からユーザーが戻るボタンを押した時の処理
                        // NavigationStackを1つ戻ス（ゲーム画面→設定画面）
                        navigationPath.removeLast()
                        AppLogger.shared.debug("ゲーム終了: ゲーム設定画面に戻る")
                    },
                    onNavigateToResults: nil // この場合はナビゲーション遷移を使用しない
                )
                .onAppear {
                    AppLogger.shared.debug("NavigationStack: MainGameView作成開始")
                }
            }
        }
    }
}

/// GameSessionの保存処理付きのMainGameView Wrapper
struct GameWrapperWithDataPersistence: View {
    let gameData: GameSetupData
    let onGameEnd: (GameParticipant?, [String], Int, [(playerId: String, reason: String, order: Int)]) -> Void
    let onNavigateToResults: ((GameResultsData) -> Void)?
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        MainGameView(
            gameData: gameData,
            onGameEnd: { winner, usedWords, gameDuration, eliminationHistory in
                AppLogger.shared.info("ゲーム終了コールバック: 勝者=\(winner?.name ?? "なし")")
                
                // GameSessionをSwiftDataに保存
                saveGameSession(
                    winner: winner,
                    usedWords: usedWords,
                    duration: Double(gameDuration)
                )
                
                // 上位のコールバックを実行
                onGameEnd(winner, usedWords, gameDuration, eliminationHistory)
            },
            onGameAbandoned: { usedWords, gameDuration, eliminationHistory in
                AppLogger.shared.info("ゲーム放棄コールバック: 単語数=\(usedWords.count)")
                
                // 放棄されたゲームとしてSwiftDataに保存
                saveGameSession(
                    winner: nil,
                    usedWords: usedWords,
                    duration: Double(gameDuration),
                    completionType: .abandoned
                )
                
                // 上位のコールバックを実行（勝者なしで）
                onGameEnd(nil, usedWords, gameDuration, eliminationHistory)
            },
            onNavigateToResults: onNavigateToResults
        )
    }
    
    private func saveGameSession(
        winner: GameParticipant?, 
        usedWords: [String], 
        duration: Double, 
        completionType: GameCompletionType? = nil
    ) {
        AppLogger.shared.info("GameSession保存開始: 勝者=\(winner?.name ?? "なし"), 単語数=\(usedWords.count), 時間=\(duration)秒")
        
        // プレイヤー名の配列を作成
        let playerNames = gameData.participants.map { $0.name }
        
        // GameSessionを作成
        let gameSession = GameSession(playerNames: playerNames)
        
        // 🛡️ 重複保存チェック - 同じ一意IDのセッションが既に存在するかチェック
        let uniqueId = gameSession.uniqueGameId
        do {
            let existingSessionsRequest = FetchDescriptor<GameSession>(
                predicate: #Predicate { $0.uniqueGameId == uniqueId }
            )
            let existingSessions = try modelContext.fetch(existingSessionsRequest)
            
            if !existingSessions.isEmpty {
                AppLogger.shared.warning("重複したゲームセッション保存を防止: ID=\(gameSession.uniqueGameId)")
                return
            }
        } catch {
            AppLogger.shared.error("重複チェック中にエラー: \(error.localizedDescription)")
            // エラーが発生しても保存は続行する
        }
        
        // 使用した単語を追加
        for (index, word) in usedWords.enumerated() {
            let playerIndex = index % playerNames.count
            let playerName = playerNames[playerIndex]
            gameSession.addWord(word, by: playerName)
        }
        
        // ゲームを完了状態にする（完了タイプに応じて適切なメソッドを呼び出し）
        if let winner = winner {
            gameSession.completeGame(winner: winner.name, gameDurationSeconds: duration)
        } else {
            // 完了タイプが指定されている場合はそれを使用、なければ引き分けとして処理
            let actualCompletionType = completionType ?? .draw
            switch actualCompletionType {
            case .draw:
                gameSession.completeDraw(gameDurationSeconds: duration)
            case .abandoned:
                gameSession.completeAbandoned(gameDurationSeconds: duration)
            case .completed:
                // この分岐は通常発生しないはず（winnerがあるべき）
                AppLogger.shared.warning("勝者なしで完了タイプが.completedに設定されています")
                gameSession.completeDraw(gameDurationSeconds: duration)
            }
        }
        
        // SwiftDataに挿入
        modelContext.insert(gameSession)
        
        do {
            try modelContext.save()
            AppLogger.shared.info("GameSession保存成功: \(gameSession.completionType.displayName)")
        } catch {
            AppLogger.shared.error("GameSession保存失敗: \(error.localizedDescription)")
        }
    }
}

// MARK: - 未使用のMainGameWrapperViewを削除
// このコンポーネントは使用されておらず、重複保存の原因となる可能性があったため削除


#Preview {
    GameSetupWrapperView(isPresented: .constant(true))
}