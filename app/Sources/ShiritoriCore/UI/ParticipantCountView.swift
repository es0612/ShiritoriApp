import SwiftUI

/// 参加者数表示コンポーネント
public struct ParticipantCountView: View {
    let selectedPlayersCount: Int
    let selectedComputersCount: Int
    
    @Environment(\.colorScheme) private var colorScheme
    
    public init(selectedPlayersCount: Int, selectedComputersCount: Int) {
        self.selectedPlayersCount = selectedPlayersCount
        self.selectedComputersCount = selectedComputersCount
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            Text("🎮 さんか メンバー")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 24) {
                ParticipantTypeCount(
                    icon: "👥",
                    label: "プレイヤー",
                    count: selectedPlayersCount,
                    color: .blue
                )
                
                Text("＋")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                ParticipantTypeCount(
                    icon: "🤖",
                    label: "コンピュータ",
                    count: selectedComputersCount,
                    color: .orange
                )
                
                Text("＝")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                ParticipantTypeCount(
                    icon: "🎯",
                    label: "ごうけい",
                    count: totalCount,
                    color: totalCount >= 2 ? .green : .red
                )
            }
            
            // 参加者数のバリデーション表示
            ValidationMessageView(totalCount: totalCount)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(adaptiveBackgroundColor)
                .stroke(validationColor.opacity(0.3), lineWidth: 2)
                .shadow(color: adaptiveShadowColor, radius: 4, x: 0, y: 2)
        )
    }
    
    private var totalCount: Int {
        selectedPlayersCount + selectedComputersCount
    }
    
    private var validationColor: Color {
        if totalCount < 2 {
            return .red
        } else if totalCount <= 5 {
            return .green
        } else {
            return .red
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

/// 参加者タイプ別カウント表示
private struct ParticipantTypeCount: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title2)
            
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

/// バリデーションメッセージ表示
private struct ValidationMessageView: View {
    let totalCount: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: validationIcon)
                .foregroundColor(validationColor)
            
            Text(validationMessage)
                .font(.caption)
                .foregroundColor(validationColor)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(validationColor.opacity(0.1))
        )
    }
    
    private var validationIcon: String {
        if totalCount < 2 {
            return "exclamationmark.triangle.fill"
        } else if totalCount <= 5 {
            return "checkmark.circle.fill"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var validationColor: Color {
        if totalCount < 2 {
            return .red
        } else if totalCount <= 5 {
            return .green
        } else {
            return .red
        }
    }
    
    private var validationMessage: String {
        if totalCount < 2 {
            return "2にん いじょう えらんでね"
        } else if totalCount <= 5 {
            return "ゲーム かいし できます！"
        } else {
            return "さいだい 5にん までです"
        }
    }
}