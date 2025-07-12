//
//  WordDictionaryServiceTests.swift
//  ShiritoriAppTests
//
//  Created on 2025/07/12
//

import Testing
import Foundation
@testable import ShiritoriCore

struct WordDictionaryServiceTests {
    
    @Test func testGetWordsStartingWith() {
        // Given
        let service = WordDictionaryService()
        
        // When
        let words = service.getWordsStartingWith("り", difficulty: .easy)
        
        // Then
        #expect(!words.isEmpty)
        #expect(words.allSatisfy { $0.hasPrefix("り") })
    }
    
    @Test func testDifficultyLevels() {
        // Given
        let service = WordDictionaryService()
        
        // When
        let easyWords = service.getWordsStartingWith("あ", difficulty: .easy)
        let normalWords = service.getWordsStartingWith("あ", difficulty: .normal)
        let hardWords = service.getWordsStartingWith("あ", difficulty: .hard)
        
        // Then
        #expect(!easyWords.isEmpty)
        #expect(!normalWords.isEmpty)
        #expect(!hardWords.isEmpty)
        
        // 難易度が上がるにつれて語彙数が増える
        #expect(normalWords.count >= easyWords.count)
        #expect(hardWords.count >= normalWords.count)
    }
    
    @Test func testGetRandomWord() {
        // Given
        let service = WordDictionaryService()
        
        // When
        let word1 = service.getRandomWord(startingWith: "か", difficulty: .normal)
        let word2 = service.getRandomWord(startingWith: "か", difficulty: .normal)
        
        // Then
        #expect(word1 != nil)
        #expect(word2 != nil)
        #expect(word1!.hasPrefix("か"))
        #expect(word2!.hasPrefix("か"))
    }
    
    @Test func testGetRandomWordForDifficultCharacter() {
        // Given
        let service = WordDictionaryService()
        
        // When - 「る」で始まる単語（返しにくい）
        let word = service.getRandomWord(startingWith: "る", difficulty: .hard)
        
        // Then
        #expect(word != nil)
        #expect(word!.hasPrefix("る"))
    }
    
    @Test func testIsWordInDictionary() {
        // Given
        let service = WordDictionaryService()
        
        // When & Then
        #expect(service.isWordInDictionary("りんご", difficulty: .easy))
        #expect(service.isWordInDictionary("るーる", difficulty: .hard))
        #expect(!service.isWordInDictionary("でたらめな単語", difficulty: .easy))
    }
    
    @Test func testGetAllWordsForDifficulty() {
        // Given
        let service = WordDictionaryService()
        
        // When
        let easyWords = service.getAllWords(difficulty: .easy)
        let hardWords = service.getAllWords(difficulty: .hard)
        
        // Then
        #expect(!easyWords.isEmpty)
        #expect(!hardWords.isEmpty)
        #expect(hardWords.count > easyWords.count)
    }
    
    @Test func testWordValidation() {
        // Given
        let service = WordDictionaryService()
        
        // When & Then
        #expect(!service.isWordInDictionary("みかん", difficulty: .easy)) // 「ん」で終わる
        #expect(!service.isWordInDictionary("", difficulty: .easy)) // 空文字
    }
}