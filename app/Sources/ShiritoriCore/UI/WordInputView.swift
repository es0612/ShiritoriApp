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
            // 入力モード切替
            HStack(spacing: 20) {
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isVoiceMode ? Color.gray.opacity(0.3) : Color.blue)
                    .foregroundColor(isVoiceMode ? .gray : .white)
                    .cornerRadius(20)
                }
                .disabled(!isEnabled)
                
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isVoiceMode ? Color.red : Color.gray.opacity(0.3))
                    .foregroundColor(isVoiceMode ? .white : .gray)
                    .cornerRadius(20)
                }
                .disabled(!isEnabled)
            }
            
            if isVoiceMode {
                // 音声入力UI
                VStack(spacing: 12) {
                    MicrophoneButton(
                        isRecording: isRecording,
                        onTouchDown: {
                            startVoiceRecording()
                        },
                        onTouchUp: {
                            stopVoiceRecording()
                        }
                    )
                    
                    Text(isRecording ? "話しています..." : "マイクボタンを押して話してください")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if !inputText.isEmpty {
                        Text("認識された言葉: \(inputText)")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal)
                    }
                }
                .frame(height: 120)
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
                .frame(height: 120)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .opacity(isEnabled ? 1.0 : 0.6)
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
        let word = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !word.isEmpty else { return }
        
        AppLogger.shared.info("単語提出: '\(word)'")
        onSubmit(word)
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
                    
                    // 音声認識結果をひらがなに変換
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
        
        // 認識されたテキストがあれば自動で提出
        if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            AppLogger.shared.debug("音声認識結果を自動提出")
            submitWord()
        }
    }
}