import SwiftUI

/// コンピュータプレイヤー選択カードコンポーネント
public struct ComputerPlayerCard: View {
    public let difficultyLevel: DifficultyLevel
    public let isSelected: Bool
    private let onSelectionChanged: (Bool) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    public init(
        difficultyLevel: DifficultyLevel,
        isSelected: Bool,
        onSelectionChanged: @escaping (Bool) -> Void
    ) {
        AppLogger.shared.debug("ComputerPlayerCard初期化: \(difficultyLevel), 選択=\(isSelected)")
        self.difficultyLevel = difficultyLevel
        self.isSelected = isSelected
        self.onSelectionChanged = onSelectionChanged
    }
    
    public var body: some View {
        Button(action: {
            AppLogger.shared.info("コンピュータ選択変更: \(difficultyLevel) -> \(!isSelected)")
            onSelectionChanged(!isSelected)
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(difficultyColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "desktopcomputer")
                        .font(.title2)
                        .foregroundColor(difficultyColor)
                }
                
                VStack(spacing: 2) {
                    Text(difficultyLevel.displayName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .white : difficultyColor)
                    
                    Text(difficultyLevel.description)
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? difficultyColor : adaptiveBackgroundColor)
                    .stroke(isSelected ? difficultyColor : difficultyColor.opacity(0.3), lineWidth: 2)
                    .shadow(color: adaptiveShadowColor, radius: 4, x: 0, y: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var difficultyColor: Color {
        switch difficultyLevel {
        case .easy:
            return .green
        case .normal:
            return .orange
        case .hard:
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