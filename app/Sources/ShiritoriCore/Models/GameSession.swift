//
//  GameSession.swift
//  ShiritoriApp
//
//  Created on 2025/07/12
//

import Foundation
import SwiftData

/// ゲーム完了タイプの列挙型
public enum GameCompletionType: String, CaseIterable, Codable {
    case completed = "completed"    // 正常に完了（勝者あり）
    case draw = "draw"             // 引き分けで完了
    case abandoned = "abandoned"    // 途中で放棄・中断
    
    /// 表示用の日本語名
    public var displayName: String {
        switch self {
        case .completed:
            return "完了"
        case .draw:
            return "引き分け"
        case .abandoned:
            return "中断"
        }
    }
    
    /// 履歴表示用のアイコン
    public var iconName: String {
        switch self {
        case .completed:
            return "🏆"
        case .draw:
            return "🤝"
        case .abandoned:
            return "🚫"
        }
    }
}

@Model
public final class GameSession {
    
    // MARK: - プロパティ
    var playerNames: [String]
    var isCompleted: Bool
    var winnerName: String?
    var createdAt: Date
    var completedAt: Date?
    var wordsUsed: [Word]
    var completionTypeRaw: String // GameCompletionTypeのrawValue用
    public var uniqueGameId: String // 重複保存防止用の一意ID // 重複保存防止用の一意ID
    
    // MARK: - 互換性プロパティ
    public var participantNames: [String] {
        return playerNames
    }
    
    public var usedWords: [Word] {
        return wordsUsed
    }
    
    public var gameDuration: TimeInterval {
        guard let completed = completedAt else {
            return 0
        }
        return completed.timeIntervalSince(createdAt)
    }
    
    /// ゲーム完了タイプの計算プロパティ
    public var completionType: GameCompletionType {
        get {
            return GameCompletionType(rawValue: completionTypeRaw) ?? .abandoned
        }
        set {
            completionTypeRaw = newValue.rawValue
        }
    }
    
    // MARK: - イニシャライザ
    public init(playerNames: [String]) {
        AppLogger.shared.info("新しいゲームセッションを作成: プレイヤー数=\(playerNames.count)")
        self.playerNames = playerNames
        self.isCompleted = false
        self.winnerName = nil
        self.createdAt = Date()
        self.completedAt = nil
        self.wordsUsed = []
        self.completionTypeRaw = GameCompletionType.abandoned.rawValue // デフォルトは未完了
        
        // 重複防止用の一意ID生成 (タイムスタンプ + UUID)
        let timestamp = Int(Date().timeIntervalSince1970 * 1000) // ミリ秒精度
        let uuid = UUID().uuidString.prefix(8) // UUIDの最初の8文字
        self.uniqueGameId = "\(timestamp)_\(uuid)"
        
        AppLogger.shared.debug("ゲームセッション参加者: \(playerNames.joined(separator: ", "))")
        AppLogger.shared.debug("一意ID: \(uniqueGameId)")
    }
    
    // テストとプレビュー用の便利イニシャライザ
    public convenience init(participantNames: [String], winnerName: String?) {
        self.init(playerNames: participantNames)
        
        if let winner = winnerName {
            self.completeGame(winner: winner)
        } else {
            // 引き分けの場合
            self.completeDraw()
        }
    }
    
    // MARK: - メソッド
    public func completeGame(winner: String, gameDurationSeconds: TimeInterval? = nil) {
        AppLogger.shared.info("ゲームセッション完了: 勝者=\(winner)")
        
        isCompleted = true
        winnerName = winner
        completionType = .completed // 勝者ありの正常完了
        
        if let duration = gameDurationSeconds {
            // 実際のゲーム経過時間を使用して終了時刻を設定
            completedAt = createdAt.addingTimeInterval(duration)
            AppLogger.shared.info("実際の経過時間を使用: \(duration)秒")
        } else {
            // フォールバック: 現在時刻を使用
            completedAt = Date()
            AppLogger.shared.warning("経過時間が未指定のため現在時刻を使用")
        }
        
        AppLogger.shared.debug("ゲーム終了時刻: \(completedAt?.description ?? "nil")")
    }
    
    public func completeDraw(gameDurationSeconds: TimeInterval? = nil) {
        AppLogger.shared.info("ゲームセッション完了: 引き分け")
        
        isCompleted = true
        winnerName = nil
        completionType = .draw // 引き分けでの完了
        
        if let duration = gameDurationSeconds {
            // 実際のゲーム経過時間を使用して終了時刻を設定
            completedAt = createdAt.addingTimeInterval(duration)
            AppLogger.shared.info("実際の経過時間を使用: \(duration)秒")
        } else {
            // フォールバック: 現在時刻を使用
            completedAt = Date()
            AppLogger.shared.warning("経過時間が未指定のため現在時刻を使用")
        }
        
        AppLogger.shared.debug("ゲーム終了時刻: \(completedAt?.description ?? "nil")")
    }
    
