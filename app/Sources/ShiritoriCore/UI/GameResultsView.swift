import SwiftUI

/// ゲーム結果画面
public struct GameResultsView: View {
    public let winner: GameParticipant?
    public let gameData: GameSetupData
    public let usedWords: [String]
    public let gameDuration: Int
    private let onReturnToTitle: () -> Void
    private let onPlayAgain: () -> Void
    
    @State private var showConfetti = false
    @State private var showStats = false
    
    public init(
        winner: GameParticipant?,
        gameData: GameSetupData,
        usedWords: [String],
        gameDuration: Int,
        onReturnToTitle: @escaping () -> Void,
        onPlayAgain: @escaping () -> Void
    ) {
        AppLogger.shared.info("GameResultsView初期化: 勝者=\(winner?.name ?? "なし"), 単語数=\(usedWords.count)")
        self.winner = winner
        self.gameData = gameData
        self.usedWords = usedWords
        self.gameDuration = gameDuration
        self.onReturnToTitle = onReturnToTitle
        self.onPlayAgain = onPlayAgain
    }
    
    public var body: some View {
        ZStack {
            // 背景
            ChildFriendlyBackground(animationSpeed: 0.5)
            
            // 紙吹雪アニメーション
            if showConfetti {
                ConfettiAnimation(isActive: showConfetti)
            }
            
            ScrollView {
                VStack(spacing: 30) {
                    // ヘッダー
                    resultHeader
                    
                    // 勝者表示
                    winnerDisplay
                    
                    // ゲーム統計
                    if showStats {
                        gameStatsSection
                    }
                    
                    // 単語サマリー
                    wordSummarySection
                    
                    // プレイヤーランキング
                    playerRankingSection
                    
                    // アクションボタン
                    actionButtons
                }
                .padding()
            }
        }
        .onAppear {
            // 勝者がいる場合は紙吹雪アニメーション開始
            if winner != nil {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showConfetti = true
                }
            }
            
            // 統計情報を遅延表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showStats = true
                }
            }
        }
    }
    
    private var resultHeader: some View {
        VStack(spacing: 16) {
            Text("🎉 ゲーム終了")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("おつかれさまでした！")
                .font(.title2)
                .foregroundColor(.gray)
        }
    }
    
    private var winnerDisplay: some View {
        Group {
            if let winner = winner {
                VStack(spacing: 20) {
                    Text("🏆 ゆうしょう")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    VStack(spacing: 12) {
                        PlayerAvatarView(
                            playerName: winner.name,
                            imageData: nil,
                            size: 100
                        )
                        
                        Text(winner.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text(winner.type.displayName)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.yellow.opacity(0.2))
                        .stroke(Color.orange, lineWidth: 3)
                )
            } else {
                VStack(spacing: 16) {
                    Text("🤝 ひきわけ")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("みんな よくがんばりました！")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue.opacity(0.2))
                        .stroke(Color.blue, lineWidth: 2)
                )
            }
        }
    }
    
    private var gameStatsSection: some View {
        VStack(spacing: 16) {
            Text("📊 ゲームのきろく")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            GameStatsDisplay(
                totalWords: usedWords.count,
                gameDuration: gameDuration,
                averageWordTime: calculateAverageWordTime()
            )
        }
    }
    
    private var wordSummarySection: some View {
        VStack(spacing: 16) {
            Text("📝 つかったことば")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            WordSummaryView(usedWords: usedWords)
        }
    }
    
    private var playerRankingSection: some View {
        VStack(spacing: 16) {
            Text("🏅 プレイヤーランキング")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            PlayerRankingView(rankings: generateRankings())
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            ChildFriendlyButton(
                title: "🔄 もういちど",
                backgroundColor: .green,
                foregroundColor: .white
            ) {
                AppLogger.shared.info("もう一度プレイボタンタップ")
                onPlayAgain()
            }
            
            ChildFriendlyButton(
                title: "🏠 タイトルにもどる",
                backgroundColor: .gray,
                foregroundColor: .white
            ) {
                AppLogger.shared.info("タイトルに戻るボタンタップ")
                onReturnToTitle()
            }
        }
        .padding(.top, 20)
    }
    
    private func calculateAverageWordTime() -> Double {
        guard usedWords.count > 0 else { return 0.0 }
        return Double(gameDuration) / Double(usedWords.count)
    }
    
    private func generateRankings() -> [PlayerRanking] {
        // 簡易的なランキング生成（実際の実装では単語貢献度などを計算）
        return gameData.participants.enumerated().map { index, participant in
            let wordsCount = max(1, usedWords.count / gameData.participants.count)
            return PlayerRanking(
                participant: participant,
                wordsContributed: wordsCount,
                rank: index + 1
            )
        }
    }
}