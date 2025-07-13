import SwiftUI

/// ゲーム統計表示コンポーネント
public struct GameStatsDisplay: View {
    public let totalWords: Int
    public let gameDuration: Int
    public let averageWordTime: Double
    
    public init(totalWords: Int, gameDuration: Int, averageWordTime: Double) {
        AppLogger.shared.debug("GameStatsDisplay初期化: 単語\(totalWords)個, 時間\(gameDuration)秒")
        self.totalWords = totalWords
        self.gameDuration = gameDuration
        self.averageWordTime = averageWordTime
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                statCard(
                    icon: "💬",
                    title: "つかった\nことば",
                    value: "\(totalWords)こ"
                )
                
                statCard(
                    icon: "⏱️",
                    title: "ゲーム\nじかん",
                    value: formatDuration(gameDuration)
                )
                
                statCard(
                    icon: "⚡",
                    title: "へいきん\nじかん",
                    value: String(format: "%.1f秒", averageWordTime)
                )
            }
            
            if totalWords == 0 {
                Text("まだ単語が出ていません")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func statCard(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.largeTitle)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
        )
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if minutes > 0 {
            return "\(minutes)分\(remainingSeconds)秒"
        } else {
            return "\(remainingSeconds)秒"
        }
    }
}