import SwiftUI

/// 音声入力用マイクボタンコンポーネント
public struct MicrophoneButton: View {
    public let isRecording: Bool
    public let size: CGFloat
    private let onTouchDown: () -> Void
    private let onTouchUp: () -> Void
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var processingRotation: Double = 0.0
    
    public init(
        isRecording: Bool,
        size: CGFloat = 120,
        onTouchDown: @escaping () -> Void,
        onTouchUp: @escaping () -> Void
    ) {
        AppLogger.shared.debug("MicrophoneButton初期化: 録音中=\(isRecording), サイズ=\(size)")
        self.isRecording = isRecording
        self.size = size
        self.onTouchDown = onTouchDown
        self.onTouchUp = onTouchUp
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // 背景円
                Circle()
                    .fill(isRecording ? Color.red : Color.blue)
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    .scaleEffect(isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isRecording)
                
                // 録音中のパルスエフェクト
                if isRecording {
                    Circle()
                        .strokeBorder(Color.red.opacity(0.4), lineWidth: 4)
                        .frame(width: size + 20, height: size + 20)
                        .scaleEffect(pulseScale)
                        .opacity(2.0 - pulseScale)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false), value: pulseScale)
                }
                
                // 音声認識中のプロセシングリング
                if isRecording {
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(Color.white.opacity(0.8), lineWidth: 3)
                        .frame(width: size - 20, height: size - 20)
                        .rotationEffect(.degrees(processingRotation))
                        .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: processingRotation)
                }
                
                // マイクアイコン
                Image(systemName: "mic.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.white)
                    .scaleEffect(isRecording ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isRecording)
            }
            .onTapGesture {
                // シンプルなタップ処理（テスト用）
                if isRecording {
                    onTouchUp()
                } else {
                    onTouchDown()
                }
            }
            .zIndex(10) // 他のUI要素との重複を防ぐ
            .onAppear {
                if isRecording {
                    startRecordingAnimation()
                }
            }
            .onChange(of: isRecording) { _, recording in
                if recording {
                    startRecordingAnimation()
                } else {
                    stopRecordingAnimation()
                }
            }
            
            // 状態に応じたメッセージ
            VStack(spacing: 4) {
                Text(isRecording ? "音声を認識中..." : "おしながら はなしてね")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if isRecording {
                    Text("処理しています")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .opacity(0.8)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity) // 中央配置の確保
    }
    
    // MARK: - Animation Methods
    
    private func startRecordingAnimation() {
        pulseScale = 1.0
        processingRotation = 0.0
        
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
            pulseScale = 1.4
        }
        
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            processingRotation = 360.0
        }
    }
    
    private func stopRecordingAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            pulseScale = 1.0
            processingRotation = 0.0
        }
    }
}