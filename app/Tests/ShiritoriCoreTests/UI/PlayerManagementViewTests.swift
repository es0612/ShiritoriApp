import Testing
import SwiftUI
@testable import ShiritoriCore

struct PlayerManagementViewTests {
    
    @Test func testPlayerManagementViewCreation() {
        // Given
        var dismissCalled = false
        
        // When
        let view = PlayerManagementView(
            onDismiss: { dismissCalled = true }
        )
        
        // Then
        #expect(dismissCalled == false)
    }
    
    @Test func testPlayerCardViewCreation() {
        // Given
        let playerName = "たろうくん"
        let gamesPlayed = 5
        let gamesWon = 3
        var editCalled = false
        var deleteCalled = false
        
        // When
        let card = PlayerCardView(
            playerName: playerName,
            gamesPlayed: gamesPlayed,
            gamesWon: gamesWon,
            onEdit: { editCalled = true },
            onDelete: { deleteCalled = true }
        )
        
        // Then
        #expect(card.playerName == playerName)
        #expect(card.gamesPlayed == gamesPlayed)
        #expect(card.gamesWon == gamesWon)
        #expect(editCalled == false)
        #expect(deleteCalled == false)
    }
    
    @Test func testPlayerCardViewWithZeroGames() {
        // Given
        let playerName = "はなちゃん"
        let gamesPlayed = 0
        let gamesWon = 0
        
        // When
        let card = PlayerCardView(
            playerName: playerName,
            gamesPlayed: gamesPlayed,
            gamesWon: gamesWon,
            onEdit: {},
            onDelete: {}
        )
        
        // Then
        #expect(card.playerName == playerName)
        #expect(card.gamesPlayed == 0)
        #expect(card.gamesWon == 0)
    }
    
    @Test func testAddPlayerSheetCreation() {
        // Given
        let isPresented = true
        var saveCalled = false
        var cancelCalled = false
        
        // When
        let sheet = AddPlayerSheet(
            isPresented: .constant(isPresented),
            onSave: { _ in saveCalled = true },
            onCancel: { cancelCalled = true }
        )
        
        // Then
        #expect(saveCalled == false)
        #expect(cancelCalled == false)
    }
    
    @Test func testPlayerStatsDisplayCreation() {
        // Given
        let gamesPlayed = 10
        let gamesWon = 7
        let winRate = 0.7
        
        // When
        let stats = PlayerStatsDisplay(
            gamesPlayed: gamesPlayed,
            gamesWon: gamesWon,
            winRate: winRate
        )
        
        // Then
        #expect(stats.gamesPlayed == gamesPlayed)
        #expect(stats.gamesWon == gamesWon)
        #expect(stats.winRate == winRate)
    }
    
    @Test func testPlayerStatsDisplayWithPerfectWinRate() {
        // Given
        let gamesPlayed = 5
        let gamesWon = 5
        let winRate = 1.0
        
        // When
        let stats = PlayerStatsDisplay(
            gamesPlayed: gamesPlayed,
            gamesWon: gamesWon,
            winRate: winRate
        )
        
        // Then
        #expect(stats.gamesPlayed == gamesPlayed)
        #expect(stats.gamesWon == gamesWon)
        #expect(stats.winRate == winRate)
    }
    
    @Test func testEmptyPlayerListViewCreation() {
        // Given
        var addPlayerCalled = false
        
        // When
        let emptyView = EmptyPlayerListView(
            onAddPlayer: { addPlayerCalled = true }
        )
        
        // Then
        #expect(addPlayerCalled == false)
    }
}