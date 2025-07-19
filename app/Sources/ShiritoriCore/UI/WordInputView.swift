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
                    MicrophoneButton(
                        isRecording: isRecording,
                        size: 100, // サイズを少し小さく調整
                        onTouchDown: {
                            startVoiceRecording()
                        },
                        onTouchUp: {
                            stopVoiceRecording()
                        }
                    )
                    
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
        
        // テキスト入力時もしりとり用に正規化
        let normalizedWord = hiraganaConverter.convertToHiraganaForShiritori(sanitizedWord)
        
        if normalizedWord != sanitizedWord {
            AppLogger.shared.info("テキスト入力正規化: '\(sanitizedWord)' -> '\(normalizedWord)'")
        }
        AppLogger.shared.info("単語提出: '\(normalizedWord)'")
        
        onSubmit(normalizedWord)
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
                    
                    // 音声認識結果をひらがなに変換し、しりとり用に正規化
                    let hiraganaText = hiraganaConverter.convertToHiraganaForShiritori(recognizedText)
                    AppLogger.shared.info("しりとり用ひらがな変換: '\(recognizedText)' -> '\(hiraganaText)'")
                    
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
        
        // 自動提出設定が有効で、認識されたテキストがあれば自動で提出
        if settingsManager.voiceAutoSubmit && !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            AppLogger.shared.debug("音声認識結果を自動提出")
            submitWord()
        } else if !settingsManager.voiceAutoSubmit {
            AppLogger.shared.debug("自動提出が無効のため、手動提出が必要")
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
}