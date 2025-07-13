import SwiftUI

/// ポーズメニューコンポーネント
public struct PauseMenuView: View {
    private let onResume: () -> Void
    private let onQuit: () -> Void
    
    public init(
        onResume: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        AppLogger.shared.debug("PauseMenuView初期化")
        self.onResume = onResume
        self.onQuit = onQuit
    }
    
    public var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // ヘッダー
                VStack(spacing: 16) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                    
                    Text("いちじ ていし")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("どうしますか？")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                
                // メニューボタン
                VStack(spacing: 20) {
                    ChildFriendlyButton(
                        title: "▶️ つづける",
                        backgroundColor: .green,
                        foregroundColor: .white
                    ) {
                        AppLogger.shared.info("ゲーム再開選択")
                        onResume()
                    }
                    
                    ChildFriendlyButton(
                        title: "🏠 やめる",
                        backgroundColor: .red,
                        foregroundColor: .white
                    ) {
                        AppLogger.shared.info("ゲーム終了選択")
                        showQuitConfirmation()
                    }
                }
                .frame(maxWidth: 200)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            .frame(maxWidth: 350)
        }
    }
    
    private func showQuitConfirmation() {
        // TODO: 確認ダイアログの実装
        onQuit()
    }
}