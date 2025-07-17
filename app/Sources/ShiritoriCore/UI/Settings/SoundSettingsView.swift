import SwiftUI

/// 効果音設定ビュー
public struct SoundSettingsView: View {
    @StateObject private var soundManager = SoundManager.shared
    
    public init() {
        AppLogger.shared.debug("SoundSettingsView初期化")
    }
    
    public var body: some View {
        VStack(spacing: DesignSystem.Spacing.standard) {
            // 効果音有効/無効切り替え
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("こうかおんを ならす")
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("せいかい・まちがいなどの おとを だします")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { soundManager.isEnabled },
                    set: { soundManager.setEnabled($0) }
                ))
                .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primary))
            }
            
            if soundManager.isEnabled {
                Divider()
                    .padding(.vertical, DesignSystem.Spacing.small)
                
                // 音量調整
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    HStack {
                        Text("おんりょう")
                            .font(DesignSystem.Typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(Int(soundManager.volume * 100))%")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "speaker.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        Slider(
                            value: Binding(
                                get: { soundManager.volume },
                                set: { soundManager.setVolume($0) }
                            ),
                            in: 0.0...1.0,
                            step: 0.1
                        )
                        .tint(DesignSystem.Colors.primary)
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                Divider()
                    .padding(.vertical, DesignSystem.Spacing.small)
                
                // 効果音テスト
                VStack(spacing: DesignSystem.Spacing.small) {
                    Text("おとの てすと")
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("ボタンを おして おとを かくにんできます")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // テストボタン群
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignSystem.Spacing.small) {
                        SoundTestButton(
                            title: "せいかい",
                            icon: "checkmark.circle.fill",
                            color: .green
                        ) {
                            SoundManager.playSuccessFeedback()
                        }
                        
                        SoundTestButton(
                            title: "まちがい",
                            icon: "xmark.circle.fill",
                            color: .red
                        ) {
                            SoundManager.playErrorFeedback()
                        }
                        
                        SoundTestButton(
                            title: "ターンこうたい",
                            icon: "arrow.triangle.2.circlepath",
                            color: .blue
                        ) {
                            SoundManager.playTurnChangeFeedback()
                        }
                        
                        SoundTestButton(
                            title: "だつらく",
                            icon: "person.badge.minus",
                            color: .orange
                        ) {
                            SoundManager.playEliminationFeedback()
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.standard)
        .onAppear {
            AppLogger.shared.info("効果音設定画面表示")
        }
    }
}

/// 効果音テストボタン
private struct SoundTestButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            action()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }) {
            VStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
                    .fill(color.opacity(0.1))
                    .stroke(color, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SoundSettingsView()
}