import SwiftUI

/// 新しいプレイヤーを追加するシートコンポーネント
public struct AddPlayerSheet: View {
    @Binding public var isPresented: Bool
    private let onSave: (String) -> Void
    private let onCancel: () -> Void
    
    @State private var playerName: String = ""
    @State private var showNameEmptyAlert = false
    @Environment(\.colorScheme) private var colorScheme
    
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
        NavigationView {
            ZStack {
                ChildFriendlyBackground(animationSpeed: 0.3)
                
                VStack(spacing: 30) {
                    VStack(spacing: 16) {
                        Text("✨ あたらしい プレイヤー")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("なまえを いれてね")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 20) {
                        // 名前入力フィールド
                        VStack(alignment: .leading, spacing: 8) {
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
                        }
                        
                        // プレビューアバター
                        if !playerName.isEmpty {
                            VStack(spacing: 12) {
                                Text("プレビュー")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                PlayerAvatarView(
                                    playerName: playerName,
                                    imageData: nil,
                                    size: 80
                                )
                            }
                            .padding(.top, 8)
                        }
                    }
                    
                    Spacer()
                    
                    // ボタン
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
                }
                .padding()
            }
            .navigationTitle("")
#if os(iOS)
            .navigationBarHidden(true)
#endif
        }
        .alert("なまえを いれてね", isPresented: $showNameEmptyAlert) {
            Button("OK") { }
        } message: {
            Text("プレイヤーの なまえを にゅうりょく してください")
        }
    }
    
    private func savePlayer() {
        let trimmedName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            AppLogger.shared.warning("空のプレイヤー名での登録を試行")
            showNameEmptyAlert = true
            return
        }
        
        AppLogger.shared.info("新しいプレイヤーを保存: \(trimmedName)")
        onSave(trimmedName)
    }
}