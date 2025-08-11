import SwiftUI

/// プレイヤーが一人もいない場合の表示コンポーネント
public struct EmptyPlayerListView: View {
    private let onAddPlayer: () -> Void
    
    // UIState統合によるアニメーション管理
    @State private var uiState = UIState.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private var animationOffset: CGFloat {
        CGFloat(uiState.animationValues["emptyPlayerList_offset"] ?? 0.0)
    }
    
    private var animationScale: CGFloat {
        CGFloat(uiState.animationValues["emptyPlayerList_scale"] ?? 1.0)
    }
    
    public init(onAddPlayer: @escaping () -> Void) {
        AppLogger.shared.debug("EmptyPlayerListView初期化")
        self.onAddPlayer = onAddPlayer
    }
    
    // 適応的な色プロパティ
    private var iconBackgroundColor: Color {
        colorScheme == .dark ? Color.blue.opacity(0.3) : Color.blue.opacity(0.1)
    }
    
    private var iconColor: Color {
        colorScheme == .dark ? Color.blue.opacity(0.9) : Color.blue
    }
    
    public var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 24) {
                // アイコン
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "person.2.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(iconColor)
                        .scaleEffect(animationScale)
                        .offset(y: animationOffset)
                }
                
                VStack(spacing: 12) {
                    Text("まだ プレイヤーが いません")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("あたらしい プレイヤーを\nついか してみましょう！")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            
            ChildFriendlyButton(
                title: "➕ はじめての プレイヤー",
                backgroundColor: .green,
                foregroundColor: .white
            ) {
                AppLogger.shared.info("初回プレイヤー追加ボタンタップ")
                onAddPlayer()
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // UIState統合によるアニメーション開始
        uiState.setAnimationValue(0.0, for: "emptyPlayerList_offset")
        uiState.setAnimationValue(1.0, for: "emptyPlayerList_scale")
        
        uiState.startAnimation("emptyPlayerList_offset")
        uiState.startAnimation("emptyPlayerList_scale")
        
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            uiState.setAnimationValue(-10.0, for: "emptyPlayerList_offset")
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            uiState.setAnimationValue(1.1, for: "emptyPlayerList_scale")
        }
    }
}