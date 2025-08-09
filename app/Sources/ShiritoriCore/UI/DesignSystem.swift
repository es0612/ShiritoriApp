import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// アプリ全体のデザインシステム定義
public enum DesignSystem {
    
    // MARK: - Spacing (余白)
    public enum Spacing {
        /// 極小余白: 4pt
        public static let extraSmall: CGFloat = 4
        /// 微小余白: 6pt
        public static let tiny: CGFloat = 6
        /// 小余白: 8pt
        public static let small: CGFloat = 8
        /// 中小余白: 12pt
        public static let mediumSmall: CGFloat = 12
        /// 標準余白: 16pt (基本単位)
        public static let standard: CGFloat = 16
        /// 中余白: 20pt
        public static let mediumLarge: CGFloat = 20
        /// 大余白: 24pt
        public static let medium: CGFloat = 24
        /// 特大余白: 32pt
        public static let large: CGFloat = 32
        /// 超大余白: 48pt
        public static let extraLarge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    public enum CornerRadius {
        /// 小さい角丸: 8pt
        public static let small: CGFloat = 8
        /// 標準角丸: 12pt
        public static let standard: CGFloat = 12
        /// 大きい角丸: 16pt
        public static let large: CGFloat = 16
        /// 特大角丸: 24pt
        public static let extraLarge: CGFloat = 24
    }
    
    // MARK: - Typography
    public enum Typography {
        /// 大タイトル
        public static let largeTitle = Font.largeTitle.weight(.bold)
        /// タイトル
        public static let title = Font.title.weight(.semibold)
        /// サブタイトル
        public static let subtitle = Font.title2.weight(.medium)
        /// 本文
        public static let body = Font.body
        /// キャプション
        public static let caption = Font.caption
        /// 小さなキャプション
        public static let smallCaption = Font.caption2
    }
    
    // MARK: - Colors
    public enum Colors {
        /// プライマリカラー
        public static let primary = Color.blue
        /// セカンダリカラー
        public static let secondary = Color.green
        /// アクセントカラー
        public static let accent = Color.orange
        /// 成功色
        public static let success = Color.green
        /// 警告色
        public static let warning = Color.orange
        /// エラー色
        public static let error = Color.red
        /// グレー系
        public static let lightGray = Color.gray.opacity(0.2)
        public static let mediumGray = Color.gray.opacity(0.5)
        public static let darkGray = Color.gray.opacity(0.8)
    }
    
    // MARK: - Button Styles
    public struct PrimaryButtonStyle: ButtonStyle {
        public init() {}
        
        public func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Typography.body.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.standard)
                .padding(.vertical, Spacing.small)
                .background(Colors.primary)
                .cornerRadius(CornerRadius.standard)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }
    
    public struct SecondaryButtonStyle: ButtonStyle {
        public init() {}
        
        public func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Typography.body.weight(.medium))
                .foregroundColor(Colors.primary)
                .padding(.horizontal, Spacing.standard)
                .padding(.vertical, Spacing.small)
                .background(Colors.lightGray)
                .cornerRadius(CornerRadius.standard)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }
    
    // MARK: - Card Style
    public struct CardStyle: ViewModifier {
        public init() {}
        
        public func body(content: Content) -> some View {
            content
                .padding(Spacing.standard)
                .background(systemBackgroundColor)
                .cornerRadius(CornerRadius.standard)
                .shadow(color: Colors.darkGray, radius: 4, x: 0, y: 2)
        }
        
        private var systemBackgroundColor: Color {
            #if canImport(UIKit)
            return Color(UIColor.systemBackground)
            #else
            return Color.white
            #endif
        }
    }
    
    // MARK: - Safe Area Padding
    public struct SafeAreaPadding: ViewModifier {
        public init() {}
        
        public func body(content: Content) -> some View {
            content
                .padding(.horizontal, Spacing.standard)
                .padding(.top, Spacing.small)
                .padding(.bottom, Spacing.standard)
        }
    }
}

// MARK: - View Extensions
public extension View {
    /// カードスタイルを適用
    func cardStyle() -> some View {
        self.modifier(DesignSystem.CardStyle())
    }
    
    /// セーフエリアパディングを適用
    func safeAreaPadding() -> some View {
        self.modifier(DesignSystem.SafeAreaPadding())
    }
    
    /// 標準パディングを適用
    func standardPadding() -> some View {
        self.padding(DesignSystem.Spacing.standard)
    }
    
    /// 小パディングを適用
    func smallPadding() -> some View {
        self.padding(DesignSystem.Spacing.small)
    }
    
    /// 大パディングを適用
    func largePadding() -> some View {
        self.padding(DesignSystem.Spacing.large)
    }
}