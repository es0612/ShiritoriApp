import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 単語入力コンポーネント
public struct WordInputView: View {
    public let isEnabled: Bool
    private let onSubmit: (String) -> Void
    
    @State private var inputText = ""
    @State private var isVoiceMode = false
    @State private var speechManager = SpeechRecognitionManager()
    @State private var isRecording = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var settingsManager = SettingsManager.shared
    private let hiraganaConverter = HiraganaConverter()
    
    // 自動フォールバック機能
    @State private var showFallbackMessage = false
    @State private var guidanceMessage = ""
    @State private var hasAutoSwitched = false
    
    public init(
        isEnabled: Bool,
        onSubmit: @escaping (String) -> Void
    ) {
        AppLogger.shared.debug("WordInputView初期化: enabled=\(isEnabled)")
        self.isEnabled = isEnabled
        self.onSubmit = onSubmit
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // プログレッシブガイダンスメッセージ表示
            if showFallbackMessage && !guidanceMessage.isEmpty {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        // アニメーション付きアイコン
                        Image(systemName: getGuidanceIcon())
                            .font(.title2)
                            .foregroundColor(getGuidanceColor())
                            .scaleEffect(showFallbackMessage ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true), value: showFallbackMessage)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(getGuidanceTitle())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(getGuidanceColor())
                            
                            Text(guidanceMessage)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                    }
                    
