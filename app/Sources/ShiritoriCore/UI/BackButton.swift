import SwiftUI

/// アプリ全体で統一された戻るボタンコンポーネント
/// 子供向けの分かりやすいデザインと適切なマージンを提供
public struct BackButton: View {
    private let onBack: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    public init(onBack: @escaping () -> Void) {
        AppLogger.shared.debug("BackButton初期化")
        self.onBack = onBack
    }
    
    public var body: some View {
        HStack {
            Button(action: {
                AppLogger.shared.info("BackButtonタップ")
                onBack()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("もどる")
                        .font(DesignSystem.Typography.subtitle)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, DesignSystem.Spacing.large)
                .padding(.vertical, DesignSystem.Spacing.standard)
                .background(adaptiveBackgroundColor)
                .foregroundStyle(adaptiveForegroundColor)
                .cornerRadius(DesignSystem.CornerRadius.extraLarge)
                .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.large)
        .padding(.top, DesignSystem.Spacing.small)
    }
    
    private var adaptiveBackgroundColor: Color {
        if colorScheme == .dark {
            return Color(red: 0.2, green: 0.2, blue: 0.25).opacity(0.9)
        } else {
            return Color(red: 0.95, green: 0.95, blue: 0.95)
        }
    }
    
    private var adaptiveForegroundColor: Color {
        return colorScheme == .dark ? .white : .primary
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? .white.opacity(0.1) : .black.opacity(0.15)
    }
}

#Preview {
    VStack {
        BackButton(onBack: {
            print("戻るボタンがタップされました")
        })
        
        Spacer()
    }
    .background(Color.purple.opacity(0.3))
}