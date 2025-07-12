//
//  PlayerModelTests.swift
//  ShiritoriAppTests
//
//  Created on 2025/07/12
//

import Testing
import Foundation
import SwiftData
@testable import ShiritoriCore

struct PlayerModelTests {
    
    @Test func testPlayerCreation() {
        // Given
        let name = "たろう"
        let iconImageData = Data([0x01, 0x02, 0x03])
        
        // When
        let player = Player(name: name, iconImageData: iconImageData)
        
        // Then
        #expect(player.name == name)
        #expect(player.iconImageData == iconImageData)
        #expect(player.gamesPlayed == 0)
        #expect(player.gamesWon == 0)
        #expect(player.createdAt <= Date())
    }
    
    @Test func testPlayerWinRate() {
        // Given
        let player = Player(name: "テストプレイヤー", iconImageData: nil)
        player.gamesPlayed = 10
        player.gamesWon = 3
        
        // When
        let winRate = player.winRate
        
        // Then
        #expect(winRate == 0.3)
    }
    
    @Test func testPlayerWinRateWithZeroGames() {
        // Given
        let player = Player(name: "新規プレイヤー", iconImageData: nil)
        
        // When
        let winRate = player.winRate
        
        // Then
        #expect(winRate == 0.0)
    }
    
    @Test func testPlayerUpdateStats() {
        // Given
        let player = Player(name: "プレイヤー", iconImageData: nil)
        
        // When - 勝利の場合
        player.updateStats(won: true)
        
        // Then
        #expect(player.gamesPlayed == 1)
        #expect(player.gamesWon == 1)
        
        // When - 敗北の場合
        player.updateStats(won: false)
        
        // Then
        #expect(player.gamesPlayed == 2)
        #expect(player.gamesWon == 1)
    }
}