import SwiftUI

/// ポーズメニューコンポーネント
public struct PauseMenuView: View {
    private let onResume: () -> Void
    private let onQuit: () -> Void
    
    // UIState統合による状態管理
    @State private var uiState = UIState.shared
    
    private var showQuitConfirmation: Bool {
        uiState.getTransitionPhase("pauseMenu_quitConfirmation") == "shown"
    }
    
    private var showQuitConfirmationBinding: Binding<Bool> {
        Binding(
            get: { showQuitConfirmation },
            set: { newValue in
                if newValue {
                    uiState.setTransitionPhase("shown", for: "pauseMenu_quitConfirmation")
                } else {
                    uiState.setTransitionPhase("hidden", for: "pauseMenu_quitConfirmation")
                }
            }
        )
    }
    
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
                        showQuitDialog()
                    }
                }
                .frame(maxWidth: 200)
            }
            .padding(DesignSystem.Spacing.extraLarge)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            .frame(maxWidth: 350)
        }
        .alert("ゲームを やめますか？", isPresented: showQuitConfirmationBinding) {
            Button("キャンセル", role: .cancel) {
                AppLogger.shared.debug("ゲーム終了をキャンセル")
            }
            
            Button("やめる", role: .destructive) {
                AppLogger.shared.info("ゲーム終了を確定")
                onQuit()
            }
        } message: {
            Text("ゲームをやめると、これまでの きろくが きえてしまいます。ほんとうに やめますか？")
        }
    }
    
    private func showQuitDialog() {
        AppLogger.shared.debug("ゲーム終了確認ダイアログを表示")
        uiState.setTransitionPhase("shown", for: "pauseMenu_quitConfirmation")
    }
}