import SwiftUI

/// 単語履歴表示コンポーネント
public struct WordHistoryView: View {
    public let words: [String]
    
    public init(words: [String]) {
        AppLogger.shared.debug("WordHistoryView初期化: 単語数=\(words.count)")
        self.words = words
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.blue)
                Text("つかった ことば")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Spacer()
                
                if !words.isEmpty {
                    Text("\(words.count)こ")
                        .font(.caption)
                        .padding(.horizontal, DesignSystem.Spacing.small)
                        .padding(.vertical, DesignSystem.Spacing.extraSmall)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                }
            }
            
            if words.isEmpty {
                // 空の状態
                VStack(spacing: 8) {
                    Image(systemName: "text.book.closed")
                        .font(.largeTitle)
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("まだ ことばが ありません")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // 単語一覧（最新3つのみ表示）
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(words.suffix(5).enumerated()), id: \.offset) { index, word in
                            WordChip(
                                word: word,
                                isLatest: index == words.suffix(5).count - 1
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.05))
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

/// 単語チップコンポーネント
private struct WordChip: View {
    let word: String
    let isLatest: Bool
    
    var body: some View {
        Text(word)
            .font(.system(size: 16, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isLatest ? Color.blue : Color.gray.opacity(0.2))
                    .stroke(isLatest ? Color.blue : Color.clear, lineWidth: 2)
            )
            .foregroundColor(isLatest ? .white : .primary)
            .scaleEffect(isLatest ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isLatest)
    }
}