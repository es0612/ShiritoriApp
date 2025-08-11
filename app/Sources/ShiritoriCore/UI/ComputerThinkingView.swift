import SwiftUI

/// コンピュータ思考中表示コンポーネント
public struct ComputerThinkingView: View {
    // UIState統合によるアニメーション管理
    @State private var uiState = UIState.shared
    
    private var animationPhase: Int {
        Int(uiState.animationValues["computerThinking_phase"] ?? 0.0)
    }
    
    public init() {
        AppLogger.shared.debug("ComputerThinkingView初期化")
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // アニメーション付きのロボットアイコン
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .scaleEffect(1.0 + sin(Double(animationPhase) * 0.3) * 0.1)
                    .rotationEffect(.degrees(sin(Double(animationPhase) * 0.2) * 5))
                    .animation(.easeInOut(duration: 0.5), value: animationPhase)
                
                // 思考中の点々アニメーション
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                            .scaleEffect(thinkingDotScale(for: index))
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: animationPhase
                            )
                    }
                }
            }
            
            // メッセージ
            VStack(spacing: 8) {
                Text("コンピュータが かんがえています...")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("すこし まってね")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
        )
        .onAppear {
            startAnimation()
        }
    }
    
    private func thinkingDotScale(for index: Int) -> CGFloat {
        let phase = (animationPhase + index * 20) % 100
        return 0.5 + sin(Double(phase) * 0.1) * 0.5
    }
    
    private func startAnimation() {
        // UIState統合によるアニメーション開始
        let phaseKey = "computerThinking_phase"
        
        uiState.setAnimationValue(0.0, for: phaseKey)
        uiState.startAnimation(phaseKey)
        
        // Timer.scheduledTimer の代替として UIState による連続的なアニメーション更新
        schedulePhaseUpdate()
    }
    
    private func schedulePhaseUpdate() {
        let phaseKey = "computerThinking_phase"
        let currentPhase = uiState.animationValues[phaseKey] ?? 0.0
        let nextPhase = (currentPhase + 1.0).truncatingRemainder(dividingBy: 100.0)
        
        uiState.setAnimationValue(nextPhase, for: phaseKey)
        
        // UIState自動遷移による連続更新（Timer.scheduledTimerの代替）
        uiState.scheduleAutoTransition(for: "computerThinking_update", after: 0.1) {
            self.schedulePhaseUpdate()
        }
    }
}