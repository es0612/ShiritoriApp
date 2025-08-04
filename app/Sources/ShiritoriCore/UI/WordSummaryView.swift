import SwiftUI

/// 単語サマリー表示コンポーネント
public struct WordSummaryView: View {
    public let usedWords: [String]
    
    @State private var showAllWords = false
    @Environment(\.colorScheme) private var colorScheme
    
    public init(usedWords: [String]) {
        AppLogger.shared.debug("WordSummaryView初期化: 単語数=\(usedWords.count)")
        self.usedWords = usedWords
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            if usedWords.isEmpty {
                emptyState
            } else {
                wordGrid
                
                if usedWords.count > 6 {
                    toggleButton
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.1))
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var adaptiveCardBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color.white
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.bubble")
                .font(.largeTitle)
                .foregroundColor(.gray.opacity(0.5))
            
            Text("つかった ことばが ありません")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(height: 80)
    }
    
    private var wordGrid: some View {
        let displayWords = showAllWords ? usedWords : Array(usedWords.prefix(6))
        
        return LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(Array(displayWords.enumerated()), id: \.offset) { index, word in
                WordChip(
                    word: word,
                    index: index,
                    isLatest: index == usedWords.count - 1
                )
            }
        }
    }
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 12)
        ]
    }
    
    private var toggleButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                showAllWords.toggle()
            }
        }) {
            HStack(spacing: 8) {
                Text(showAllWords ? "すくなく表示" : "もっと表示")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Image(systemName: showAllWords ? "chevron.up" : "chevron.down")
                    .font(.caption)
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue.opacity(0.1))
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

/// 単語チップコンポーネント
private struct WordChip: View {
    let word: String
    let index: Int
    let isLatest: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var adaptiveCardBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color.white
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(word)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isLatest ? .white : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text("\(index + 1)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(isLatest ? .white.opacity(0.8) : .gray)
        }
        .frame(minWidth: 80, minHeight: 50)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isLatest ? Color.blue : adaptiveCardBackgroundColor)
                .stroke(isLatest ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1.5)
                .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
        )
        .scaleEffect(isLatest ? 1.05 : 1.0)
    }
}