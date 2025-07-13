import SwiftUI

/// 単語入力コンポーネント
public struct WordInputView: View {
    public let isEnabled: Bool
    private let onSubmit: (String) -> Void
    
    @State private var inputText = ""
    @State private var isVoiceMode = false
    @FocusState private var isTextFieldFocused: Bool
    
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
                        isRecording: false,
                        onTouchDown: {
                            AppLogger.shared.info("音声入力開始")
                            // TODO: 音声認識の実装
                        },
                        onTouchUp: {
                            AppLogger.shared.info("音声入力終了")
                            // TODO: 音声認識の実装
                        }
                    )
                    
                    Text("マイクボタンを押して話してください")
                        .font(.caption)
                        .foregroundColor(.gray)
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
                                    .fill(Color.white)
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
    
    private func submitWord() {
        let word = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !word.isEmpty else { return }
        
        AppLogger.shared.info("単語提出: '\(word)'")
        onSubmit(word)
        inputText = ""
    }
}