import SwiftUI

/// 前の単語を表示するカードコンポーネント
public struct WordDisplayCard: View {
    public let word: String?
    public let isHighlighted: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    public init(
        word: String?,
        isHighlighted: Bool = false
    ) {
        AppLogger.shared.debug("WordDisplayCard初期化: 単語=\(word ?? "なし"), ハイライト=\(isHighlighted)")
        self.word = word
        self.isHighlighted = isHighlighted
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            Text("まえのことば")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            if let word = word {
                Text(word)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(isHighlighted ? .white : .primary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isHighlighted ? Color.orange : adaptiveNormalBackgroundColor)
                            .shadow(color: adaptiveShadowColor, radius: 4, x: 0, y: 2)
                    )
                    .scaleEffect(isHighlighted ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)
            } else {
                Text("まだありません")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(adaptiveNormalBackgroundColor)
                    )
            }
        }
        .padding()
    }
    
    private var adaptiveNormalBackgroundColor: Color {
        if colorScheme == .dark {
            return Color.gray.opacity(0.3)
        } else {
            return Color.gray.opacity(0.1)
        }
    }
    
    private var adaptiveShadowColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.1)
        } else {
            return Color.black.opacity(0.1)
        }
    }
}