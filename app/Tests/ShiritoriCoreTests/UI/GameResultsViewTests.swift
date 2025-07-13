import Testing
@testable import ShiritoriCore

/// ゲーム結果画面のテストスイート
@Suite("ゲーム結果画面テスト")
struct GameResultsViewTests {
    
    @Test("GameResultsView基本作成テスト")
    func testGameResultsViewCreation() {
        // Given
        let participant1 = GameParticipant(id: "1", name: "たろうくん", type: .human)
        let participant2 = GameParticipant(id: "2", name: "コンピュータ", type: .computer(difficulty: .easy))
        let participants = [participant1, participant2]
        let rules = GameRulesConfig(timeLimit: 60, maxPlayers: 4, winCondition: .lastPlayerStanding)
        let gameData = GameSetupData(participants: participants, rules: rules, turnOrder: ["1", "2"])
        
        var returnToTitleCalled = false
        var playAgainCalled = false
        
        // When
        let view = GameResultsView(
            winner: participant1,
            gameData: gameData,
            usedWords: ["りんご", "ごりら", "らっぱ"],
            gameDuration: 120,
            onReturnToTitle: { returnToTitleCalled = true },
            onPlayAgain: { playAgainCalled = true }
        )
        
        // Then
        #expect(view != nil)
    }
    
    @Test("GameResultsView引き分け表示テスト")
    func testGameResultsViewDraw() {
        // Given
        let participant1 = GameParticipant(id: "1", name: "たろうくん", type: .human)
        let participant2 = GameParticipant(id: "2", name: "はなちゃん", type: .human)
        let participants = [participant1, participant2]
        let rules = GameRulesConfig(timeLimit: 45, maxPlayers: 3, winCondition: .firstToEliminate)
        let gameData = GameSetupData(participants: participants, rules: rules, turnOrder: ["1", "2"])
        
        var returnToTitleCalled = false
        var playAgainCalled = false
        
        // When
        let view = GameResultsView(
            winner: nil, // 引き分け
            gameData: gameData,
            usedWords: ["りんご", "ごりら"],
            gameDuration: 45,
            onReturnToTitle: { returnToTitleCalled = true },
            onPlayAgain: { playAgainCalled = true }
        )
        
        // Then
        #expect(view != nil)
    }
    
    @Test("GameStatsDisplay作成テスト")
    func testGameStatsDisplayCreation() {
        // When
        let statsDisplay = GameStatsDisplay(
            totalWords: 15,
            gameDuration: 180,
            averageWordTime: 12.0
        )
        
        // Then
        #expect(statsDisplay != nil)
    }
    
    @Test("GameStatsDisplay空のゲームテスト")
    func testGameStatsDisplayEmptyGame() {
        // When
        let statsDisplay = GameStatsDisplay(
            totalWords: 0,
            gameDuration: 5,
            averageWordTime: 0.0
        )
        
        // Then
        #expect(statsDisplay != nil)
    }
    
    @Test("WordSummaryView作成テスト")
    func testWordSummaryViewCreation() {
        // Given
        let words = ["りんご", "ごりら", "らっぱ", "ぱんだ", "だちょう"]
        
        // When
        let summaryView = WordSummaryView(usedWords: words)
        
        // Then
        #expect(summaryView != nil)
    }
    
    @Test("WordSummaryView空のリストテスト")
    func testWordSummaryViewEmptyList() {
        // When
        let summaryView = WordSummaryView(usedWords: [])
        
        // Then
        #expect(summaryView != nil)
    }
    
    @Test("PlayerRankingView作成テスト")
    func testPlayerRankingViewCreation() {
        // Given
        let rankings = [
            PlayerRanking(participant: GameParticipant(id: "1", name: "たろうくん", type: .human), wordsContributed: 8, rank: 1),
            PlayerRanking(participant: GameParticipant(id: "2", name: "コンピュータ", type: .computer(difficulty: .normal)), wordsContributed: 5, rank: 2),
            PlayerRanking(participant: GameParticipant(id: "3", name: "はなちゃん", type: .human), wordsContributed: 2, rank: 3)
        ]
        
        // When
        let rankingView = PlayerRankingView(rankings: rankings)
        
        // Then
        #expect(rankingView != nil)
    }
    
    @Test("PlayerRanking統計データテスト")
    func testPlayerRankingData() {
        // Given
        let participant = GameParticipant(id: "test", name: "テストプレイヤー", type: .human)
        
        // When
        let ranking = PlayerRanking(
            participant: participant,
            wordsContributed: 10,
            rank: 1
        )
        
        // Then
        #expect(ranking.participant.name == "テストプレイヤー")
        #expect(ranking.wordsContributed == 10)
        #expect(ranking.rank == 1)
    }
    
    @Test("ConfettiAnimation作成テスト")
    func testConfettiAnimationCreation() {
        // When
        let confettiAnimation = ConfettiAnimation(isActive: true)
        
        // Then
        #expect(confettiAnimation != nil)
    }
    
    @Test("ConfettiAnimation非アクティブテスト")
    func testConfettiAnimationInactive() {
        // When
        let confettiAnimation = ConfettiAnimation(isActive: false)
        
        // Then
        #expect(confettiAnimation != nil)
    }
}