import SwiftUI

/// 子供向けの楽しい背景コンポーネント
public struct ChildFriendlyBackground: View {
    public let animationSpeed: Double
    
    @State private var animationOffset1: CGFloat = 0
    @State private var animationOffset2: CGFloat = 0
    @State private var rotationAngle: Double = 0
    @Environment(\.colorScheme) private var colorScheme
    
    public init(animationSpeed: Double = 1.0) {
        AppLogger.shared.debug("ChildFriendlyBackground初期化: アニメーション速度=\(animationSpeed)")
        self.animationSpeed = animationSpeed
    }
    
    public var body: some View {
        ZStack {
            // ベース背景
            LinearGradient(
                colors: backgroundGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 浮かぶ円形要素
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [getAdaptiveColorForIndex(index).opacity(0.6), getAdaptiveColorForIndex(index).opacity(0.2)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: CGFloat.random(in: 60...120))
                    .offset(
                        x: animationOffset1 + CGFloat(index * 50 - 200),
                        y: animationOffset2 + CGFloat(index * 80 - 300)
                    )
                    .rotationEffect(.degrees(rotationAngle + Double(index * 45)))
            }
            
            // 装飾要素
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: getSymbolForIndex(index))
                    .font(.system(size: CGFloat.random(in: 30...50)))
                    .foregroundStyle(getAdaptiveColorForIndex(index + 3).opacity(0.4))
                    .offset(
                        x: CGFloat.random(in: -150...150),
                        y: animationOffset1 * 0.5 + CGFloat(index * 100 - 200)
                    )
                    .rotationEffect(.degrees(rotationAngle * 0.7 + Double(index * 30)))
            }
        }
        .onAppear {
            startBackgroundAnimation()
        }
    }
    
    private func startBackgroundAnimation() {
        withAnimation(
            .linear(duration: 10.0 / animationSpeed)
            .repeatForever(autoreverses: false)
        ) {
            animationOffset1 = 100
        }
        
        withAnimation(
            .linear(duration: 15.0 / animationSpeed)
            .repeatForever(autoreverses: true)
        ) {
            animationOffset2 = 80
        }
        
        withAnimation(
            .linear(duration: 20.0 / animationSpeed)
            .repeatForever(autoreverses: false)
        ) {
            rotationAngle = 360
        }
    }
    
    private var backgroundGradientColors: [Color] {
        if colorScheme == .dark {
            return [.indigo.opacity(0.4), .purple.opacity(0.3)]
        } else {
            return [.cyan.opacity(0.3), .blue.opacity(0.2)]
        }
    }
    
    private func getColorForIndex(_ index: Int) -> Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .mint]
        return colors[index % colors.count]
    }
    
    private func getAdaptiveColorForIndex(_ index: Int) -> Color {
        let baseColor = getColorForIndex(index)
        if colorScheme == .dark {
            // ダークモードでは色を少し明るく、鮮やかにする
            return baseColor.opacity(0.8)
        } else {
            return baseColor
        }
    }
    
    private func getSymbolForIndex(_ index: Int) -> String {
        let symbols = ["star.fill", "heart.fill", "moon.fill", "sun.max.fill", "cloud.fill"]
        return symbols[index % symbols.count]
    }
}