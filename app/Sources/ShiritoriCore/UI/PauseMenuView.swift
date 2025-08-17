import SwiftUI

/// ポーズメニューコンポーネント
public struct PauseMenuView: View {
    private let onResume: () -> Void
    private let onQuit: () -> Void
    private let onQuitToTitle: (() -> Void)?
    private let onQuitToSettings: (() -> Void)?
    
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
        onQuit: @escaping () -> Void,
        onQuitToTitle: (() -> Void)? = nil,
        onQuitToSettings: (() -> Void)? = nil
    ) {
        AppLogger.shared.debug("PauseMenuView初期化")
        self.onResume = onResume
        self.onQuit = onQuit
        self.onQuitToTitle = onQuitToTitle
        self.onQuitToSettings = onQuitToSettings
    }
    
    public var body: some View {
        ZStack(alignment: .center) {
            // 背景
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // 簡素化: 継続/終了の2択のみ表示
            mainMenuView
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
    
    private var mainMenuView: some View {
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
                
                // 簡素化: シンプルな終了ボタンのみ
                ChildFriendlyButton(
                    title: "🏠 やめる",
                    backgroundColor: .red,
                    foregroundColor: .white
                ) {
                    AppLogger.shared.info("ゲーム終了選択（簡素化版）")
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
        .frame(maxHeight: .infinity)
        .clipped()
    }
    
    // 簡素化により以下を削除:
    // - destinationOptionsView: 複雑な詳細選択画面
    // - hasAdvancedOptions: 条件分岐ロジック  
    // - showDestinationOptions: 状態管理
    
    private func showQuitDialog() {
        AppLogger.shared.debug("ゲーム終了確認ダイアログを表示")
        uiState.setTransitionPhase("shown", for: "pauseMenu_quitConfirmation")
    }
}