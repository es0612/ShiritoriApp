import SwiftUI
import SwiftData

/// ゲーム履歴詳細表示画面
public struct GameHistoryDetailView: View {
    let session: GameSession
    private let onDismiss: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    // UIState統合による状態管理
    @State private var uiState = UIState.shared
    
    private var selectedTab: DetailTab {
        if let tabRawValue = uiState.getTransitionPhase("gameHistoryDetail_selectedTab"),
           let tab = DetailTab(rawValue: tabRawValue) {
            return tab
        }
        return .overview
    }
    
    private var selectedTabBinding: Binding<DetailTab> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                uiState.setTransitionPhase(newTab.rawValue, for: "gameHistoryDetail_selectedTab")
            }
        )
    }
    
    public init(session: GameSession, onDismiss: @escaping () -> Void) {
        AppLogger.shared.debug("GameHistoryDetailView初期化: セッションID=\(session.id)")
        self.session = session
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
                ChildFriendlyBackground(animationSpeed: 0.2)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // ヘッダー
                        GameDetailHeader(session: session)
                        
                        // タブ選択
                        DetailTabSelector(
                            selectedTab: selectedTabBinding,
                            wordCount: session.usedWords.count
                        )
                        
                        // タブコンテンツ
                        Group {
                            switch selectedTab {
                            case .overview:
                                GameOverviewSection(session: session)
                            case .words:
                                GameWordsSection(session: session)
                            case .players:
                                GamePlayersSection(session: session)
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: selectedTab)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
        .onAppear {
            AppLogger.shared.info("ゲーム履歴詳細画面表示: \(session.winnerName ?? session.completionType.displayName)")
        }
    }

/// 詳細タブの種類
private enum DetailTab: String, CaseIterable {
    case overview = "がいよう"
    case words = "たんご"
    case players = "プレイヤー"
    
    var icon: String {
        switch self {
        case .overview: return "📊"
        case .words: return "📝"
        case .players: return "👥"
        }
    }
}

/// ゲーム詳細ヘッダー
private struct GameDetailHeader: View {
    let session: GameSession
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color.white
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 勝者表示
            VStack(spacing: 8) {
                Text(winnerIcon)
                    .font(.system(size: 60))
                
                Text(gameTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(formatDate(session.createdAt))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // 基本統計
            HStack(spacing: 16) {
                StatCard(
                    icon: "👥",
                    title: "プレイヤー",
                    value: "\(session.participantNames.count)",
                    color: .blue
                )
                
                StatCard(
                    icon: "📝",
                    title: "つかった\nたんご",
                    value: "\(session.usedWords.count)",
                    color: .green
                )
                
                StatCard(
                    icon: "⏱️",
                    title: "ゲーム\nじかん",
                    value: formatDuration(session.gameDuration),
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
                return "\(session.completionType.displayName) ゲーム"
            }
        case .draw:
            return "\(session.completionType.displayName) ゲーム"
        case .abandoned:
            return "\(session.completionType.displayName) ゲーム"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
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

/// 統計カード
private struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.16) : Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.title)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackgroundColor)
        )
    }
}

/// 詳細タブセレクター
private struct DetailTabSelector: View {
    @Binding var selectedTab: DetailTab
    let wordCount: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                TabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    wordCount: tab == .words ? wordCount : nil
                ) {
                    selectedTab = tab
                }
            }
        }
        .padding(.horizontal)
    }
}

/// タブボタン
private struct TabButton: View {
    let tab: DetailTab
    let isSelected: Bool
    let wordCount: Int?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(tab.icon)
                    .font(.title3)
                
