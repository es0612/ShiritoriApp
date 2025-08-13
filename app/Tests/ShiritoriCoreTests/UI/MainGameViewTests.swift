import Testing
import SwiftUI
@testable import ShiritoriCore

struct MainGameViewTests {
    
    @Test func testMainGameViewCreation() {
        // Given
        let gameData = createSampleGameData()
        var gameEndedCalled = false
        
        // When
        let view = MainGameView(
            gameData: gameData,
            onGameEnd: { _, _, _, _ in gameEndedCalled = true }
        )
        
        // Then
        #expect(view.gameData.participants.count == 2)
        #expect(gameEndedCalled == false)
    }
    
    @Test func testGameStateCreation() {
        // Given
        let gameData = createSampleGameData()
        
        // When
        let gameState = GameState(gameData: gameData)
        
        // Then
        #expect(gameState.currentTurnIndex == 0)
        #expect(gameState.isGameActive == true)
        #expect(gameState.usedWords.isEmpty)
        #expect(gameState.timeRemaining == gameData.rules.timeLimit)
    }
    
    @Test func testGameStateWithCustomTime() {
        // Given
        let rules = GameRulesConfig(timeLimit: 45, maxPlayers: 3, winCondition: .firstToEliminate)
        let gameData = GameSetupData(
            participants: [createHumanParticipant()],
            rules: rules,
            turnOrder: ["human_test"]
        )
        
        // When
        let gameState = GameState(gameData: gameData)
        
        // Then
        #expect(gameState.timeRemaining == 45)
    }
    
    @Test func testCurrentPlayerDisplayCreation() {
        // Given
        let participant = createHumanParticipant()
        let timeRemaining = 30
        
        // When
        let display = CurrentPlayerDisplay(
            participant: participant,
            timeRemaining: timeRemaining
        )
        
        // Then
        #expect(display.participant.name == "テストプレイヤー")
        #expect(display.timeRemaining == timeRemaining)
    }
    
    @Test func testCurrentPlayerDisplayWithComputer() {
        // Given
        let participant = createComputerParticipant()
        let timeRemaining = 60
        
        // When
        let display = CurrentPlayerDisplay(
            participant: participant,
            timeRemaining: timeRemaining
        )
        
        // Then
        #expect(display.participant.type.displayName == "コンピュータ(よわい)")
        #expect(display.timeRemaining == timeRemaining)
    }
    
    @Test func testWordInputViewCreation() {
        // Given
        let isEnabled = true
        var submitCalled = false
        
        // When
        let inputView = WordInputView(
            isEnabled: isEnabled,
            currentPlayerId: "test-player",
            onSubmit: { _ in submitCalled = true }
        )
        
        // Then
        #expect(inputView.isEnabled == true)
        #expect(submitCalled == false)
    }
    
    @Test func testWordInputViewDisabled() {
        // Given
        let isEnabled = false
        
        // When
        let inputView = WordInputView(
            isEnabled: isEnabled,
            currentPlayerId: "test-player",
            onSubmit: { _ in }
        )
        
        // Then
        #expect(inputView.isEnabled == false)
    }
    
    @Test func testGameProgressBarCreation() {
        // Given
        let usedWordsCount = 5
        let totalTurns = 10
        
        // When
        let progressBar = GameProgressBar(
            usedWordsCount: usedWordsCount,
            totalTurns: totalTurns
        )
        
        // Then
        #expect(progressBar.usedWordsCount == usedWordsCount)
        #expect(progressBar.totalTurns == totalTurns)
    }
    
    @Test func testGameProgressBarEmpty() {
        // Given
        let usedWordsCount = 0
        let totalTurns = 5
        
        // When
        let progressBar = GameProgressBar(
            usedWordsCount: usedWordsCount,
            totalTurns: totalTurns
        )
        
        // Then
        #expect(progressBar.usedWordsCount == 0)
        #expect(progressBar.totalTurns == totalTurns)
    }
    
    @Test func testWordHistoryViewCreation() {
        // Given
        let words = ["りんご", "ごりら", "らっぱ"]
        
        // When
        let historyView = WordHistoryView(words: words)
        
        // Then
        #expect(historyView.words.count == 3)
        #expect(historyView.words.first == "りんご")
        #expect(historyView.words.last == "らっぱ")
    }
    
    @Test func testWordHistoryViewEmpty() {
        // Given
        let words: [String] = []
        
        // When
        let historyView = WordHistoryView(words: words)
        
        // Then
        #expect(historyView.words.isEmpty)
    }
    
    // MARK: - Helper Methods
    
    private func createSampleGameData() -> GameSetupData {
        let participants = [
            createHumanParticipant(),
            createComputerParticipant()
        ]
        let rules = GameRulesConfig()
        let turnOrder = participants.map { $0.id }
        
        return GameSetupData(
            participants: participants,
            rules: rules,
            turnOrder: turnOrder
        )
    }
    
    private func createHumanParticipant() -> GameParticipant {
        return GameParticipant(
            id: "human_test",
            name: "テストプレイヤー",
            type: .human
        )
    }
    
    private func createComputerParticipant() -> GameParticipant {
        return GameParticipant(
            id: "computer_easy",
            name: "コンピュータ(よわい)",
            type: .computer(difficulty: .easy)
        )
    }
}