import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// ゲーム画面のUI計算ヘルパークラス
/// 画面サイズ、デバイス対応、レイアウト計算などのUI関連処理を分離
public struct GameUIHelpers {
    
    // MARK: - Responsive Layout Calculations
    
    /// 画面サイズに応じた動的スペーサーの高さを計算
    /// @param geometry 画面のGeometryProxy
    /// @return 適切なスペーサーの高さ
    public static func adaptiveSpacerHeight(for geometry: GeometryProxy) -> CGFloat {
        let screenHeight = geometry.size.height
        
        // iPhone SE (568pt) などの小さな画面では最小限のスペース
        if screenHeight < 600 {
            return DesignSystem.Spacing.small
        }
        // iPhone (667pt-736pt) などの標準的な画面では適度なスペース
        else if screenHeight < 800 {
            return DesignSystem.Spacing.standard
        }
        // iPhone Pro Max (926pt) やiPad などの大きな画面ではゆとりのあるスペース
        else {
            return DesignSystem.Spacing.large
        }
    }
    
    /// 画面サイズに応じた単語履歴表示エリアの最大高さを計算
    /// @param geometry 画面のGeometryProxy
    /// @return 単語履歴表示エリアの最大高さ
    public static func adaptiveHistoryHeight(for geometry: GeometryProxy) -> CGFloat {
        let screenHeight = geometry.size.height
        
        // 小さな画面では画面の25%
        if screenHeight < 600 {
            return screenHeight * 0.25
        }
        // 標準的な画面では画面の30%
        else if screenHeight < 800 {
            return screenHeight * 0.30
        }
        // 大きな画面では画面の35%（ただし最大300pt）
        else {
            return min(screenHeight * 0.35, 300)
        }
    }
    
    /// 画面サイズに応じた入力エリア用スペーサーの高さを計算
    /// 固定位置の入力エリアとスクロール内容が重ならないようにする
    /// @param geometry 画面のGeometryProxy
    /// @return 入力エリア用スペーサーの高さ
    public static func calculateInputAreaHeight(for geometry: GeometryProxy) -> CGFloat {
        let screenHeight = geometry.size.height
        
        // 入力エリアの高さを推定（WordInputViewの高さ + パディング）
        // 音声入力時：約200pt、キーボード入力時：約160pt
        let estimatedInputAreaHeight: CGFloat = 220
        
        // 小さい画面では最小限の追加スペースを確保
        if screenHeight < 600 {
            return estimatedInputAreaHeight + DesignSystem.Spacing.small
        }
        // 標準的な画面では適度なスペースを確保
        else if screenHeight < 800 {
            return estimatedInputAreaHeight + DesignSystem.Spacing.standard
        }
        // 大きな画面では十分なスペースを確保
        else {
            return estimatedInputAreaHeight + DesignSystem.Spacing.large
        }
    }
    
    // MARK: - Platform-Specific Helpers
    
