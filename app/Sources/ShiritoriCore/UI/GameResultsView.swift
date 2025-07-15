import SwiftUI

/// ゲーム結果画面
public struct GameResultsView: View {
    public let winner: GameParticipant?
    public let gameData: GameSetupData
    public let usedWords: [String]
    public let gameDuration: Int
    public let eliminationHistory: [(playerId: String, reason: String, order: Int)]
    private let onReturnToTitle: () -> Void
    private let onPlayAgain: () -> Void
    
    @State private var showConfetti = false
    @State private var showStats = false
    
    public init(
        winner: GameParticipant?,
        gameData: GameSetupData,
        usedWords: [String],
        gameDuration: Int,
        eliminationHistory: [(playerId: String, reason: String, order: Int)] = [],
        onReturnToTitle: @escaping () -> Void,
        onPlayAgain: @escaping () -> Void
    ) {
        AppLogger.shared.info("GameResultsView初期化: 勝者=\(winner?.name ?? "なし"), 単語数=\(usedWords.count), 脱落履歴=\(eliminationHistory.count)件")
        self.winner = winner
        self.gameData = gameData
        self.usedWords = usedWords
        self.gameDuration = gameDuration
        self.eliminationHistory = eliminationHistory
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
                VStack(spacing: 24) {
                    // 大きな勝利タイトル
                    Text("🏆 ゆうしょう！")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .orange.opacity(0.5), radius: 8, x: 0, y: 4)
                        .scaleEffect(showStats ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showStats)
                    
                    VStack(spacing: 20) {
                        // 大きなプレイヤーアバター
                        PlayerAvatarView(
                            playerName: winner.name,
                            imageData: nil,
                            size: 140
                        )
                        .overlay(
                            // 金色の輝くリング
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.yellow, .orange, .yellow],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 6
                                )
                                .scaleEffect(pulseScale)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseScale)
                        )
                        .shadow(color: .yellow.opacity(0.6), radius: 12, x: 0, y: 6)
                        
                        // 勝者名（非常に大きく表示）
                        Text(winner.name)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                            .scaleEffect(bounceScale)
                            .animation(.spring(response: 0.8, dampingFraction: 0.5), value: bounceScale)
                        
                        Text(winner.type.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                    }
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.yellow.opacity(0.3),
                                    Color.orange.opacity(0.2),
                                    Color.white.opacity(0.9)
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 200
                            )
                        )
                        .stroke(
                            LinearGradient(
                                colors: [.yellow, .orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .shadow(color: .orange.opacity(0.4), radius: 12, x: 0, y: 8)
                )
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.3).delay(0.5)) {
                        bounceScale = 1.1
                    }
                    withAnimation(.easeInOut(duration: 0.3).delay(0.8)) {
                        bounceScale = 1.0
                    }
                    pulseScale = 1.2
                }
            } else {
                VStack(spacing: 20) {
                    Text("🤝 ひきわけ")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Text("みんな よくがんばりました！")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(28)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.2),
                                    Color.cyan.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .stroke(Color.blue, lineWidth: 3)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
        }
    }
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var bounceScale: CGFloat = 1.0
    
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
        VStack(spacing: 20) {
            // 操作ガイダンス
            Text("下のボタンを押してください")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .padding(.bottom, 8)
            
            VStack(spacing: 16) {
                // もう一度プレイボタン（大きく強調）
                Button(action: {
                    AppLogger.shared.info("もう一度プレイボタンタップ")
                    onPlayAgain()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title2)
                        Text("もういちど あそぶ")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .scaleEffect(buttonScale)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: buttonScale)
                
                // タイトルに戻るボタン（目立つように配色変更）
                Button(action: {
                    AppLogger.shared.info("タイトルに戻るボタンタップ")
                    onReturnToTitle()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "house.circle.fill")
                            .font(.title2)
                        Text("タイトルに もどる")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .scaleEffect(buttonScale)
                .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1), value: buttonScale)
            }
        }
        .padding(.top, 30)
        .onAppear {
            // ボタンのアニメーション効果
            withAnimation(.easeInOut(duration: 0.3).delay(1.5)) {
                buttonScale = 1.05
            }
            withAnimation(.easeInOut(duration: 0.3).delay(1.8)) {
                buttonScale = 1.0
            }
        }
    }
    
    @State private var buttonScale: CGFloat = 0.9
    
    private func calculateAverageWordTime() -> Double {
        guard usedWords.count > 0 else { return 0.0 }
        return Double(gameDuration) / Double(usedWords.count)
    }
    
    private func generateRankings() -> [PlayerRanking] {
        var rankings: [PlayerRanking] = []
        
        for (index, participant) in gameData.participants.enumerated() {
            // 各プレイヤーの貢献単語数を計算（簡易版）
            let wordsCount = max(1, usedWords.count / gameData.participants.count)
            
            // 脱落情報を検索
            let eliminationInfo = eliminationHistory.first { $0.playerId == participant.id }
            let eliminationOrder = eliminationInfo?.order
            let eliminationReason = eliminationInfo?.reason
            
            // 勝者判定
            let isWinner = winner?.id == participant.id
            
            // ランク計算：勝者が1位、脱落順によって順位を決定
            let rank: Int
            if isWinner {
                rank = 1
            } else if let elimOrder = eliminationOrder {
                // 脱落順に基づいて順位決定（最後に脱落した人が最高順位）
                rank = gameData.participants.count - elimOrder + 1
            } else {
                // 脱落していない場合（引き分けなど）
                rank = index + 1
            }
            
            let ranking = PlayerRanking(
                participant: participant,
                wordsContributed: wordsCount,
                rank: rank,
                eliminationOrder: eliminationOrder,
                eliminationReason: eliminationReason,
                isWinner: isWinner
            )
            
            rankings.append(ranking)
        }
        
        // ランクでソート（1位が最初）
        return rankings.sorted { $0.rank < $1.rank }
    }
}