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
    
    // MARK: - メソッド
    func completeGame(winner: String) {
        AppLogger.shared.info("ゲームセッション完了: 勝者=\(winner)")
        
        isCompleted = true
        winnerName = winner
        completedAt = Date()
        
        AppLogger.shared.debug("ゲーム終了時刻: \(completedAt?.description ?? "nil")")
    }
    
    func addWord(_ word: String, by playerName: String) {
        AppLogger.shared.debug("単語をゲームセッションに追加: '\(word)' by \(playerName)")
        
        let wordEntry = Word(word: word, playerName: playerName)
        wordsUsed.append(wordEntry)
        
        AppLogger.shared.info("ゲームセッションの単語数: \(wordsUsed.count)")
    }
}