    /// プラットフォーム固有の背景色を取得
    /// @return システム背景色またはデフォルト色
    public static var backgroundColorForCurrentPlatform: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #else
        return Color.white
        #endif
    }
    
    /// プラットフォーム固有のセカンダリ背景色を取得
    /// @return システムセカンダリ背景色またはデフォルト色
    public static var secondaryBackgroundColorForCurrentPlatform: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemBackground)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }
    
    /// プラットフォーム固有のラベル色を取得
    /// @return システムラベル色またはデフォルト色
    public static var labelColorForCurrentPlatform: Color {
        #if canImport(UIKit)
        return Color(UIColor.label)
        #else
        return Color.black
        #endif
    }
    
    // MARK: - Device Type Detection
    
    /// 現在のデバイスがiPadかどうかを判定
    /// @return iPadの場合true
    public static var isPad: Bool {
        #if canImport(UIKit)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }
    
    /// 現在のデバイスがiPhoneかどうかを判定
    /// @return iPhoneの場合true
    public static var isPhone: Bool {
        #if canImport(UIKit)
        return UIDevice.current.userInterfaceIdiom == .phone
        #else
        return true
        #endif
    }
    
    /// 小さな画面（iPhone SEなど）かどうかを判定
    /// @param geometry 画面のGeometryProxy
    /// @return 小さな画面の場合true
    public static func isCompactScreen(_ geometry: GeometryProxy) -> Bool {
        return geometry.size.height < 600 || geometry.size.width < 375
    }
    
    // MARK: - Animation Helpers
    
    /// 画面サイズに応じたアニメーション継続時間を取得
    /// @param geometry 画面のGeometryProxy
    /// @return アニメーション継続時間
    public static func adaptiveAnimationDuration(for geometry: GeometryProxy) -> Double {
        // 小さな画面では高速なアニメーション
        if isCompactScreen(geometry) {
            return 0.3
        }
        // 大きな画面では少し長めのアニメーション
        else if isPad {
            return 0.6
        }
        // 標準的な画面では標準的なアニメーション
        else {
            return 0.4
        }
    }
    
    /// 画面サイズに応じたスプリングアニメーションを取得
    /// @param geometry 画面のGeometryProxy
    /// @return スプリングアニメーション
    public static func adaptiveSpringAnimation(for geometry: GeometryProxy) -> Animation {
        let duration = adaptiveAnimationDuration(for: geometry)
        return .spring(response: duration, dampingFraction: 0.8)
    }
    
    // MARK: - Accessibility Helpers
    
    /// アクセシビリティのための動きを減らす設定を確認
    /// @return 動きを減らす設定がオンの場合true
    public static var prefersReducedMotion: Bool {
        #if canImport(UIKit)
        return UIAccessibility.isReduceMotionEnabled
        #else
        return false
        #endif
    }
    
    /// アクセシビリティを考慮したアニメーション継続時間を取得
    /// @param geometry 画面のGeometryProxy
    /// @return アクセシビリティを考慮したアニメーション継続時間
    public static func accessibleAnimationDuration(for geometry: GeometryProxy) -> Double {
        if prefersReducedMotion {
            return 0.0 // 動きを減らす設定時はアニメーションなし
        }
        return adaptiveAnimationDuration(for: geometry)
    }
    
    // MARK: - Layout Constants
    
    /// 画面サイズ別の推奨パディング値
    public enum AdaptivePadding {
        /// 小さな画面での推奨パディング
        public static let compact: CGFloat = 12
        /// 標準画面での推奨パディング
        public static let regular: CGFloat = 16
        /// 大きな画面での推奨パディング
        public static let expanded: CGFloat = 24
        
        /// 画面サイズに応じたパディングを取得
        public static func forGeometry(_ geometry: GeometryProxy) -> CGFloat {
            if GameUIHelpers.isCompactScreen(geometry) {
                return compact
            } else if GameUIHelpers.isPad {
                return expanded
            } else {
                return regular
            }
        }
    }
    
    /// 画面サイズ別の推奨フォントサイズ倍率
    public enum AdaptiveFontScale {
        /// 小さな画面でのフォント倍率
        public static let compact: CGFloat = 0.9
        /// 標準画面でのフォント倍率
        public static let regular: CGFloat = 1.0
        /// 大きな画面でのフォント倍率
        public static let expanded: CGFloat = 1.1
        
        /// 画面サイズに応じたフォント倍率を取得
        public static func forGeometry(_ geometry: GeometryProxy) -> CGFloat {
            if GameUIHelpers.isCompactScreen(geometry) {
                return compact
            } else if GameUIHelpers.isPad {
                return expanded
            } else {
                return regular
            }
        }
    }
    
    // MARK: - Debug Helpers
    
    /// デバッグ用の画面情報を生成
    /// @param geometry 画面のGeometryProxy
    /// @return デバッグ情報文字列
    public static func debugScreenInfo(for geometry: GeometryProxy) -> String {
        return """
        Screen Info:
        - Size: \(geometry.size.width) x \(geometry.size.height)
        - Safe Area: \(geometry.safeAreaInsets)
        - Device: \(isPad ? "iPad" : "iPhone")
        - Compact: \(isCompactScreen(geometry))
        - Reduce Motion: \(prefersReducedMotion)
        """
    }
}