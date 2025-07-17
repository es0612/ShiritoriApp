import SwiftUI

/// アプリケーション設定画面
public struct SettingsView: View {
    private let onDismiss: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var settingsManager = SettingsManager.shared
    
    public init(onDismiss: @escaping () -> Void) {
        AppLogger.shared.debug("SettingsView初期化")
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                ChildFriendlyBackground(animationSpeed: 0.3)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // ヘッダー
                        VStack(spacing: 8) {
                            Text("⚙️ せってい")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            
                            Text("あそびかたを かえられるよ")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top)
                        
                        // 入力方式設定
                        SettingsSectionCard(
                            title: "📝 にゅうりょく ほうほう",
                            description: "どちらで ことばを いれるか えらんでね"
                        ) {
                            InputModeSelectionView()
                        }
                        
                        // 音声設定
                        SettingsSectionCard(
                            title: "🎤 おんせい せってい",
                            description: "おんせいにゅうりょくの せってい"
                        ) {
                            VoiceSettingsView()
                        }
                        
                        // 効果音設定
                        SettingsSectionCard(
                            title: "🔊 こうかおん せってい",
                            description: "ゲームちゅうの おとの せってい"
                        ) {
                            SoundSettingsView()
                        }
                        
                        // その他の設定
                        SettingsSectionCard(
                            title: "🔧 そのほか",
                            description: "その他の設定"
                        ) {
                            OtherSettingsView()
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    ChildFriendlyButton(
                        title: "もどる",
                        backgroundColor: .blue,
                        foregroundColor: .white
                    ) {
                        AppLogger.shared.info("設定画面を閉じる")
                        onDismiss()
                    }
                }
            }
        }
    }
}

/// 設定セクションカード
private struct SettingsSectionCard<Content: View>: View {
    let title: String
    let description: String
    let content: Content
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        title: String,
        description: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.description = description
        self.content = content()
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color.white
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackgroundColor)
                .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

/// 入力方式選択ビュー
private struct InputModeSelectionView: View {
    @State private var settingsManager = SettingsManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(InputMode.allCases) { mode in
                let isSelected = (mode == .voice) == settingsManager.defaultInputMode
                
                ChildFriendlyButton(
                    title: "\(mode.iconName == "mic.fill" ? "🎤" : "⌨️") \(mode.displayName)",
                    backgroundColor: isSelected ? .green : .gray.opacity(0.3),
                    foregroundColor: isSelected ? .white : .primary
                ) {
                    let isVoiceMode = (mode == .voice)
                    AppLogger.shared.info("入力方式を変更: \(mode.displayName)")
                    settingsManager.updateDefaultInputMode(isVoiceMode)
                }
                .overlay(
                    VStack(spacing: 4) {
                        Spacer()
                        Text(mode.childFriendlyDescription)
                            .font(.caption2)
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    }
                    .padding(.bottom, 8)
                )
            }
            
            // 現在の設定表示
            HStack {
                Text("いまの せってい:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(settingsManager.getInputModeDisplayName())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                
                Spacer()
            }
            .padding(.top, 8)
        }
    }
}

/// 音声設定ビュー
private struct VoiceSettingsView: View {
    @State private var settingsManager = SettingsManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // 音声自動提出設定
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("じどう そうしん")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("はなしおわったら じどうで ことばを おくるよ")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { settingsManager.voiceAutoSubmit },
                    set: { newValue in
                        AppLogger.shared.info("音声自動提出を変更: \(newValue)")
                        settingsManager.updateVoiceAutoSubmit(newValue)
                    }
                ))
                .labelsHidden()
            }
            
            Divider()
            
            // 音声感度設定
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("おんせい かんど")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(settingsManager.voiceSensitivity * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
                
                Text("こえの きこえやすさを ちょうせいするよ")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Slider(
                    value: Binding(
                        get: { settingsManager.voiceSensitivity },
                        set: { newValue in
                            AppLogger.shared.debug("音声感度を変更: \(newValue)")
                            settingsManager.updateVoiceSensitivity(newValue)
                        }
                    ),
                    in: 0.0...1.0,
                    step: 0.1
                )
                .accentColor(.blue)
                
                HStack {
                    Text("ひくい")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("たかい")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// その他の設定ビュー
private struct OtherSettingsView: View {
    @State private var settingsManager = SettingsManager.shared
    @State private var showResetAlert = false
    
    var body: some View {
        VStack(spacing: 12) {
            // リセットボタン
            ChildFriendlyButton(
                title: "🔄 せってい リセット",
                backgroundColor: .orange,
                foregroundColor: .white
            ) {
                AppLogger.shared.info("設定リセットを要求")
                showResetAlert = true
            }
            
            Text("すべての せってい を もとに もどすよ")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            // デバッグ情報（開発用）
            #if DEBUG
            Divider()
                .padding(.vertical, 8)
            
            ChildFriendlyButton(
                title: "🐛 デバッグ情報",
                backgroundColor: .gray,
                foregroundColor: .white
            ) {
                settingsManager.printDebugInfo()
            }
            #endif
        }
        .alert("せってい リセット", isPresented: $showResetAlert) {
            Button("キャンセル", role: .cancel) {
                AppLogger.shared.debug("設定リセットをキャンセル")
            }
            
            Button("リセット", role: .destructive) {
                AppLogger.shared.info("設定をリセット実行")
                settingsManager.resetToDefaults()
            }
        } message: {
            Text("すべての せってい を もとに もどしますか？")
        }
    }
}