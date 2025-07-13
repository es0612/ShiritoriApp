import SwiftUI

/// プレイヤー選択カードコンポーネント
public struct PlayerSelectionCard: View {
    public let playerName: String
    public let isSelected: Bool
    private let onSelectionChanged: (Bool) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    public init(
        playerName: String,
        isSelected: Bool,
        onSelectionChanged: @escaping (Bool) -> Void
    ) {
        AppLogger.shared.debug("PlayerSelectionCard初期化: \(playerName), 選択=\(isSelected)")
        self.playerName = playerName
        self.isSelected = isSelected
        self.onSelectionChanged = onSelectionChanged
    }
    
    public var body: some View {
        Button(action: {
            AppLogger.shared.info("プレイヤー選択変更: \(playerName) -> \(!isSelected)")
            onSelectionChanged(!isSelected)
        }) {
            VStack(spacing: 12) {
                PlayerAvatarView(
                    playerName: playerName,
                    imageData: nil,
                    size: 60
                )
                
                Text(playerName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.green : adaptiveBackgroundColor)
                    .stroke(isSelected ? Color.green : adaptiveStrokeColor, lineWidth: 2)
                    .shadow(color: adaptiveShadowColor, radius: 4, x: 0, y: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var adaptiveBackgroundColor: Color {
        if colorScheme == .dark {
            return Color.gray.opacity(0.2)
        } else {
            return Color.white
        }
    }
    
    private var adaptiveStrokeColor: Color {
        if colorScheme == .dark {
            return Color.gray.opacity(0.5)
        } else {
            return Color.gray.opacity(0.3)
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