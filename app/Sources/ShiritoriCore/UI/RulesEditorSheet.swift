import SwiftUI

/// ルール編集シートコンポーネント
public struct RulesEditorSheet: View {
    @State private var timeLimit: Int
    @State private var winCondition: WinCondition
    
    private let onSave: (GameRulesConfig) -> Void
    private let onCancel: () -> Void
    
    public init(
        rules: GameRulesConfig,
        onSave: @escaping (GameRulesConfig) -> Void,
        onCancel: @escaping () -> Void
    ) {
        AppLogger.shared.debug("RulesEditorSheet初期化")
        self._timeLimit = State(initialValue: rules.timeLimit)
        self._winCondition = State(initialValue: rules.winCondition)
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                ChildFriendlyBackground(animationSpeed: 0.2)
                
                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("⚙️ ルール せってい")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("ゲームの ルールを きめよう")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 24) {
                        // 制限時間設定
                        TimeLimitSelector(
                            timeLimit: $timeLimit
                        )
                        
                        // 勝利条件設定
                        WinConditionSelector(
                            winCondition: $winCondition
                        )
                    }
                    
                    Spacer()
                    
                    // ボタン
                    HStack(spacing: 16) {
                        ChildFriendlyButton(
                            title: "キャンセル",
                            backgroundColor: .gray,
                            foregroundColor: .white
                        ) {
                            AppLogger.shared.info("ルール編集をキャンセル")
                            onCancel()
                        }
                        
                        ChildFriendlyButton(
                            title: "💾 ほぞん",
                            backgroundColor: .green,
                            foregroundColor: .white
                        ) {
                            saveRules()
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
    }
    
    private func saveRules() {
        let newRules = GameRulesConfig(
            timeLimit: timeLimit,
            maxPlayers: 5, // 固定値
            winCondition: winCondition
        )
        AppLogger.shared.info("ルール保存: 制限時間=\(timeLimit)秒, 勝利条件=\(winCondition.rawValue)")
        onSave(newRules)
    }
}

/// 制限時間選択コンポーネント
private struct TimeLimitSelector: View {
    @Binding var timeLimit: Int
    
    private let timeLimitOptions = [0, 30, 60, 90, 120]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⏱️ せいげん じかん")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(timeLimitOptions, id: \.self) { option in
                    TimeLimitOption(
                        seconds: option,
                        isSelected: timeLimit == option,
                        onTap: {
                            timeLimit = option
                        }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

/// 制限時間オプション
private struct TimeLimitOption: View {
    let seconds: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(displayText)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var displayText: String {
        if seconds == 0 {
            return "せいげん\nなし"
        } else if seconds < 60 {
            return "\(seconds)\nびょう"
        } else {
            let minutes = seconds / 60
            return "\(minutes)\nふん"
        }
    }
}

/// 勝利条件選択コンポーネント
private struct WinConditionSelector: View {
    @Binding var winCondition: WinCondition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🏆 しょうり じょうけん")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(WinCondition.allCases, id: \.self) { condition in
                    WinConditionOption(
                        condition: condition,
                        isSelected: winCondition == condition,
                        onTap: {
                            winCondition = condition
                        }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

/// 勝利条件オプション
private struct WinConditionOption: View {
    let condition: WinCondition
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(condition.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(condition.rawValue)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(condition.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.green : Color.gray.opacity(0.1))
                    .stroke(isSelected ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}