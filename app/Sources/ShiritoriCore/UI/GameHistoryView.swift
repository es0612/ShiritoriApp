import SwiftUI
import SwiftData

/// ゲーム履歴一覧表示画面
public struct GameHistoryView: View {
    private let onDismiss: () -> Void
    
    @Query(
        filter: #Predicate<GameSession> { session in 
            session.isCompleted 
        },
        sort: \GameSession.createdAt,
        order: .reverse
    ) private var gameHistory: [GameSession]
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedSession: GameSession?
    
    // UIState統合による状態管理
    @State private var uiState = UIState.shared
    
    private var showDetailView: Bool {
        uiState.getTransitionPhase("gameHistory_detailView") == "shown"
    }
    
    private var showDetailViewBinding: Binding<Bool> {
        Binding(
            get: { showDetailView },
            set: { newValue in
                if newValue {
                    uiState.setTransitionPhase("shown", for: "gameHistory_detailView")
                } else {
                    uiState.setTransitionPhase("hidden", for: "gameHistory_detailView")
                }
            }
        )
    }
    
    public init(onDismiss: @escaping () -> Void) {
        AppLogger.shared.debug("GameHistoryView初期化")
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
                ChildFriendlyBackground(animationSpeed: 0.3)
                
                VStack {
                    // 戻るボタンを上部に配置
                    BackButton {
                        AppLogger.shared.info("ゲーム履歴画面を閉じる")
                        onDismiss()
                    }
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // ヘッダー
                            VStack(spacing: 8) {
                                Text("📈 ゲーム れきし")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                
                                Text("いままで あそんだ ゲームを みよう")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 8)
                        
                        // 履歴統計情報
                        GameHistoryStatsCard(gameHistory: gameHistory)
                        
                        // 履歴一覧
                        if gameHistory.isEmpty {
                            EmptyHistoryView()
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(gameHistory, id: \.id) { session in
                                    GameHistoryCard(
                                        session: session,
                                        onTap: {
                                            AppLogger.shared.info("ゲーム履歴詳細表示: セッションID=\(session.id)")
                                            selectedSession = session
                                            uiState.setTransitionPhase("shown", for: "gameHistory_detailView")
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                            Spacer(minLength: 100)
                        }
                    }
                }
            }
        .sheet(isPresented: showDetailViewBinding) {
            if let session = selectedSession {
                GameHistoryDetailView(
                    session: session,
                    onDismiss: {
                        uiState.setTransitionPhase("hidden", for: "gameHistory_detailView")
                        selectedSession = nil
                    }
                )
            }
        }
        .onAppear {
            AppLogger.shared.info("ゲーム履歴画面表示: 履歴件数=\(gameHistory.count)")
        }
    }

/// 履歴統計カード
private struct GameHistoryStatsCard: View {
    let gameHistory: [GameSession]
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color.white
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("📊 とうけい")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            HStack(spacing: 16) {
                StatItem(
                    icon: "🎮",
                    title: "ゲーム数",
                    value: "\(gameHistory.count)",
                    color: .blue
                )
                
                StatItem(
                    icon: "📝",
                    title: "たんご数",
                    value: "\(totalWordsUsed)",
                    color: .green
                )
                
                StatItem(
                    icon: "⏱️",
                    title: "へいきん じかん",
                    value: averageGameDuration,
                    color: .orange
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackgroundColor)
                .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    private var totalWordsUsed: Int {
        gameHistory.reduce(0) { total, session in
            total + session.usedWords.count
        }
    }
    
    private var averageGameDuration: String {
        guard !gameHistory.isEmpty else { return "0分" }
        
        let totalDuration = gameHistory.reduce(into: 0.0) { total, session in
            total += session.gameDuration
        }
        
        let averageMinutes = totalDuration / Double(gameHistory.count) / 60.0
        return String(format: "%.1f分", averageMinutes)
    }
}

/// 統計アイテム
private struct StatItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title2)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

/// ゲーム履歴カード
private struct GameHistoryCard: View {
    let session: GameSession
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color.white
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー行
                HStack {
                    Text(winnerIcon)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(gameTitle)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text(formatDate(session.createdAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // ゲーム詳細行
                HStack(spacing: 16) {
                    DetailItem(
                        icon: "👥",
                        text: "\(session.participantNames.count)人"
                    )
                    
                    DetailItem(
                        icon: "📝",
                        text: "\(session.usedWords.count)たんご"
                    )
                    
                    DetailItem(
                        icon: "⏱️",
                        text: formatDuration(session.gameDuration)
                    )
                    
                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardBackgroundColor)
                    .shadow(color: shadowColor, radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var winnerIcon: String {
        // 新しいGameCompletionTypeシステムを使用してアイコンを決定
        return session.completionType.iconName
    }
    
    private var gameTitle: String {
        switch session.completionType {
        case .completed:
            if let winner = session.winnerName {
                return "\(winner) の かち！"
            } else {
                // 完了だが勝者がいない場合（異常なケースだが安全のため）
                return session.completionType.displayName
            }
        case .draw:
            return session.completionType.displayName
        case .abandoned:
            return session.completionType.displayName
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

/// 詳細アイテム
private struct DetailItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(icon)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// 空の履歴表示
private struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("📝")
                .font(.system(size: 60))
            
            Text("まだ ゲームを あそんでいません")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            
            Text("しりとりゲームを あそぶと\nここに きろくが のこるよ")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    GameHistoryView(onDismiss: {})
}
}