    /// ゲーム途中終了（放棄・中断）の処理
    public func completeAbandoned(gameDurationSeconds: TimeInterval? = nil) {
        AppLogger.shared.info("ゲームセッション中断: 途中終了")
        
        isCompleted = true
        winnerName = nil
        completionType = .abandoned // 途中終了・放棄
        
        if let duration = gameDurationSeconds {
            // 実際のゲーム経過時間を使用して終了時刻を設定
            completedAt = createdAt.addingTimeInterval(duration)
            AppLogger.shared.info("中断時の経過時間: \(duration)秒")
        } else {
            // フォールバック: 現在時刻を使用
            completedAt = Date()
            AppLogger.shared.warning("経過時間が未指定のため現在時刻を使用")
        }
        
        AppLogger.shared.debug("ゲーム中断時刻: \(completedAt?.description ?? "nil")")
    }
    
    public func addWord(_ word: String, by playerName: String) {
        AppLogger.shared.debug("単語をゲームセッションに追加: '\(word)' by \(playerName)")
        
        let wordEntry = Word(word: word, playerName: playerName)
        wordsUsed.append(wordEntry)
        
        AppLogger.shared.info("ゲームセッションの単語数: \(wordsUsed.count)")
    }

    
    // MARK: - データマイグレーション
    
    /// 既存のゲームセッションデータを新しい完了タイプシステムに移行する
    /// このメソッドはアプリ起動時に一度だけ実行される想定
    public static func migrateExistingData(modelContext: ModelContext) {
        AppLogger.shared.info("既存GameSessionデータのマイグレーション開始")
        
        do {
            // 完了済みで、completionTypeRawが正しく設定されていない可能性があるセッションを取得
            let fetchRequest = FetchDescriptor<GameSession>(
                predicate: #Predicate<GameSession> { session in
                    session.isCompleted
                }
            )
            
            let existingSessions = try modelContext.fetch(fetchRequest)
            var migratedCount = 0
            var skippedCount = 0
            
            for session in existingSessions {
                // 既に適切に分類されているかチェック
                let needsMigration = shouldMigrateSession(session)
                
                if needsMigration {
                    let oldType = session.completionTypeRaw
                    migrateSession(session)
                    let newType = session.completionTypeRaw
                    
                    AppLogger.shared.info("セッション移行: ID=\(session.uniqueGameId), \(oldType) → \(newType)")
                    migratedCount += 1
                } else {
                    skippedCount += 1
                }
            }
            
            // 変更を保存
            if migratedCount > 0 {
                try modelContext.save()
                AppLogger.shared.info("データマイグレーション完了: \(migratedCount)件移行, \(skippedCount)件スキップ")
            } else {
                AppLogger.shared.info("データマイグレーション: 移行対象なし (\(skippedCount)件確認済み)")
            }
            
        } catch {
            AppLogger.shared.error("データマイグレーションエラー: \(error.localizedDescription)")
        }
    }
    
    /// セッションが移行対象かどうかを判定
    private static func shouldMigrateSession(_ session: GameSession) -> Bool {
        // uniqueGameIdが設定されていない場合は移行対象
        if session.uniqueGameId.isEmpty {
            return true
        }
        
        // 完了タイプが適切に設定されているかチェック
        let currentType = GameCompletionType(rawValue: session.completionTypeRaw) ?? .abandoned
        
        // 勝者がいるのに完了タイプが.completedでない場合
        if session.winnerName != nil && currentType != .completed {
            return true
        }
        
        // 勝者がいないのに完了タイプが.completedの場合
        if session.winnerName == nil && currentType == .completed {
            return true
        }
        
        // デフォルト値（abandoned）のままで、実際は引き分けの可能性がある場合
        if session.winnerName == nil && currentType == .abandoned {
            // ゲームが十分進行していれば引き分けと判定
            let hasEnoughProgress = session.usedWords.count >= 3 && session.gameDuration >= 30.0
            return hasEnoughProgress
        }
        
        return false
    }
    
    /// セッションを適切な完了タイプに移行
    private static func migrateSession(_ session: GameSession) {
        // uniqueGameIdが未設定の場合は生成
        if session.uniqueGameId.isEmpty {
            let timestamp = Int(session.createdAt.timeIntervalSince1970 * 1000)
            let uuid = UUID().uuidString.prefix(8)
            session.uniqueGameId = "\(timestamp)_\(uuid)"
            AppLogger.shared.debug("uniqueGameID生成: \(session.uniqueGameId)")
        }
        
        // 完了タイプを適切に設定
        if let _ = session.winnerName {
            // 勝者がいる場合は完了済み
            session.completionTypeRaw = GameCompletionType.completed.rawValue
        } else {
            // 勝者がいない場合は引き分けか中断かを判定
            let wordCount = session.usedWords.count
            let duration = session.gameDuration
            
            // 判定基準:
            // - 3単語以上かつ30秒以上: 引き分けと判定
            // - それ以外: 中断と判定
            if wordCount >= 3 && duration >= 30.0 {
                session.completionTypeRaw = GameCompletionType.draw.rawValue
                AppLogger.shared.debug("引き分けに分類: 単語数=\(wordCount), 時間=\(String(format: "%.1f", duration))秒")
            } else {
                session.completionTypeRaw = GameCompletionType.abandoned.rawValue
                AppLogger.shared.debug("中断に分類: 単語数=\(wordCount), 時間=\(String(format: "%.1f", duration))秒")
            }
        }
    }
}