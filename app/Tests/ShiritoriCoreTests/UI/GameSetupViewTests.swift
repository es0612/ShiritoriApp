import Testing
import SwiftUI
@testable import ShiritoriCore

struct GameSetupViewTests {
    
    @Test func testGameSetupViewCreation() {
        // Given
        var startGameCalled = false
        var cancelCalled = false
        
        // When
        let view = GameSetupView(
            onStartGame: { _, _, _ in startGameCalled = true },
            onCancel: { cancelCalled = true }
        )
        
        // Then
        #expect(startGameCalled == false)
        #expect(cancelCalled == false)
    }
    
    @Test func testPlayerSelectionCardCreation() {
        // Given
        let playerName = "たろうくん"
        let isSelected = true
        var selectionChangedCalled = false
        
        // When
        let card = PlayerSelectionCard(
            playerName: playerName,
            isSelected: isSelected,
            onSelectionChanged: { _ in selectionChangedCalled = true }
        )
        
        // Then
        #expect(card.playerName == playerName)
        #expect(card.isSelected == isSelected)
        #expect(selectionChangedCalled == false)
    }
    
    @Test func testPlayerSelectionCardNotSelected() {
        // Given
        let playerName = "はなちゃん"
        let isSelected = false
        
        // When
        let card = PlayerSelectionCard(
            playerName: playerName,
            isSelected: isSelected,
            onSelectionChanged: { _ in }
        )
        
        // Then
        #expect(card.playerName == playerName)
        #expect(card.isSelected == false)
    }
    
    @Test func testComputerPlayerCardCreation() {
        // Given
        let difficultyLevel = DifficultyLevel.normal
        let isSelected = true
        var selectionChangedCalled = false
        
        // When
        let card = ComputerPlayerCard(
            difficultyLevel: difficultyLevel,
            isSelected: isSelected,
            onSelectionChanged: { _ in selectionChangedCalled = true }
        )
        
        // Then
        #expect(card.difficultyLevel == difficultyLevel)
        #expect(card.isSelected == isSelected)
        #expect(selectionChangedCalled == false)
    }
    
    @Test func testComputerPlayerCardAllDifficulties() {
        // Given & When & Then
        for difficulty in DifficultyLevel.allCases {
            let card = ComputerPlayerCard(
                difficultyLevel: difficulty,
                isSelected: false,
                onSelectionChanged: { _ in }
            )
            #expect(card.difficultyLevel == difficulty)
        }
    }
    
    @Test func testGameRulesConfigCreation() {
        // Given
        let timeLimit = 30
        let maxPlayers = 4
        let winCondition = WinCondition.lastPlayerStanding
        
        // When
        let config = GameRulesConfig(
            timeLimit: timeLimit,
            maxPlayers: maxPlayers,
            winCondition: winCondition
        )
        
        // Then
        #expect(config.timeLimit == timeLimit)
        #expect(config.maxPlayers == maxPlayers)
        #expect(config.winCondition == winCondition)
    }
    
    @Test func testGameRulesConfigDefaultValues() {
        // Given & When
        let config = GameRulesConfig()
        
        // Then
        #expect(config.timeLimit == 60)
        #expect(config.maxPlayers == 5)
        #expect(config.winCondition == .lastPlayerStanding)
    }
    
    @Test func testWinConditionEnum() {
        // Given & When & Then
        let conditions = WinCondition.allCases
        #expect(conditions.contains(.lastPlayerStanding))
        #expect(conditions.contains(.firstToEliminate))
        #expect(conditions.count == 2)
    }
    
    @Test func testRulesDisplayCardCreation() {
        // Given
        let timeLimit = 45
        let winCondition = WinCondition.firstToEliminate
        var editCalled = false
        
        // When
        let card = RulesDisplayCard(
            timeLimit: timeLimit,
            winCondition: winCondition,
            onEdit: { editCalled = true }
        )
        
        // Then
        #expect(card.timeLimit == timeLimit)
        #expect(card.winCondition == winCondition)
        #expect(editCalled == false)
    }
}