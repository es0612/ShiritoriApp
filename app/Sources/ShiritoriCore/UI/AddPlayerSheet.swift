import SwiftUI

/// 新しいプレイヤーを追加するシートコンポーネント
public struct AddPlayerSheet: View {
    @Binding public var isPresented: Bool
    private let onSave: (String) -> Void
    private let onCancel: () -> Void
    
    @State private var playerName: String = ""
    @State private var showNameEmptyAlert = false
    
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
    
    public var body: some View {
        NavigationView {
            ZStack {
                ChildFriendlyBackground(animationSpeed: 0.3)
                
                VStack(spacing: 40) {
                    VStack(spacing: 20) {
                        Text("✨ あたらしい プレイヤー")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("なまえを いれてね")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 24) {
                        // 名前入力フィールド
                        VStack(alignment: .leading, spacing: 8) {
                            Text("なまえ")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("たろうくん", text: $playerName)
                                .font(.title2)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        
                        // プレビューアバター
                        if !playerName.isEmpty {
                            VStack(spacing: 8) {
                                Text("プレビュー")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                PlayerAvatarView(
                                    playerName: playerName,
                                    imageData: nil,
                                    size: 100
                                )
                            }
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