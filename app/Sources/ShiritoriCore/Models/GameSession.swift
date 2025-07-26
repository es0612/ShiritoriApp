//
//  GameSession.swift
//  ShiritoriApp
//
//  Created on 2025/07/12
//

import Foundation
import SwiftData

@Model
public final class GameSession {
    
    // MARK: - プロパティ
    var playerNames: [String]
    var isCompleted: Bool
    var winnerName: String?
    var createdAt: Date
    var completedAt: Date?
    var wordsUsed: [Word]
    
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
    
    // MARK: - イニシャライザ
    public init(playerNames: [String]) {
        AppLogger.shared.info("新しいゲームセッションを作成: プレイヤー数=\(playerNames.count)")
        self.playerNames = playerNames
        self.isCompleted = false
        self.winnerName = nil
        self.createdAt = Date()
        self.completedAt = nil
        self.wordsUsed = []
        
        AppLogger.shared.debug("ゲームセッション参加者: \(playerNames.joined(separator: ", "))")
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
    
    public func addWord(_ word: String, by playerName: String) {
        AppLogger.shared.debug("単語をゲームセッションに追加: '\(word)' by \(playerName)")
        
        let wordEntry = Word(word: word, playerName: playerName)
        wordsUsed.append(wordEntry)
        
        AppLogger.shared.info("ゲームセッションの単語数: \(wordsUsed.count)")
    }
}