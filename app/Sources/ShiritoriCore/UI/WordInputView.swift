import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 単語入力コンポーネント
/// UX改善により、音声認識結果が取得された時点で自動的に選択画面を表示します
public struct WordInputView: View {
    public let isEnabled: Bool
    public let currentPlayerId: String  // プレイヤー切り替え監視用
    private let onSubmit: (String) -> Void
    
    @State private var inputText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var settingsManager = SettingsManager.shared
    private let hiraganaConverter = HiraganaConverter()
    
    // 🎯 新しい@Observable状態管理による統一化
    @State private var speechRecognitionState = SpeechRecognitionState()
    @State private var speechManager = SpeechRecognitionManager()
    
    public init(
        isEnabled: Bool,
        currentPlayerId: String,
        onSubmit: @escaping (String) -> Void
    ) {
        AppLogger.shared.debug("WordInputView初期化: enabled=\(isEnabled), playerId=\(currentPlayerId)")
        self.isEnabled = isEnabled
        self.currentPlayerId = currentPlayerId
        self.onSubmit = onSubmit
    }
    
    public var body: some View {
        VStack(spacing: DesignSystem.Spacing.standard) {
            // プログレッシブガイダンスメッセージ表示
            if speechRecognitionState.showGuidanceMessage && !speechRecognitionState.guidanceMessage.isEmpty {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        // アニメーション付きアイコン
                        Image(systemName: getGuidanceIcon())
                            .font(.title2)
                            .foregroundColor(getGuidanceColor())
                            .scaleEffect(speechRecognitionState.showGuidanceMessage ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true), value: speechRecognitionState.showGuidanceMessage)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(getGuidanceTitle())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(getGuidanceColor())
                            
                            Text(speechRecognitionState.guidanceMessage)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                    }
                    
                    // 失敗進捗インジケーター（3回失敗時は非表示）
                    if speechRecognitionState.consecutiveFailureCount < 3 {
                        HStack(spacing: 4) {
                            ForEach(1...3, id: \.self) { index in
                                Circle()
                                    .fill(index <= speechRecognitionState.consecutiveFailureCount ? getGuidanceColor() : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(index == speechRecognitionState.consecutiveFailureCount ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.3), value: speechRecognitionState.consecutiveFailureCount)
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.standard)
                .padding(.vertical, DesignSystem.Spacing.mediumSmall)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(backgroundColorForCurrentPlatform)
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
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: speechRecognitionState.showGuidanceMessage)
            }
            
            // 入力モード切替（音声入力を優先的に表示）
            HStack(spacing: DesignSystem.Spacing.mediumLarge) {
                // 音声入力ボタン（左側に配置して優先度を高める）
                Button(action: {
                    speechRecognitionState.isVoiceMode = true
                    isTextFieldFocused = false
                    AppLogger.shared.debug("音声入力モードに切替")
                }) {
                    HStack {
                        Image(systemName: "mic.fill")
                        Text("おんせい")
                    }
                    .font(.caption)
                    .fontWeight(speechRecognitionState.isVoiceMode ? .bold : .regular)
                    .padding(.horizontal, DesignSystem.Spacing.standard)
                    .padding(.vertical, DesignSystem.Spacing.small)
                    .background(speechRecognitionState.isVoiceMode ? Color.red : Color.gray.opacity(0.3))
                    .foregroundColor(speechRecognitionState.isVoiceMode ? .white : .gray)
                    .cornerRadius(20)
                    .scaleEffect(speechRecognitionState.isVoiceMode ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: speechRecognitionState.isVoiceMode)
                }
                .disabled(!isEnabled)
                
                // キーボード入力ボタン（右側に配置）
                Button(action: {
                    speechRecognitionState.isVoiceMode = false
                    isTextFieldFocused = true
                    AppLogger.shared.debug("テキスト入力モードに切替")
                }) {
                    HStack {
                        Image(systemName: "keyboard")
                        Text("キーボード")
                    }
                    .font(.caption)
                    .fontWeight(speechRecognitionState.isVoiceMode ? .regular : .bold)
                    .padding(.horizontal, DesignSystem.Spacing.mediumSmall)
                    .padding(.vertical, DesignSystem.Spacing.tiny)
                    .background(speechRecognitionState.isVoiceMode ? Color.gray.opacity(0.3) : Color.blue)
                    .foregroundColor(speechRecognitionState.isVoiceMode ? .gray : .white)
                    .cornerRadius(20)
                    .scaleEffect(speechRecognitionState.isVoiceMode ? 1.0 : 1.05)
                    .animation(.easeInOut(duration: 0.2), value: speechRecognitionState.isVoiceMode)
                }
                .disabled(!isEnabled)
            }
            
            if speechRecognitionState.isVoiceMode {
                if speechRecognitionState.showRecognitionChoice {
                    // 🎯 認識結果確認UI（自動表示）
                    RecognitionResultView(
                        recognizedText: speechRecognitionState.recognitionResult,
                        onUseWord: {
                            AppLogger.shared.info("認識結果を採用: \(speechRecognitionState.recognitionResult)")
                            useRecognitionResult()
                        },
                        onRetry: {
                            AppLogger.shared.info("音声認識をやり直し")
                            retryVoiceRecognition()
                        }
                    )
                } else {
                    // 音声入力UI
                    VStack(spacing: 8) {
                        ZStack {
                            // 失敗時のシェイクアニメーション背景
                            if speechRecognitionState.consecutiveFailureCount > 0 && speechRecognitionState.consecutiveFailureCount < 3 {
                                Circle()
                                    .stroke(getGuidanceColor().opacity(0.3), lineWidth: 3)
                                    .frame(width: 120, height: 120)
                                    .scaleEffect(1.0 + (0.1 * Double(speechRecognitionState.consecutiveFailureCount)))
                                    .animation(.easeInOut(duration: 0.5).repeatCount(2, autoreverses: true), value: speechRecognitionState.consecutiveFailureCount)
                            }
                            
                            MicrophoneButton(
                                speechState: speechRecognitionState,
                                size: 100,
                                onTouchDown: {
                                    startVoiceRecording()
                                },
                                onTouchUp: {
                                    stopVoiceRecording()
                                }
                            )
                            .scaleEffect(speechRecognitionState.currentPhase.isActive ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: speechRecognitionState.currentPhase.isActive)
                            
                            // 失敗カウンター表示（バッジ風）
                            if speechRecognitionState.consecutiveFailureCount > 0 && speechRecognitionState.consecutiveFailureCount < 3 {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Circle()
                                            .fill(getGuidanceColor())
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Text("\(speechRecognitionState.consecutiveFailureCount)")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            )
                                            .offset(x: 10, y: -10)
                                            .transition(.scale.combined(with: .opacity))
                                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: speechRecognitionState.consecutiveFailureCount)
                                    }
                                    Spacer()
                                }
                                .frame(width: 100, height: 100)
                            }
                        }
                        
