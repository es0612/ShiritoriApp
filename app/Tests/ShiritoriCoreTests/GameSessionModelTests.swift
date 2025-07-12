//
//  GameSessionModelTests.swift
//  ShiritoriAppTests
//
//  Created on 2025/07/12
//

import Testing
import Foundation
import SwiftData
@testable import ShiritoriCore

struct GameSessionModelTests {
    
    @Test func testGameSessionCreation() {
        // Given
        let playerNames = ["たろう", "はなこ"]
        
        // When
        let gameSession = GameSession(playerNames: playerNames)
        
        // Then
        #expect(gameSession.playerNames == playerNames)
        #expect(gameSession.isCompleted == false)
        #expect(gameSession.winnerName == nil)
        #expect(gameSession.createdAt <= Date())
        #expect(gameSession.completedAt == nil)
        #expect(gameSession.wordsUsed.isEmpty)
    }
    
    @Test func testGameSessionCompletion() {
        // Given
        let gameSession = GameSession(playerNames: ["プレイヤー1", "プレイヤー2"])
        let winnerName = "プレイヤー1"
        
        // When
        gameSession.completeGame(winner: winnerName)
        
        // Then
        #expect(gameSession.isCompleted == true)
        #expect(gameSession.winnerName == winnerName)
        #expect(gameSession.completedAt != nil)
    }
    
    @Test func testAddWordToSession() {
        // Given
        let gameSession = GameSession(playerNames: ["テスト"])
        let word = "りんご"
        let playerName = "テスト"
        
        // When
        gameSession.addWord(word, by: playerName)
        
        // Then
        #expect(gameSession.wordsUsed.count == 1)
        #expect(gameSession.wordsUsed.first?.word == word)
        #expect(gameSession.wordsUsed.first?.playerName == playerName)
    }
}