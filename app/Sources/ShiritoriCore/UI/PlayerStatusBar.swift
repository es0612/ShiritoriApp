import SwiftUI

/// ゲーム中のプレイヤー状況表示バー
public struct PlayerStatusBar: View {
    public let participants: [GameParticipant]
    public let currentTurnIndex: Int
    public let eliminatedPlayers: Set<String>
    
    public init(
        participants: [GameParticipant],
        currentTurnIndex: Int,
        eliminatedPlayers: Set<String>
    ) {
        AppLogger.shared.debug("PlayerStatusBar初期化: 参加者\(participants.count)人, 現在のターン=\(currentTurnIndex), 脱落者=\(eliminatedPlayers.count)人")
        self.participants = participants
        self.currentTurnIndex = currentTurnIndex
        self.eliminatedPlayers = eliminatedPlayers
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // タイトル
            HStack {
                Text("👥 プレイヤー状況")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Spacer()
                
                // アクティブプレイヤー数表示
                Text("残り: \(activePlayerCount)人")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.2))
                    )
            }
            
            // プレイヤー状況表示
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(participants.enumerated()), id: \.offset) { index, participant in
                        PlayerStatusCard(
                            participant: participant,
                            isCurrentTurn: index == currentTurnIndex,
                            isEliminated: eliminatedPlayers.contains(participant.id)
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
        )
    }
    
    private var activePlayerCount: Int {
        participants.count - eliminatedPlayers.count
    }
}


/// 個別プレイヤーの状況カード
private struct PlayerStatusCard: View {
    let participant: GameParticipant
    let isCurrentTurn: Bool
    let isEliminated: Bool
    
    private var playerStatus: PlayerAvatarStatus {
        if isEliminated {
            return .eliminated
        } else if isCurrentTurn {
            return .currentTurn
        } else {
            return .normal
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // 統合されたプレイヤーアバター
            PlayerAvatarViewWithStatus(
                playerName: participant.name,
                imageData: nil,
                size: 45,
                status: playerStatus
            )
            .scaleEffect(isCurrentTurn ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCurrentTurn)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEliminated)
            
            // プレイヤー名
            Text(participant.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isEliminated ? .gray : .primary)
                .lineLimit(1)
                .truncationMode(.tail)
            
            // 状況表示
            statusIndicator
        }
        .frame(width: 80)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .opacity(isEliminated ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isEliminated)
    }
    
    private var statusIndicator: some View {
        Group {
            if isEliminated {
                Text("❌ 脱落")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            } else if isCurrentTurn {
                HStack(spacing: 2) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 4, height: 4)
                        .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 0.6).repeatForever(), value: pulseAnimation)
                    
                    Text("ターン")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .onAppear {
                    pulseAnimation = true
                }
                .onDisappear {
                    pulseAnimation = false
                }
            } else {
                Text("待機中")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
    }
    
    @State private var pulseAnimation = false
    
    private var backgroundColor: Color {
        if isEliminated {
            return Color.gray.opacity(0.1)
        } else if isCurrentTurn {
            return Color.orange.opacity(0.2)
        } else {
            return Color.blue.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        if isEliminated {
            return Color.gray.opacity(0.3)
        } else if isCurrentTurn {
            return Color.orange
        } else {
            return Color.blue.opacity(0.3)
        }
    }
    
    private var borderWidth: CGFloat {
        isCurrentTurn ? 2 : 1
    }
}

#Preview {
    let participants = [
        GameParticipant(id: "1", name: "太郎", type: .human),
        GameParticipant(id: "2", name: "花子", type: .human),
        GameParticipant(id: "3", name: "AI簡単", type: .computer(difficulty: .easy)),
        GameParticipant(id: "4", name: "AI普通", type: .computer(difficulty: .normal))
    ]
    
    VStack(spacing: 20) {
        // 全員アクティブな状態
        PlayerStatusBar(
            participants: participants,
            currentTurnIndex: 1,
            eliminatedPlayers: []
        )
        
        // 一人脱落した状態
        PlayerStatusBar(
            participants: participants,
            currentTurnIndex: 0,
            eliminatedPlayers: ["3"]
        )
        
        // 複数人脱落した状態
        PlayerStatusBar(
            participants: participants,
            currentTurnIndex: 1,
            eliminatedPlayers: ["2", "4"]
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}