                        // 🎯 状態に基づく表示メッセージ
                        VStack(spacing: 4) {
                            switch speechRecognitionState.currentPhase {
                            case .idle:
                                Text("マイクを おしながら はなしてね")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            
                            case .recording:
                                Text("きいています...")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            
                            case .processing:
                                VStack(spacing: 2) {
                                    Text("かんがえています...")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                        .opacity(0.8)
                                    
                                    if !speechRecognitionState.partialResult.isEmpty {
                                        Text("『\(speechRecognitionState.partialResult)』が きこえるかな？")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                            .padding(.horizontal, DesignSystem.Spacing.small)
                                            .padding(.vertical, DesignSystem.Spacing.extraSmall)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.blue.opacity(0.1))
                                            )
                                    }
                                }
                                
                            case .resultReady:
                                // 🎯 認識結果表示フェーズ（自動遷移前の短期間表示）
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                        .scaleEffect(1.2)
                                    
                                    Text("『\(speechRecognitionState.recognitionResult)』が きこえました！")
                                        .font(.callout)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, DesignSystem.Spacing.standard)
                                .padding(.vertical, DesignSystem.Spacing.small)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.green.opacity(0.15), Color.mint.opacity(0.1)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .stroke(Color.green.opacity(0.4), lineWidth: 2)
                                        .shadow(color: .green.opacity(0.2), radius: 4, x: 0, y: 2)
                                )
                                .multilineTextAlignment(.center)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(y: -10)),
                                    removal: .scale(scale: 1.1).combined(with: .opacity).combined(with: .offset(y: 10))
                                ))
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: speechRecognitionState.recognitionResult)
                                
                            case .choiceDisplayed, .completed, .failed:
                                EmptyView()
                            }
                        }
                    }
                    .frame(minHeight: 140, maxHeight: 160)
                    .frame(maxWidth: .infinity)
                }
            } else {
                // テキスト入力UI
                VStack(spacing: 12) {
                    HStack {
                        TextField("ことばを いれてね", text: $inputText)
                            .font(.title2)
                            .padding(DesignSystem.Spacing.standard)
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
                .frame(minHeight: 120, maxHeight: 140)
            }
        }
        .padding(DesignSystem.Spacing.standard)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .opacity(isEnabled ? 1.0 : 0.6)
        .onAppear {
            initializeInputMode()
        }
        // プレイヤー変更時の自動リセット処理
        .onChange(of: currentPlayerId) { _, newPlayerId in
            AppLogger.shared.info("プレイヤー切り替え検出: \(newPlayerId) - 音声認識状態をリセット")
            
            // 音声認識が進行中の場合は安全に停止
            if speechRecognitionState.currentPhase.isActive {
                AppLogger.shared.info("進行中の音声認識を停止: \(speechRecognitionState.currentPhase)")
                speechManager.stopRecording()
            }
            
            // 完全なリセット処理（両方のマネージャーをリセット）
            speechRecognitionState.resetForNewTurn()
            speechManager.resetForNewTurn()
            inputText = ""
            isTextFieldFocused = false
            initializeInputMode()
        }
        // 🎯 状態変更の監視（遅延処理の代替）
        .onChange(of: speechRecognitionState.currentPhase) { _, newPhase in
            handlePhaseChange(newPhase)
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
        guard isEnabled && speechRecognitionState.currentPhase == .idle else { return }
        
        AppLogger.shared.info("🎤 音声録音開始")
        speechRecognitionState.startRecording()
        inputText = ""
        
        Task {
            await speechManager.startRecording { recognizedText in
                Task { @MainActor in
                    let hiraganaText = hiraganaConverter.convertToHiragana(recognizedText)
                    
                    // 中間結果更新（処理中段階）
                    if speechRecognitionState.currentPhase == .recording {
                        speechRecognitionState.startProcessing()
                    }
                    
                    // リアルタイム中間結果
                    speechRecognitionState.updatePartialResult(hiraganaText, confidence: 0.8) // 仮の信頼度
                    inputText = hiraganaText
                }
            }
        }
    }
    
    private func stopVoiceRecording() {
        guard speechRecognitionState.currentPhase.isActive else { return }
        
        AppLogger.shared.info("🎤 音声録音停止")
        speechManager.stopRecording()
        
        // 🎯 状態ベースの結果処理（遅延なし）
        let finalResult = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !finalResult.isEmpty {
            // 認識成功 → 結果準備完了段階に遷移
            speechRecognitionState.completeRecognition(result: finalResult, confidence: 0.8)
        } else {
            // 認識失敗
            speechRecognitionState.recordFailure()
            handleVoiceRecognitionFailure()
        }
    }
    
    /// 🎯 段階変更時の処理（遅延処理の代替）
    private func handlePhaseChange(_ newPhase: SpeechRecognitionState.Phase) {
        AppLogger.shared.debug("音声認識段階変更対応: \(newPhase)")
        
        switch newPhase {
        case .failed:
            // 失敗時の処理
            break
        default:
            break
        }
    }
    
    /// 音声認識失敗時の処理
    private func handleVoiceRecognitionFailure() {
        let failureCount = speechRecognitionState.consecutiveFailureCount
        
        AppLogger.shared.info("音声認識失敗処理: \(failureCount)回目")
        
        // 設定に基づいて失敗閾値を更新
        speechManager.setFailureThreshold(settingsManager.speechFailureThreshold)
        
        // 自動フォールバック機能が有効で、閾値に達した場合
        if settingsManager.autoFallbackEnabled &&
           speechRecognitionState.hasReachedFailureThreshold(settingsManager.speechFailureThreshold) &&
           !speechRecognitionState.hasAutoSwitched {
            speechRecognitionState.performAutoFallback()
        }
    }
    
    /// 初期化メソッド
    private func initializeInputMode() {
        let defaultMode = settingsManager.defaultInputMode
        speechRecognitionState.isVoiceMode = defaultMode
        
        AppLogger.shared.info("入力モードを初期化: \(defaultMode ? "音声入力" : "キーボード入力")")
        
        // キーボード入力モードの場合、テキストフィールドにフォーカス
        if !defaultMode {
            isTextFieldFocused = true
        }
    }
    
    // MARK: - ヘルパーメソッド
    
    /// ガイダンスメッセージのアイコンを取得
    private func getGuidanceIcon() -> String {
        let failureCount = speechRecognitionState.consecutiveFailureCount
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
        let failureCount = speechRecognitionState.consecutiveFailureCount
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
        let failureCount = speechRecognitionState.consecutiveFailureCount
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
        speechRecognitionState.resetForNewTurn()
        inputText = ""
        initializeInputMode()
    }
    
    // MARK: - Voice Recognition Result Methods
    
    /// 認識結果を採用して提出
    private func useRecognitionResult() {
        AppLogger.shared.info("音声認識結果を採用: '\(speechRecognitionState.recognitionResult)'")
        
        // 成功を記録
        speechRecognitionState.completeWithResult()
        
        // 認識結果を入力テキストに設定
        inputText = speechRecognitionState.recognitionResult
        
        // 単語を提出
        submitWord()
    }
    
    /// 音声認識をやり直す
    private func retryVoiceRecognition() {
        AppLogger.shared.info("音声認識をやり直し - 失敗として記録")
        speechRecognitionState.retryRecognition()
        inputText = ""
        handleVoiceRecognitionFailure()
    }
}

