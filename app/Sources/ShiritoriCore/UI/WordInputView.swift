import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 単語入力コンポーネント（UI表示専用）
/// ビジネスロジックはSpeechRecognitionControllerとInputValidationManagerに分離済み
public struct WordInputView: View {
    public let isEnabled: Bool
    public let currentPlayerId: String  // プレイヤー切り替え監視用
    private let onSubmit: (String) -> Void
    
    @State private var inputText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    // 🎯 新しいアーキテクチャ：責務分離済みのコントローラー
    @State private var speechController = SpeechRecognitionController()
    @State private var validationManager = InputValidationManager()
    
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
            if speechController.showGuidanceMessage && !speechController.guidanceMessage.isEmpty {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        // アニメーション付きアイコン
                        Image(systemName: speechController.getGuidanceIcon())
                            .font(.title2)
                            .foregroundColor(speechController.getGuidanceColor())
                            .scaleEffect(speechController.showGuidanceMessage ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true), value: speechController.showGuidanceMessage)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(speechController.getGuidanceTitle())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(speechController.getGuidanceColor())
                            
                            Text(speechController.guidanceMessage)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                    }
                    
                    // 失敗進捗インジケーター（3回失敗時は非表示）
                    if speechController.consecutiveFailureCount < 3 {
                        HStack(spacing: 4) {
                            ForEach(1...3, id: \.self) { index in
                                Circle()
                                    .fill(index <= speechController.consecutiveFailureCount ? speechController.getGuidanceColor() : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(index == speechController.consecutiveFailureCount ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.3), value: speechController.consecutiveFailureCount)
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.standard)
                .padding(.vertical, DesignSystem.Spacing.mediumSmall)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(GameUIHelpers.backgroundColorForCurrentPlatform)
                        .shadow(color: speechController.getGuidanceColor().opacity(0.2), radius: 8, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(speechController.getGuidanceColor().opacity(0.3), lineWidth: 2)
                        )
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.8)).combined(with: .offset(y: -20)),
                    removal: .opacity.combined(with: .scale(scale: 0.9))
                ))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: speechController.showGuidanceMessage)
            }
            
            // 入力モード切替（音声入力を優先的に表示）
            HStack(spacing: DesignSystem.Spacing.mediumLarge) {
                // 音声入力ボタン（左側に配置して優先度を高める）
                Button(action: {
                    speechController.switchToVoiceMode()
                    isTextFieldFocused = false
                }) {
                    HStack {
                        Image(systemName: "mic.fill")
                        Text("おんせい")
                    }
                    .font(.caption)
                    .fontWeight(speechController.isVoiceMode ? .bold : .regular)
                    .padding(.horizontal, DesignSystem.Spacing.standard)
                    .padding(.vertical, DesignSystem.Spacing.small)
                    .background(speechController.isVoiceMode ? Color.red : Color.gray.opacity(0.3))
                    .foregroundColor(speechController.isVoiceMode ? .white : .gray)
                    .cornerRadius(20)
                    .scaleEffect(speechController.isVoiceMode ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: speechController.isVoiceMode)
                }
                .disabled(!isEnabled)
                
                // キーボード入力ボタン（右側に配置）
                Button(action: {
                    speechController.switchToKeyboardMode()
                    isTextFieldFocused = true
                }) {
                    HStack {
                        Image(systemName: "keyboard")
                        Text("キーボード")
                    }
                    .font(.caption)
                    .fontWeight(speechController.isVoiceMode ? .regular : .bold)
                    .padding(.horizontal, DesignSystem.Spacing.mediumSmall)
                    .padding(.vertical, DesignSystem.Spacing.tiny)
                    .background(speechController.isVoiceMode ? Color.gray.opacity(0.3) : Color.blue)
                    .foregroundColor(speechController.isVoiceMode ? .gray : .white)
                    .cornerRadius(20)
                    .scaleEffect(speechController.isVoiceMode ? 1.0 : 1.05)
                    .animation(.easeInOut(duration: 0.2), value: speechController.isVoiceMode)
                }
                .disabled(!isEnabled)
            }
            
            if speechController.isVoiceMode {
                if speechController.showRecognitionChoice {
                    // 🎯 認識結果確認UI（自動表示）
                    RecognitionResultView(
                        recognizedText: speechController.recognitionResult,
                        onUseWord: {
                            AppLogger.shared.info("認識結果を採用: \(speechController.recognitionResult)")
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
                            if speechController.consecutiveFailureCount > 0 && speechController.consecutiveFailureCount < 3 {
                                Circle()
                                    .stroke(speechController.getGuidanceColor().opacity(0.3), lineWidth: 3)
                                    .frame(width: 120, height: 120)
                                    .scaleEffect(1.0 + (0.1 * Double(speechController.consecutiveFailureCount)))
                                    .animation(.easeInOut(duration: 0.5).repeatCount(2, autoreverses: true), value: speechController.consecutiveFailureCount)
                            }
                            
                            MicrophoneButton(
                                speechState: speechController.speechState,
                                size: 100,
                                onTouchDown: {
                                    startVoiceRecording()
                                },
                                onTouchUp: {
                                    stopVoiceRecording()
                                }
                            )
                            .scaleEffect(speechController.currentPhase.isActive ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: speechController.currentPhase.isActive)
                            
                            // 失敗カウンター表示（バッジ風）
                            if speechController.consecutiveFailureCount > 0 && speechController.consecutiveFailureCount < 3 {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Circle()
                                            .fill(speechController.getGuidanceColor())
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Text("\(speechController.consecutiveFailureCount)")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            )
                                            .offset(x: 10, y: -10)
                                            .transition(.scale.combined(with: .opacity))
                                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: speechController.consecutiveFailureCount)
                                    }
                                    Spacer()
                                }
                                .frame(width: 100, height: 100)
                            }
                        }
                        
                        // 🎯 状態に基づく表示メッセージ
                        VStack(spacing: 4) {
                            switch speechController.currentPhase {
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
                                    
                                    if !speechController.partialResult.isEmpty {
                                        Text("『\(speechController.partialResult)』が きこえるかな？")
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
                                    
                                    Text("『\(speechController.recognitionResult)』が きこえました！")
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
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: speechController.recognitionResult)
                                
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
                                    .fill(GameUIHelpers.backgroundColorForCurrentPlatform)
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
            speechController.initializeInputMode()
        }
        // プレイヤー変更時の自動リセット処理
        .onChange(of: currentPlayerId) { _, newPlayerId in
            AppLogger.shared.info("プレイヤー切り替え検出: \(newPlayerId) - 音声認識状態をリセット")
            
            // 完全なリセット処理
            speechController.resetForNewTurn(playerId: newPlayerId)
            inputText = ""
            isTextFieldFocused = false
        }
    }
    
    private var canSubmit: Bool {
        isEnabled && !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func submitWord() {
        let validationResult = validationManager.validateForSubmission(inputText)
        
        switch validationResult {
        case .valid(let processedWord, _):
            AppLogger.shared.info("単語提出: '\(processedWord)'")
            onSubmit(processedWord)
            inputText = ""
            
        case .empty(let reason), .invalid(let reason):
            AppLogger.shared.warning("入力検証失敗: \(reason)")
            // エラー表示は呼び出し元で処理
            inputText = ""
        }
    }
    
    // MARK: - Voice Recognition Methods
    
    private func startVoiceRecording() {
        guard isEnabled else { return }
        
        if speechController.startVoiceRecording() {
            inputText = ""
        }
    }
    
    private func stopVoiceRecording() {
        if let result = speechController.stopVoiceRecording() {
            inputText = result
        }
    }
    
    /// 認識結果を採用して提出
    private func useRecognitionResult() {
        let result = speechController.useRecognitionResult()
        inputText = result
        submitWord()
    }
    
    /// 音声認識をやり直す
    private func retryVoiceRecognition() {
        speechController.retryVoiceRecognition()
        inputText = ""
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