//
//  Word.swift
//  ShiritoriApp
//
//  Created on 2025/07/12
//

import Foundation
import SwiftData

@Model
public final class Word {
    
    // MARK: - プロパティ
    var word: String
    var playerName: String
    var createdAt: Date
    
    // MARK: - 計算プロパティ
    var firstCharacter: String {
        let result = String(word.prefix(1))
        AppLogger.shared.debug("単語 '\(word)' の最初の文字: \(result)")
        return result
    }
    
    var lastCharacter: String {
        let result = String(word.suffix(1))
        AppLogger.shared.debug("単語 '\(word)' の最後の文字: \(result)")
        return result
    }
    
    var endsWithN: Bool {
        let result = lastCharacter == "ん"
        AppLogger.shared.debug("単語 '\(word)' は「ん」で終わる: \(result)")
        return result
    }
    
    // MARK: - イニシャライザ
    public init(word: String, playerName: String) {
        AppLogger.shared.info("新しい単語を作成: '\(word)' by \(playerName)")
        self.word = word
        self.playerName = playerName
        self.createdAt = Date()
    }
    
    // MARK: - メソッド
    func canFollow(_ previousWord: Word) -> Bool {
        let canFollow = previousWord.lastCharacter == self.firstCharacter
        AppLogger.shared.debug("しりとり判定: '\(previousWord.word)'(\(previousWord.lastCharacter)) → '\(self.word)'(\(self.firstCharacter)) = \(canFollow)")
        return canFollow
    }
}