//
//  ShiritoriRuleEngineTests.swift
//  ShiritoriAppTests
//
//  Created on 2025/07/12
//

import Testing
import Foundation
@testable import ShiritoriCore

struct ShiritoriRuleEngineTests {
    
    @Test func testValidShiritoriChain() {
        // Given
        let engine = ShiritoriRuleEngine()
        let words = ["りんご", "ごりら", "らっぱ"]
        
        // When
        let result = engine.validateShiritoriChain(words)
        
        // Then
        #expect(result.isValid == true)
        #expect(result.errorType == nil)
    }
    
    @Test func testInvalidShiritoriChain() {
        // Given
        let engine = ShiritoriRuleEngine()
        let words = ["りんご", "あひる"] // 「ご」→「あ」は無効
        
        // When
        let result = engine.validateShiritoriChain(words)
        
        // Then
        #expect(result.isValid == false)
        #expect(result.errorType == .invalidConnection)
    }
    
    @Test func testWordEndingWithN() {
        // Given
        let engine = ShiritoriRuleEngine()
        let words = ["りんご", "ごりら", "らいおん"]
        
        // When
        let result = engine.validateShiritoriChain(words)
        
        // Then
        #expect(result.isValid == false)
        #expect(result.errorType == .endsWithN)
    }
    
    @Test func testDuplicateWord() {
        // Given
        let engine = ShiritoriRuleEngine()
        let words = ["りんご", "ごりら", "らいおん", "んぼうし", "しまうま", "まりも", "もも", "ももたろう"]
        // 「もも」が重複
        let duplicateWords = words + ["もも"]
        
        // When
        let result = engine.validateShiritoriChain(duplicateWords)
        
        // Then
        #expect(result.isValid == false)
        #expect(result.errorType == .duplicateWord)
    }
    
    @Test func testCanWordFollow() {
        // Given
        let engine = ShiritoriRuleEngine()
        
        // When & Then
        #expect(engine.canWordFollow(previousWord: "りんご", nextWord: "ごりら"))
        #expect(!engine.canWordFollow(previousWord: "りんご", nextWord: "あひる"))
    }
    
    @Test func testIsWordValidForShiritori() {
        // Given
        let engine = ShiritoriRuleEngine()
        
        // When & Then
        #expect(engine.isWordValidForShiritori("りんご"))
        #expect(!engine.isWordValidForShiritori("みかん")) // 「ん」で終わる
        #expect(!engine.isWordValidForShiritori("")) // 空文字
    }
    
    @Test func testFindUsedWords() {
        // Given
        let engine = ShiritoriRuleEngine()
        let existingWords = ["りんご", "ごりら", "らっぱ"]
        
        // When
        let usedWords = engine.findUsedWords("ごりら", in: existingWords)
        
        // Then
        #expect(usedWords.count == 1)
        #expect(usedWords.first == "ごりら")
    }
}