                HStack(spacing: 2) {
                    Text(tab.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    if let count = wordCount {
                        Text("(\(count))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue : Color.clear)
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

/// ゲーム概要セクション
private struct GameOverviewSection: View {
    let session: GameSession
    
    var body: some View {
        VStack(spacing: 16) {
            SectionCard(title: "🎮 ゲーム じょうほう") {
                GameInfoContent(session: session)
            }
            
            if !session.participantNames.isEmpty {
                SectionCard(title: "👥 さんか した プレイヤー") {
                    ParticipantsList(participantNames: session.participantNames, winnerName: session.winnerName)
                }
            }
        }
    }
}

/// ゲーム情報コンテンツ
private struct GameInfoContent: View {
    let session: GameSession
    
    var body: some View {
        VStack(spacing: 12) {
            InfoRow(label: "かいし じこく", value: formatStartTime(session.createdAt))
            InfoRow(label: "しゅうりょう じこく", value: formatEndTime(session.createdAt, duration: session.gameDuration))
            InfoRow(label: "ゲーム じかん", value: formatDetailedDuration(session.gameDuration))
            InfoRow(label: "つかった たんご すう", value: "\(session.usedWords.count) こ")
        }
    }
    
    private func formatStartTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func formatEndTime(_ startDate: Date, duration: TimeInterval) -> String {
        let endDate = startDate.addingTimeInterval(duration)
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: endDate)
    }
    
    private func formatDetailedDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        if minutes > 0 {
            return "\(minutes)分 \(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }
}

/// 情報行
private struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
    }
}

/// 参加者リスト
private struct ParticipantsList: View {
    let participantNames: [String]
    let winnerName: String?
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(participantNames, id: \.self) { name in
                HStack {
                    Text(winnerName == name ? "🏆" : "👤")
                        .font(.subheadline)
                    
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(winnerName == name ? .bold : .regular)
                        .foregroundColor(winnerName == name ? .orange : .primary)
                    
                    Spacer()
                    
                    if winnerName == name {
                        Text("かち")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
}

/// ゲーム単語セクション
private struct GameWordsSection: View {
    let session: GameSession
    
    var body: some View {
        SectionCard(title: "📝 つかった たんご (\(session.usedWords.count)こ)") {
            if session.usedWords.isEmpty {
                Text("たんごが きろく されていません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(session.usedWords.enumerated()), id: \.offset) { index, word in
                        WordCard(index: index + 1, word: word.word)
                    }
                }
            }
        }
    }
}

/// 単語カード
private struct WordCard: View {
    let index: Int
    let word: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.16) : Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    
    var body: some View {
        HStack {
            Text("\(index)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.blue))
            
            Text(word)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(cardBackgroundColor)
        )
    }
}

/// ゲームプレイヤーセクション
private struct GamePlayersSection: View {
    let session: GameSession
    
    var body: some View {
        SectionCard(title: "👥 プレイヤー せいせき") {
            if session.participantNames.isEmpty {
                Text("プレイヤー じょうほうが ありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(session.participantNames.enumerated()), id: \.offset) { index, name in
                        PlayerCard(
                            name: name,
                            isWinner: name == session.winnerName,
                            rank: calculateRank(for: name, in: session)
                        )
                    }
                }
            }
        }
    }
    
    private func calculateRank(for playerName: String, in session: GameSession) -> Int {
        // 勝者が1位、その他は同率2位として簡易的に実装
        return playerName == session.winnerName ? 1 : 2
    }
}

/// プレイヤーカード
private struct PlayerCard: View {
    let name: String
    let isWinner: Bool
    let rank: Int
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackgroundColor: Color {
        if isWinner {
            return colorScheme == .dark ? Color.orange.opacity(0.2) : Color.orange.opacity(0.1)
        } else {
            return colorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.16) : Color(red: 0.95, green: 0.95, blue: 0.97)
        }
    }
    
    private var borderColor: Color {
        isWinner ? Color.orange : Color.clear
    }
    
    var body: some View {
        HStack {
            Text(isWinner ? "🏆" : "👤")
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("\(rank)位")
                    .font(.caption)
                    .foregroundColor(isWinner ? .orange : .secondary)
            }
            
            Spacer()
            
            if isWinner {
                Text("WIN")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackgroundColor)
                .stroke(borderColor, lineWidth: isWinner ? 2 : 0)
        )
    }
}

/// セクションカード
private struct SectionCard<Content: View>: View {
    let title: String
    let content: Content
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color.white
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackgroundColor)
                .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

#Preview {
    // プレビュー用のダミーデータ
    let dummySession = GameSession(
        participantNames: ["太郎", "花子", "AI"],
        winnerName: "太郎"
    )
    
    GameHistoryDetailView(
        session: dummySession,
        onDismiss: {}
    )
}
}