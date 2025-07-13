import SwiftUI

/// 現在のプレイヤー表示コンポーネント
public struct CurrentPlayerDisplay: View {
    public let participant: GameParticipant
    public let timeRemaining: Int
    
    @Environment(\.colorScheme) private var colorScheme
    
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
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(participant.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(participant.type.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(participantTypeColor.opacity(0.2))
                        .foregroundColor(participantTypeColor)
                        .cornerRadius(8)
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
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(adaptiveBackgroundColor)
                .stroke(participantTypeColor, lineWidth: 3)
                .shadow(color: adaptiveShadowColor, radius: 8, x: 0, y: 4)
        )
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