                    // 失敗進捗インジケーター（3回失敗時は非表示）
                    if speechManager.consecutiveFailureCount < 3 {
                        HStack(spacing: 4) {
                            ForEach(1...3, id: \.self) { index in
                                Circle()
                                    .fill(index <= speechManager.consecutiveFailureCount ? getGuidanceColor() : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(index == speechManager.consecutiveFailureCount ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.3), value: speechManager.consecutiveFailureCount)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: getGuidanceColor().opacity(0.2), radius: 8, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(getGuidanceColor().opacity(0.3), lineWidth: 2)
                        )
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.8)).combined(with: .offset(y: -20)),
                    removal: .opacity.combined(with: .scale(scale: 0.9))
                ))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showFallbackMessage)
            }
            
            // 入力モード切替（音声入力を優先的に表示）
            HStack(spacing: 20) {
                // 音声入力ボタン（左側に配置して優先度を高める）
                Button(action: {
                    isVoiceMode = true
                    isTextFieldFocused = false
                    AppLogger.shared.debug("音声入力モードに切替")
                }) {
                    HStack {
                        Image(systemName: "mic.fill")
                        Text("おんせい")
                    }
                    .font(.caption)
                    .fontWeight(isVoiceMode ? .bold : .regular)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isVoiceMode ? Color.red : Color.gray.opacity(0.3))
                    .foregroundColor(isVoiceMode ? .white : .gray)
                    .cornerRadius(20)
                    .scaleEffect(isVoiceMode ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isVoiceMode)
                }
                .disabled(!isEnabled)
                
                // キーボード入力ボタン（右側に配置）
                Button(action: {
                    isVoiceMode = false
                    isTextFieldFocused = true
                    AppLogger.shared.debug("テキスト入力モードに切替")
                }) {
                    HStack {
                        Image(systemName: "keyboard")
                        Text("キーボード")
                    }
                    .font(.caption)
                    .fontWeight(isVoiceMode ? .regular : .bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isVoiceMode ? Color.gray.opacity(0.3) : Color.blue)
                    .foregroundColor(isVoiceMode ? .gray : .white)
                    .cornerRadius(20)
                    .scaleEffect(isVoiceMode ? 1.0 : 1.05)
                    .animation(.easeInOut(duration: 0.2), value: isVoiceMode)
                }
                .disabled(!isEnabled)
            }
            
            if isVoiceMode {
                // 音声入力UI
                VStack(spacing: 8) {
                    ZStack {
                        // 失敗時のシェイクアニメーション背景
                        if speechManager.consecutiveFailureCount > 0 && speechManager.consecutiveFailureCount < 3 {
                            Circle()
                                .stroke(getGuidanceColor().opacity(0.3), lineWidth: 3)
                                .frame(width: 120, height: 120)
                                .scaleEffect(1.0 + (0.1 * Double(speechManager.consecutiveFailureCount)))
                                .animation(.easeInOut(duration: 0.5).repeatCount(2, autoreverses: true), value: speechManager.consecutiveFailureCount)
                        }
                        
                        MicrophoneButton(
                            isRecording: isRecording,
                            size: 100,
                            onTouchDown: {
                                startVoiceRecording()
                            },
                            onTouchUp: {
                                stopVoiceRecording()
                            }
                        )
                        .scaleEffect(isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isRecording)
                        
                        // 失敗カウンター表示（バッジ風）
                        if speechManager.consecutiveFailureCount > 0 && speechManager.consecutiveFailureCount < 3 {
                            VStack {
                                HStack {
                                    Spacer()
                                    Circle()
                                        .fill(getGuidanceColor())
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Text("\(speechManager.consecutiveFailureCount)")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        )
                                        .offset(x: 10, y: -10)
                                        .transition(.scale.combined(with: .opacity))
                                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: speechManager.consecutiveFailureCount)
                                }
                                Spacer()
                            }
                            .frame(width: 100, height: 100)
                        }
                    }
                    
                    if !inputText.isEmpty {
                        Text("認識された言葉: \(inputText)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.1))
                            )
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(minHeight: 140, maxHeight: 160) // 適応的な高さ設定
                .frame(maxWidth: .infinity)
            } else {
                // テキスト入力UI
                VStack(spacing: 12) {
                    HStack {
                        TextField("ことばを いれてね", text: $inputText)
                            .font(.title2)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(backgroundColorForCurrentPlatform)
                                    .stroke(isEnabled ? Color.blue : Color.gray, lineWidth: 2)
                            )
                            .focused($isTextFieldFocused)
                            .disabled(!isEnabled)
                            .onSubmit {
                                submitWord()
                            }
                        
                        Button(action: {
                            guard canSubmit else { return }
                            submitWord()
                        }) {
                            Text("🆗")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(canSubmit ? Color.green : Color.gray)
                                .cornerRadius(30)
                        }
                        .disabled(!canSubmit)
                    }
                    
                    Text("さいごの もじから はじまる ことばを いれてね")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(minHeight: 120, maxHeight: 140) // テキスト入力UIも適応的な高さに
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .opacity(isEnabled ? 1.0 : 0.6)
        .onAppear {
            initializeInputMode()
        }
    }
    
    private var canSubmit: Bool {
        isEnabled && !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var backgroundColorForCurrentPlatform: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #else
        return Color.white
        #endif
    }
    
    private func submitWord() {
        let rawWord = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawWord.isEmpty else { return }
        
        // 入力を清浄化（無効な文字を除去）
        let wordValidator = WordValidator()
        let sanitizedWord = wordValidator.sanitizeInput(rawWord)
        
        if sanitizedWord.isEmpty {
            AppLogger.shared.warning("清浄化後に空文字になりました: '\(rawWord)'")
            inputText = ""
            return
        }
        
        if sanitizedWord != rawWord {
            AppLogger.shared.info("入力清浄化: '\(rawWord)' -> '\(sanitizedWord)'")
        }
        
        // ひらがなに変換（正規化は行わない）
        let hiraganaWord = hiraganaConverter.convertToHiragana(sanitizedWord)
        
        if hiraganaWord != sanitizedWord {
            AppLogger.shared.info("ひらがな変換: '\(sanitizedWord)' -> '\(hiraganaWord)'")
        }
        
        AppLogger.shared.info("単語提出: '\(hiraganaWord)'")
        onSubmit(hiraganaWord)
        inputText = ""
    }
    
    // MARK: - Voice Recognition Methods
    
    private func startVoiceRecording() {
        guard isEnabled && !isRecording else { return }
        
        AppLogger.shared.info("音声録音開始")
        isRecording = true
        inputText = ""
        
        Task {
            await speechManager.startRecording { recognizedText in
                Task { @MainActor in
                    AppLogger.shared.debug("音声認識テキスト受信: '\(recognizedText)'")
                    
                    // 音声認識結果をひらがなに変換（正規化は行わない）
                    let hiraganaText = hiraganaConverter.convertToHiragana(recognizedText)
                    AppLogger.shared.info("ひらがな変換: '\(recognizedText)' -> '\(hiraganaText)'")
                    
                    inputText = hiraganaText
                }
            }
        }
    }
    
    private func stopVoiceRecording() {
        guard isRecording else { return }
        
        AppLogger.shared.info("音声録音停止")
        isRecording = false
        speechManager.stopRecording()
        
        // 音声認識結果をチェック
        let hasValidInput = !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        if hasValidInput {
            // 成功：失敗カウンターをリセット
            speechManager.recordRecognitionSuccess()
            hideGuidanceMessage()
            
            // 自動提出設定が有効なら提出
            if settingsManager.voiceAutoSubmit {
                AppLogger.shared.debug("音声認識結果を自動提出")
                submitWord()
            } else {
                AppLogger.shared.debug("自動提出が無効のため、手動提出が必要")
            }
        } else {
            // 失敗：カウンターを増加し、ガイダンスを表示
            speechManager.incrementFailureCount()
            handleVoiceRecognitionFailure()
        }
    }
    
    /// 音声認識失敗時の処理
    private func handleVoiceRecognitionFailure() {
        let failureCount = speechManager.consecutiveFailureCount
        
        AppLogger.shared.info("音声認識失敗処理: \(failureCount)回目")
        
        // 設定に基づいて失敗閾値を更新
        speechManager.setFailureThreshold(settingsManager.speechFailureThreshold)
        
        // 段階的ガイダンスメッセージを表示
        updateGuidanceMessage(for: failureCount)
        
        // 自動フォールバック機能が有効で、閾値に達した場合
        if settingsManager.autoFallbackEnabled && 
           speechManager.hasReachedFailureThreshold() && 
           !hasAutoSwitched {
            performAutoFallback()
        } else if !settingsManager.autoFallbackEnabled && speechManager.hasReachedFailureThreshold() {
            // 自動フォールバック無効時は最終メッセージのみ表示
            AppLogger.shared.info("自動フォールバック無効：手動でキーボード入力に切り替えてください")
            guidanceMessage = "キーボードボタンを押して入力してください"
            showFallbackMessage = true
        }
    }
    
    /// 自動フォールバックを実行
    private func performAutoFallback() {
        AppLogger.shared.info("音声認識3回連続失敗：キーボード入力に自動切り替え")
        
        // アニメーション付きで切り替え実行
        withAnimation(.easeInOut(duration: 0.8)) {
            hasAutoSwitched = true
            isVoiceMode = false
        }
        
        // 少し遅れてテキストフィールドにフォーカス
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isTextFieldFocused = true
        }
        
        // フォールバック専用メッセージを表示
        guidanceMessage = "キーボードで入力してみよう！"
        
        // エフェクト付きでメッセージ表示
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showFallbackMessage = true
        }
        
        // 特別なビジュアルエフェクト（パルス効果）
        addFallbackPulseEffect()
        
        // 3秒後にメッセージを自動で隠す
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            hideGuidanceMessage()
        }
    }
    
    /// フォールバック時のパルス効果
    private func addFallbackPulseEffect() {
        // キーボードボタンを強調するパルス効果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)) {
                // パルス効果を示すための状態変数が必要（実際の実装では@Stateで管理）
            }
        }
    }
    
    /// ガイダンスメッセージを更新
    private func updateGuidanceMessage(for failureCount: Int) {
        switch failureCount {
        case 1:
            guidanceMessage = "もう一度話してみてね"
        case 2:
            guidanceMessage = "ゆっくり はっきり話してみてね"
        default:
            guidanceMessage = ""
        }
        
        if !guidanceMessage.isEmpty {
            showFallbackMessage = true
            
            // 2秒後にメッセージを隠す（3回目失敗時は除く）
            if failureCount < 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    hideGuidanceMessage()
                }
            }
        }
    }
    
    /// ガイダンスメッセージを隠す
    private func hideGuidanceMessage() {
        withAnimation(.easeOut(duration: 0.3)) {
            showFallbackMessage = false
        }
    }
    
    // MARK: - 初期化メソッド
    
    /// 設定に基づいて初期入力モードを設定
    private func initializeInputMode() {
        let defaultMode = settingsManager.defaultInputMode
        isVoiceMode = defaultMode
        
        AppLogger.shared.info("入力モードを初期化: \(defaultMode ? "音声入力" : "キーボード入力")")
        
        // キーボード入力モードの場合、テキストフィールドにフォーカス
        if !defaultMode {
            isTextFieldFocused = true
        }
    }
    
    // MARK: - ヘルパーメソッド
    
    /// ガイダンスメッセージのアイコンを取得
    private func getGuidanceIcon() -> String {
        let failureCount = speechManager.consecutiveFailureCount
        switch failureCount {
        case 1:
            return "exclamationmark.circle"
        case 2:
            return "exclamationmark.triangle"
        case 3:
            return "keyboard"
        default:
            return "info.circle"
        }
    }
    
    /// ガイダンスメッセージの色を取得
    private func getGuidanceColor() -> Color {
        let failureCount = speechManager.consecutiveFailureCount
        switch failureCount {
        case 1:
            return .blue
        case 2:
            return .orange
        case 3:
            return .red
        default:
            return .gray
        }
    }
    
    /// ガイダンスメッセージのタイトルを取得
    private func getGuidanceTitle() -> String {
        let failureCount = speechManager.consecutiveFailureCount
        switch failureCount {
        case 1:
            return "ちょっと待って！"
        case 2:
            return "がんばって！"
        case 3:
            return "キーボードを使おう！"
        default:
            return "ヒント"
        }
    }
    
    /// 新しいターン開始時の状態リセット
    public func resetForNewTurn() {
        AppLogger.shared.debug("WordInputView: 新しいターンのためのリセット")
        
        // 失敗トラッキング状態をリセット
        speechManager.resetFailureCount()
        hasAutoSwitched = false
        hideGuidanceMessage()
        
        // 入力状態をリセット
        inputText = ""
        isRecording = false
        
        // デフォルト入力モードに戻す
        initializeInputMode()
    }
}