import SwiftUI

/// 新しいプレイヤーを追加するシートコンポーネント
public struct AddPlayerSheet: View {
    @Binding public var isPresented: Bool
    private let onSave: (String) -> Void
    private let onCancel: () -> Void
    
    @State private var playerName: String = ""
    
    // UIState統合による状態管理
    @State private var uiState = UIState.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private var showNameEmptyAlert: Bool {
        uiState.getTransitionPhase("addPlayer_emptyNameAlert") == "shown"
    }
    
    private var showNameEmptyAlertBinding: Binding<Bool> {
        Binding(
            get: { showNameEmptyAlert },
            set: { newValue in
                if newValue {
                    uiState.setTransitionPhase("shown", for: "addPlayer_emptyNameAlert")
                } else {
                    uiState.setTransitionPhase("hidden", for: "addPlayer_emptyNameAlert")
                }
            }
        )
    }
    
    public init(
        isPresented: Binding<Bool>,
        onSave: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        AppLogger.shared.debug("AddPlayerSheet初期化")
        self._isPresented = isPresented
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    // 適応的な背景色プロパティ
    private var textFieldBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color.white
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
    
    public var body: some View {
        ZStack {
                ChildFriendlyBackground(animationSpeed: 0.3)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // ヘッダー部分
                        VStack(spacing: 16) {
                            Text("✨ あたらしい プレイヤー")
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text("なまえを いれてね")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        
                        // 入力フィールド部分
                        VStack(alignment: .leading, spacing: 12) {
                            Text("なまえ")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("たろうくん", text: $playerName)
                                .font(.title2)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(textFieldBackgroundColor)
                                        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
                                )
                                .textFieldStyle(PlainTextFieldStyle())
                                .zIndex(1) // 入力フィールドを前面に配置
                        }
                        
                        // プレビューアバター部分（十分なスペーシングで分離）
                        if !playerName.isEmpty {
                            VStack(spacing: 16) {
                                Divider()
                                    .padding(.horizontal, 20)
                                
                                Text("プレビュー")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                
                                PlayerAvatarView(
                                    playerName: playerName,
                                    imageData: nil,
                                    size: 80
                                )
                                .transition(.scale.combined(with: .opacity))
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: !playerName.isEmpty)
                                
                                Spacer(minLength: 30) // プレビューの下に十分なスペースを確保
                            }
                            .padding(.top, 20) // 入力フィールドから十分に離す
                        } else {
                            // プレビューがない場合は空のスペースを確保
                            Spacer(minLength: 60)
                        }
                        
                        // ボタン部分
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                ChildFriendlyButton(
                                    title: "キャンセル",
                                    backgroundColor: .gray,
                                    foregroundColor: .white
                                ) {
                                    AppLogger.shared.info("プレイヤー追加をキャンセル")
                                    onCancel()
                                }
                                
                                ChildFriendlyButton(
                                    title: "🎉 とうろく",
                                    backgroundColor: .green,
                                    foregroundColor: .white
                                ) {
                                    savePlayer()
                                }
                            }
                            .padding(.horizontal)
                            
                            // 最下部に余白を確保
                            Spacer(minLength: 20)
                        }
                    }
                    .padding()
                }
            }
        .alert("なまえを いれてね", isPresented: showNameEmptyAlertBinding) {
            Button("OK") { }
        } message: {
            Text("プレイヤーの なまえを にゅうりょく してください")
        }
    }
    
    private func savePlayer() {
        let trimmedName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            AppLogger.shared.warning("空のプレイヤー名での登録を試行")
            uiState.setTransitionPhase("shown", for: "addPlayer_emptyNameAlert")
            return
        }
        
        AppLogger.shared.info("新しいプレイヤーを保存: \(trimmedName)")
        onSave(trimmedName)
    }
}