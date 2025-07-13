import SwiftUI

/// ゲームルール表示カードコンポーネント
public struct RulesDisplayCard: View {
    public let timeLimit: Int
    public let winCondition: WinCondition
    private let onEdit: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    public init(
        timeLimit: Int,
        winCondition: WinCondition,
        onEdit: @escaping () -> Void
    ) {
        AppLogger.shared.debug("RulesDisplayCard初期化: 制限時間=\(timeLimit)秒, 勝利条件=\(winCondition.rawValue)")
        self.timeLimit = timeLimit
        self.winCondition = winCondition
        self.onEdit = onEdit
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("🎯 ゲームルール")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    AppLogger.shared.info("ルール編集ボタンタップ")
                    onEdit()
                }) {
                    Image(systemName: "pencil")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(16)
                }
            }
            
            VStack(spacing: 12) {
                RuleItem(
                    icon: "⏱️",
                    title: "せいげん じかん",
                    value: formatTimeLimit(timeLimit)
                )
                
                RuleItem(
                    icon: winCondition.emoji,
                    title: "しょうり じょうけん",
                    value: winCondition.description
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(adaptiveBackgroundColor)
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                .shadow(color: adaptiveShadowColor, radius: 4, x: 0, y: 2)
        )
    }
    
    private func formatTimeLimit(_ seconds: Int) -> String {
        if seconds == 0 {
            return "せいげん なし"
        } else if seconds < 60 {
            return "\(seconds)びょう"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if remainingSeconds == 0 {
                return "\(minutes)ふん"
            } else {
                return "\(minutes)ふん\(remainingSeconds)びょう"
            }
        }
    }
    
    private var adaptiveBackgroundColor: Color {
        if colorScheme == .dark {
            return Color.gray.opacity(0.2)
        } else {
            return Color.white
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

/// ルール項目表示コンポーネント
private struct RuleItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}