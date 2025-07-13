import SwiftUI

/// 子供が直感的に操作しやすい大きなボタンコンポーネント
public struct ChildFriendlyButton: View {
    public let title: String
    public let backgroundColor: Color
    public let foregroundColor: Color
    private let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    public init(
        title: String,
        backgroundColor: Color = .blue,
        foregroundColor: Color = .white,
        action: @escaping () -> Void
    ) {
        AppLogger.shared.debug("ChildFriendlyButton初期化: タイトル=\(title)")
        self.title = title
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            AppLogger.shared.info("ChildFriendlyButtonタップ: \(title)")
            action()
        }) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(adaptiveBackgroundColor)
                .foregroundStyle(adaptiveForegroundColor)
                .cornerRadius(25)
                .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
        }
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: backgroundColor)
    }
    
    private var adaptiveBackgroundColor: Color {
        if colorScheme == .dark {
            // ダークモードでは背景色を少し明るく調整
            return backgroundColor.opacity(0.8)
        } else {
            return backgroundColor
        }
    }
    
    private var adaptiveForegroundColor: Color {
        // システムの動的色を使用してダークモードに対応
        if foregroundColor == .white {
            return colorScheme == .dark ? .white : .white
        } else if foregroundColor == .black {
            return colorScheme == .dark ? .white : .black
        } else {
            return foregroundColor
        }
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? .white.opacity(0.1) : .black.opacity(0.2)
    }
}