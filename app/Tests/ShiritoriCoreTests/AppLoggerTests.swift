//
//  AppLoggerTests.swift
//  ShiritoriAppTests
//
//  Created on 2025/07/12
//

import Testing
import Foundation
@testable import ShiritoriCore

struct AppLoggerTests {
    
    @Test func testLoggerSingletonInstance() {
        // Given & When
        let logger1 = AppLogger.shared
        let logger2 = AppLogger.shared
        
        // Then
        #expect(logger1 === logger2)
    }
    
    @Test func testLogDebugMessage() {
        // Given
        let logger = AppLogger.shared
        let testMessage = "デバッグメッセージのテスト-\(UUID().uuidString)"
        
        // When
        logger.debug(testMessage)
        
        // Then
        // 特定のメッセージを持つログが存在することを確認
        let allLogs = logger.getAllLogs()
        let newLog = allLogs.first { $0.message == testMessage }
        #expect(newLog != nil)
        #expect(newLog?.level == .debug)
        #expect(newLog?.message == testMessage)
    }
    
    @Test func testLogLevels() {
        // Given
        let logger = AppLogger.shared
        
        // When & Then
        logger.debug("デバッグ")
        #expect(logger.getLastLog()?.level == .debug)
        
        logger.info("情報")
        #expect(logger.getLastLog()?.level == .info)
        
        logger.warning("警告")
        #expect(logger.getLastLog()?.level == .warning)
        
        logger.error("エラー")
        #expect(logger.getLastLog()?.level == .error)
    }
    
    @Test func testLogWithFileAndFunction() {
        // Given
        let logger = AppLogger.shared
        let message = "ファイル情報付きログ"
        
        // When
        logger.info(message, file: "TestFile.swift", function: "testFunction()", line: 42)
        
        // Then
        let lastLog = logger.getLastLog()
        #expect(lastLog?.file == "TestFile.swift")
        #expect(lastLog?.function == "testFunction()")
        #expect(lastLog?.line == 42)
    }
}