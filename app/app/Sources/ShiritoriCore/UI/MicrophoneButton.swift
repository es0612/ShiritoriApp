import SwiftUI

/// 音声入力用マイクボタンコンポーネント
public struct MicrophoneButton: View {
    public let isRecording: Bool
    public let size: CGFloat
    private let onTouchDown: () -> Void
    private let onTouchUp: () -> Void
    
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
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red : Color.blue)
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    .scaleEffect(isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isRecording)
                
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
            
            Text(isRecording ? "はなしています..." : "おしながら はなしてね")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}