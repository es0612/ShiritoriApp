import SwiftUI

/// 子供が直感的に操作しやすい大きなボタンコンポーネント
public struct ChildFriendlyButton: View {
    public let title: String
    public let backgroundColor: Color
    public let foregroundColor: Color
    private let action: () -> Void
    
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
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .cornerRadius(25)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: backgroundColor)
    }
}