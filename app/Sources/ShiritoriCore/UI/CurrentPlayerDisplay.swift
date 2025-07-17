import SwiftUI

/// 現在のプレイヤー表示コンポーネント
public struct CurrentPlayerDisplay: View {
    public let participant: GameParticipant
    public let timeRemaining: Int
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false
    
    public init(participant: GameParticipant, timeRemaining: Int) {
        AppLogger.shared.debug("CurrentPlayerDisplay初期化: \(participant.name), 残り時間=\(timeRemaining)秒")
        self.participant = participant
        self.timeRemaining = timeRemaining
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // プレイヤー情報
            HStack(spacing: 16) {
                PlayerAvatarView(
                    playerName: participant.name,
                    imageData: nil,
                    size: 80
                )
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isAnimating)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(participant.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .opacity(isAnimating ? 1.0 : 0.8)
                        .animation(.easeInOut(duration: 0.5), value: isAnimating)
                    
                    Text(participant.type.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(participantTypeColor.opacity(isAnimating ? 0.3 : 0.2))
                        .foregroundColor(participantTypeColor)
                        .cornerRadius(8)
                        .animation(.easeInOut(duration: 0.3), value: isAnimating)
                }
                
                Spacer()
                
                // 時間表示
                if timeRemaining > 0 {
                    TimeDisplayView(timeRemaining: timeRemaining)
                }
            }
            
            // ターン表示
            TurnIndicator(
                currentPlayerName: participant.name,
                isAnimated: true
            )
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isAnimating)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(adaptiveBackgroundColor)
                .stroke(participantTypeColor, lineWidth: isAnimating ? 4 : 3)
                .shadow(color: adaptiveShadowColor, radius: isAnimating ? 12 : 8, x: 0, y: isAnimating ? 6 : 4)
                .animation(.easeInOut(duration: 0.4), value: isAnimating)
        )
        .scaleEffect(isAnimating ? 1.02 : 1.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isAnimating)
        .onAppear {
            // 初回表示時のアニメーション
            triggerPlayerChangeAnimation()
        }
        .onChange(of: participant.id) { _, _ in
            // プレイヤー変更時のアニメーション
            triggerPlayerChangeAnimation()
        }
    }
    
    /// プレイヤー変更時のアニメーションをトリガー
    private func triggerPlayerChangeAnimation() {
        isAnimating = true
        
        // 1秒後にアニメーションを停止
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isAnimating = false
        }
    }
    
    private var participantTypeColor: Color {
        switch participant.type {
        case .human:
            return .blue
        case .computer(let difficulty):
            switch difficulty {
            case .easy:
                return .green
            case .normal:
                return .orange
            case .hard:
                return .red
            }
        }
    }
    
    private var adaptiveBackgroundColor: Color {
        if colorScheme == .dark {
            return Color.gray.opacity(0.2)
        } else {
            return Color.white
        }
    }
    
    private var adaptiveShadowColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.1)
        } else {
            return Color.black.opacity(0.1)
        }
    }
}

/// 時間表示コンポーネント
private struct TimeDisplayView: View {
    let timeRemaining: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "timer")
                .font(.title2)
                .foregroundColor(timeColor)
            
            Text(formatTime(timeRemaining))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(timeColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(timeColor.opacity(0.1))
                .stroke(timeColor, lineWidth: 2)
        )
        .scaleEffect(timeRemaining <= 10 ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: timeRemaining <= 10)
    }
    
    private var timeColor: Color {
        if timeRemaining <= 10 {
            return .red
        } else if timeRemaining <= 30 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        } else {
            return "\(remainingSeconds)"
        }
    }
}