/// 音声認識結果確認コンポーネント
private struct RecognitionResultView: View {
    let recognizedText: String
    let onUseWord: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.standard) {
            // ガイドメッセージ
            Text("この ことばで いいかな？")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // 認識結果を大きく表示
            VStack(spacing: 8) {
                Text(recognizedText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                    .padding(.horizontal, DesignSystem.Spacing.standard)
                    .padding(.vertical, DesignSystem.Spacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.blue.opacity(0.1))
                            .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2) // 長いテキストでも見切れないように制限
                
                Text("にんしき された ことば")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 選択ボタン（コンパクトに調整）
            HStack(spacing: 12) {
                // やり直すボタン（サイズ調整）
                Button(action: onRetry) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.callout)
                        Text("やりなおす")
                            .font(.callout)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.standard)
                    .padding(.vertical, DesignSystem.Spacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.orange)
                    )
                    .shadow(color: .orange.opacity(0.3), radius: 3, x: 0, y: 1)
                }
                
                // 採用ボタン（サイズ調整）
                Button(action: onUseWord) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("つかう")
                            .font(.callout)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.mediumLarge)
                    .padding(.vertical, DesignSystem.Spacing.mediumSmall)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: .green.opacity(0.4), radius: 4, x: 0, y: 2)
                }
                .scaleEffect(1.02) // 軽微な強調のみ
            }
        }
        .frame(minHeight: 160, maxHeight: 200) // 高さ制限を緩和
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.primary.opacity(0.05))
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: recognizedText)
    }
}