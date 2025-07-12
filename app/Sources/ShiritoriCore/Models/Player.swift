//
//  Player.swift
//  ShiritoriApp
//
//  Created on 2025/07/12
//

import Foundation
import SwiftData

@Model
public final class Player {
    
    // MARK: - プロパティ
    var name: String
    var iconImageData: Data?
    var gamesPlayed: Int
    var gamesWon: Int
    var createdAt: Date
    
    // MARK: - 計算プロパティ
    var winRate: Double {
        guard gamesPlayed > 0 else {
            AppLogger.shared.debug("プレイヤー \(name) の勝率計算: ゲーム数0のため0.0を返す")
            return 0.0
        }
        let rate = Double(gamesWon) / Double(gamesPlayed)
        AppLogger.shared.debug("プレイヤー \(name) の勝率計算: \(gamesWon)/\(gamesPlayed) = \(rate)")
        return rate
    }
    
    // MARK: - イニシャライザ
    public init(name: String, iconImageData: Data? = nil) {
        AppLogger.shared.info("新しいプレイヤーを作成: \(name)")
        self.name = name
        self.iconImageData = iconImageData
        self.gamesPlayed = 0
        self.gamesWon = 0
        self.createdAt = Date()
    }
    
    // MARK: - メソッド
    func updateStats(won: Bool) {
        AppLogger.shared.debug("プレイヤー \(name) の統計を更新: 勝利=\(won)")
        
        gamesPlayed += 1
        if won {
            gamesWon += 1
        }
        
        AppLogger.shared.info("プレイヤー \(name) の統計更新完了: \(gamesWon)勝/\(gamesPlayed)戦")
    }
}