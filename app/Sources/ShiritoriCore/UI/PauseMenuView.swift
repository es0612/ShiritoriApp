import SwiftUI

/// ポーズメニューコンポーネント
public struct PauseMenuView: View {
    private let onResume: () -> Void
    private let onQuit: () -> Void
    private let onQuitToTitle: (() -> Void)?
    private let onQuitToSettings: (() -> Void)?
    
    // UIState統合による状態管理
    @State private var uiState = UIState.shared
    @State private var showDestinationOptions = false
    
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
        ZStack {
            // 背景
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            if showDestinationOptions {
                destinationOptionsView
            } else {
                mainMenuView
            }
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
                
                if hasAdvancedOptions {
                    ChildFriendlyButton(
                        title: "🚪 やめかたを えらぶ",
                        backgroundColor: .orange,
                        foregroundColor: .white
                    ) {
                        AppLogger.shared.info("詳細な終了選択肢を表示")
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showDestinationOptions = true
                        }
                    }
                } else {
                    ChildFriendlyButton(
                        title: "🏠 やめる",
                        backgroundColor: .red,
                        foregroundColor: .white
                    ) {
                        AppLogger.shared.info("ゲーム終了選択")
                        showQuitDialog()
                    }
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
    
    private var destinationOptionsView: some View {
        VStack(spacing: 30) {
            // ヘッダー
            VStack(spacing: 16) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("どこに いきますか？")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("すきな ばしょを えらんでね")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            
            // 戻り先選択ボタン
            VStack(spacing: 16) {
                if let onQuitToTitle = onQuitToTitle {
                    ChildFriendlyButton(
                        title: "🏠 タイトルに もどる",
                        backgroundColor: .blue,
                        foregroundColor: .white
                    ) {
                        AppLogger.shared.info("タイトルに戻る選択")
                        onQuitToTitle()
                    }
                }
                
                if let onQuitToSettings = onQuitToSettings {
                    ChildFriendlyButton(
                        title: "⚙️ せっていを みる",
                        backgroundColor: .purple,
                        foregroundColor: .white
                    ) {
                        AppLogger.shared.info("設定画面に移動選択")
                        onQuitToSettings()
                    }
                }
                
                ChildFriendlyButton(
                    title: "📊 きろくを のこして やめる",
                    backgroundColor: .green,
                    foregroundColor: .white
                ) {
                    AppLogger.shared.info("記録保存して終了選択")
                    showQuitDialog()
                }
                
                // 戻るボタン
                ChildFriendlyButton(
                    title: "↩️ もどる",
                    backgroundColor: .gray,
                    foregroundColor: .white
                ) {
                    AppLogger.shared.debug("メインメニューに戻る")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showDestinationOptions = false
                    }
                }
            }
            .frame(maxWidth: 220)
        }
        .padding(DesignSystem.Spacing.extraLarge)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .frame(maxWidth: 380)
        .transition(.scale.combined(with: .opacity))
    }
    
    private var hasAdvancedOptions: Bool {
        onQuitToTitle != nil || onQuitToSettings != nil
    }
    
    private func showQuitDialog() {
        AppLogger.shared.debug("ゲーム終了確認ダイアログを表示")
        uiState.setTransitionPhase("shown", for: "pauseMenu_quitConfirmation")
    }
}