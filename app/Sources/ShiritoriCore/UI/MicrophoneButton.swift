import SwiftUI

/// 音声入力用マイクボタンコンポーネント
public struct MicrophoneButton: View {
    public let speechState: SpeechRecognitionState
    public let size: CGFloat
    private let onTouchDown: () -> Void
    private let onTouchUp: () -> Void
    
    // UIState統合によるアニメーション管理
    @State private var uiState = UIState.shared
    
    public init(
        speechState: SpeechRecognitionState,
        size: CGFloat = 120,
        onTouchDown: @escaping () -> Void,
        onTouchUp: @escaping () -> Void
    ) {
        AppLogger.shared.debug("MicrophoneButton初期化: 段階=\(speechState.currentPhase), サイズ=\(size)")
        self.speechState = speechState
        self.size = size
        self.onTouchDown = onTouchDown
        self.onTouchUp = onTouchUp
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // 背景円（状態に基づく色変更）
                Circle()
                    .fill(backgroundColorForPhase)
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    .scaleEffect(scaleEffectForPhase)
                    .animation(.easeInOut(duration: 0.2), value: speechState.currentPhase)
                
                // パルスエフェクト（アクティブ時）
                if speechState.currentPhase.isActive {
                    Circle()
                        .strokeBorder(pulseColorForPhase.opacity(0.4), lineWidth: 4)
                        .frame(width: size + 20, height: size + 20)
                        .scaleEffect(pulseScale)
                        .opacity(2.0 - pulseScale)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false), value: pulseScale)
                }
                
                // プロセシングリング（処理中のみ表示）
                if speechState.currentPhase == .processing {
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(Color.white.opacity(0.8), lineWidth: 3)
                        .frame(width: size - 20, height: size - 20)
                        .rotationEffect(.degrees(processingRotation))
                        .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: processingRotation)
                }
                
                // 結果準備完了時のチェックマークオーバーレイ
                if speechState.currentPhase == .resultReady {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: size, height: size)
                        .overlay(
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: size * 0.3))
                                .foregroundColor(.green)
                                .scaleEffect(1.2)
                        )
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: speechState.currentPhase)
                }
                
                // メインマイクアイコン
                Image(systemName: iconNameForPhase)
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.white)
                    .scaleEffect(iconScaleForPhase)
                    .animation(.easeInOut(duration: 0.2), value: speechState.currentPhase)
            }
            .onTapGesture {
                handleTap()
            }
            .zIndex(10) // 他のUI要素との重複を防ぐ
            .onAppear {
                setupAnimationForPhase(speechState.currentPhase)
            }
            .onChange(of: speechState.currentPhase) { _, newPhase in
                AppLogger.shared.debug("MicrophoneButton段階変更対応: \(newPhase)")
                setupAnimationForPhase(newPhase)
            }
            
            // 状態に応じた詳細メッセージ
            messageViewForPhase
        }
        .frame(maxWidth: .infinity) // 中央配置の確保
    }
    
    // MARK: - Computed Properties
    
    /// 段階に基づく背景色
    private var backgroundColorForPhase: Color {
        switch speechState.currentPhase {
        case .idle:
            return .blue
        case .recording:
            return .red
        case .processing:
            return .orange
        case .resultReady:
            return .green
        case .choiceDisplayed, .completed:
            return .gray
        case .failed:
            return .red.opacity(0.7)
        }
    }
    
    /// 段階に基づくスケール効果
    private var scaleEffectForPhase: CGFloat {
        switch speechState.currentPhase {
        case .idle:
            return 1.0
        case .recording, .processing:
            return 1.1
        case .resultReady:
            return 1.15
        case .choiceDisplayed, .completed:
            return 0.95
        case .failed:
            return 1.05
        }
    }
    
    /// パルス効果の色
    private var pulseColorForPhase: Color {
        switch speechState.currentPhase {
        case .recording:
            return .red
        case .processing:
            return .orange
        default:
            return .blue
        }
    }
    
    /// アイコン名
    private var iconNameForPhase: String {
        switch speechState.currentPhase {
        case .idle:
            return "mic.fill"
        case .recording:
            return "mic.fill"
        case .processing:
            return "waveform"
        case .resultReady:
            return "mic.badge.plus"
        case .choiceDisplayed, .completed:
            return "checkmark"
        case .failed:
            return "mic.slash.fill"
        }
    }
    
    /// アイコンスケール
    private var iconScaleForPhase: CGFloat {
        switch speechState.currentPhase {
        case .recording, .processing:
            return 1.2
        case .resultReady:
            return 1.3
        case .failed:
            return 1.1
        default:
            return 1.0
        }
    }
    
    /// UIStateからのアニメーション値取得
    private var pulseScale: CGFloat {
        CGFloat(uiState.animationValues["micPulse"] ?? 1.0)
    }
    
    private var processingRotation: Double {
        uiState.animationValues["micRotation"] ?? 0.0
    }
    
    /// 段階別メッセージビュー
    @ViewBuilder
    private var messageViewForPhase: some View {
        VStack(spacing: 4) {
            Text(primaryMessageForPhase)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(messageColorForPhase)
                .multilineTextAlignment(.center)
            
            if let secondaryMessage = secondaryMessageForPhase {
                Text(secondaryMessage)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .opacity(0.8)
                    .multilineTextAlignment(.center)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .animation(.easeInOut(duration: 0.3), value: speechState.currentPhase)
    }
    
    /// 主要メッセージ
    private var primaryMessageForPhase: String {
        switch speechState.currentPhase {
        case .idle:
            return "おしなから はなしてね"
        case .recording:
            return "音声を認識中..."
        case .processing:
            if !speechState.partialResult.isEmpty {
                return "認識中: \(speechState.partialResult)"
            } else {
                return "処理しています"
            }
        case .resultReady:
            return "認識完了！"
        case .choiceDisplayed:
            return "選択してください"
        case .completed:
            return "完了しました"
        case .failed:
            return "もう一度お試しください"
        }
    }
    
    /// 補助メッセージ
    private var secondaryMessageForPhase: String? {
        switch speechState.currentPhase {
        case .processing:
            return "しばらくお待ちください"
        case .resultReady:
            return "自動で選択画面に移ります"
        case .failed:
            return "ゆっくりはっきりと話してみてください"
        default:
            return nil
        }
    }
    
    /// メッセージ色
    private var messageColorForPhase: Color {
        switch speechState.currentPhase {
        case .idle:
            return .secondary
        case .recording:
            return .red
        case .processing:
            return .orange
        case .resultReady:
            return .green
        case .choiceDisplayed, .completed:
            return .primary
        case .failed:
            return .red
        }
    }
    
    // MARK: - Methods
    
    /// タップ処理
    private func handleTap() {
        AppLogger.shared.debug("MicrophoneButtonタップ: 段階=\(speechState.currentPhase)")
        
        switch speechState.currentPhase {
        case .idle:
            onTouchDown()
        case .recording, .processing:
            onTouchUp()
        case .resultReady, .choiceDisplayed, .completed, .failed:
            // これらの段階では直接操作を受け付けない
            AppLogger.shared.debug("段階 \(speechState.currentPhase) での直接操作は無効")
        }
    }
    
    /// 段階に応じたアニメーション設定
    private func setupAnimationForPhase(_ phase: SpeechRecognitionState.Phase) {
        switch phase {
        case .idle:
            stopAllAnimations()
            
        case .recording:
            startPulseAnimation()
            
        case .processing:
            startPulseAnimation()
            startRotationAnimation()
            
        case .resultReady:
            stopAllAnimations()
            // 短期間の成功アニメーション
            uiState.scheduleAutoTransition(for: "micSuccessEffect", after: 0.5) {
                // 成功エフェクト完了
            }
            
        case .choiceDisplayed, .completed, .failed:
            stopAllAnimations()
        }
    }
    
    /// パルスアニメーション開始
    private func startPulseAnimation() {
        uiState.setAnimationValue(1.0, for: "micPulse")
        uiState.startAnimation("micPulse")
        
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
            uiState.setAnimationValue(1.4, for: "micPulse")
        }
    }
    
    /// 回転アニメーション開始
    private func startRotationAnimation() {
        uiState.setAnimationValue(0.0, for: "micRotation")
        uiState.startAnimation("micRotation")
        
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            uiState.setAnimationValue(360.0, for: "micRotation")
        }
    }
    
    /// 全アニメーション停止
    private func stopAllAnimations() {
        uiState.endAnimation("micPulse")
        uiState.endAnimation("micRotation")
        
        withAnimation(.easeInOut(duration: 0.3)) {
            uiState.setAnimationValue(1.0, for: "micPulse")
            uiState.setAnimationValue(0.0, for: "micRotation")
        }
    }
}