//
//  WordModelTests.swift
//  ShiritoriAppTests
//
//  Created on 2025/07/12
//

import Testing
import Foundation
import SwiftData
@testable import ShiritoriCore

struct WordModelTests {
    
    @Test func testWordCreation() {
        // Given
        let wordText = "りんご"
        let playerName = "たろう"
        
        // When
        let word = Word(word: wordText, playerName: playerName)
        
        // Then
        #expect(word.word == wordText)
        #expect(word.playerName == playerName)
        #expect(word.createdAt <= Date())
    }
    
    @Test func testWordFirstCharacter() {
        // Given
        let word = Word(word: "りんご", playerName: "テスト")
        
        // When
        let firstChar = word.firstCharacter
        
        // Then
        #expect(firstChar == "り")
    }
    
    @Test func testWordLastCharacter() {
        // Given
        let word = Word(word: "りんご", playerName: "テスト")
        
        // When
        let lastChar = word.lastCharacter
        
        // Then
        #expect(lastChar == "ご")
    }
    
    @Test func testWordCanFollow() {
        // Given
        let previousWord = Word(word: "りんご", playerName: "プレイヤー1")
        let nextWord = Word(word: "ごりら", playerName: "プレイヤー2")
        let invalidNextWord = Word(word: "あひる", playerName: "プレイヤー2")
        
        // When & Then
        #expect(nextWord.canFollow(previousWord))
        #expect(!invalidNextWord.canFollow(previousWord))
    }
    
    @Test func testWordEndsWithN() {
        // Given
        let wordWithN = Word(word: "みかん", playerName: "テスト")
        let wordWithoutN = Word(word: "りんご", playerName: "テスト")
        
        // When & Then
        #expect(wordWithN.endsWithN)
        #expect(!wordWithoutN.endsWithN)
    }
}