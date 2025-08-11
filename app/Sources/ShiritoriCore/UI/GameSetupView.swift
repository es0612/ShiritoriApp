import SwiftUI
import SwiftData

/// ゲーム設定画面のメインビュー
public struct GameSetupView: View {
    private let onStartGame: (GameSetupData, [GameParticipant], GameRulesConfig) -> Void
    private let onCancel: () -> Void
    
    @State private var selectedPlayers: Set<String> = []
    @State private var selectedComputers: Set<DifficultyLevel> = []
    @State private var gameRules = GameRulesConfig()
    
    // UIState統合による状態管理
    @State private var uiState = UIState.shared
    @State private var showGameStartConfirmation = false
    
    private var showRulesEditor: Bool {
        uiState.getTransitionPhase("gameSetup_rulesEditor") == "shown"
    }
    
    private var showRulesEditorBinding: Binding<Bool> {
        Binding(
            get: { showRulesEditor },
            set: { newValue in
                if newValue {
                    uiState.setTransitionPhase("shown", for: "gameSetup_rulesEditor")
                } else {
                    uiState.setTransitionPhase("hidden", for: "gameSetup_rulesEditor")
                }
            }
        )
    }
    
    private var canStartGame: Bool {
        let totalParticipants = selectedPlayers.count + selectedComputers.count
        return totalParticipants >= 2 && totalParticipants <= gameRules.maxPlayers
    }
    
    @Query private var availablePlayers: [Player]
    @Environment(\.modelContext) private var modelContext
    
    public init(
        onStartGame: @escaping (GameSetupData, [GameParticipant], GameRulesConfig) -> Void,
        onCancel: @escaping () -> Void
    ) {
        AppLogger.shared.debug("GameSetupView初期化")
        self.onStartGame = onStartGame
        self.onCancel = onCancel
    }
    
    public var body: some View {
        ZStack {
            ChildFriendlyBackground(animationSpeed: 0.3)
            
            VStack(spacing: 0) {
                // 上部のボタン領域
                HStack {
                    BackButton {
                        AppLogger.shared.info("ゲーム設定をキャンセル")
                        onCancel()
                    }
                    
                    Spacer()
                    
                    // スタートボタンを上部に配置
                    ChildFriendlyButton(
                        title: "🎯 スタート",
                        backgroundColor: canStartGame ? .green : .gray,
                        foregroundColor: .white
                    ) {
                        showGameStartConfirmation = true
                    }
                    .disabled(!canStartGame)
                }
                .padding(.horizontal, DesignSystem.Spacing.standard)
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        // ヘッダー
                        VStack(spacing: DesignSystem.Spacing.small) {
                            Text("🎮 ゲーム せってい")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            
                            Text("だれと あそぶか えらんでね")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top)
                        
                        // プレイヤー選択セクション
                        VStack(alignment: .leading, spacing: 16) {
                            Text("👥 プレイヤー")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(availablePlayers, id: \.name) { player in
                                    PlayerSelectionCard(
                                        playerName: player.name,
                                        isSelected: selectedPlayers.contains(player.name),
                                        onSelectionChanged: { isSelected in
                                            togglePlayerSelection(player.name, isSelected: isSelected)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // コンピュータ選択セクション
                        VStack(alignment: .leading, spacing: 16) {
                            Text("🤖 コンピュータ")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                                    ComputerPlayerCard(
                                        difficultyLevel: difficulty,
                                        isSelected: selectedComputers.contains(difficulty),
                                        onSelectionChanged: { isSelected in
                                            toggleComputerSelection(difficulty, isSelected: isSelected)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // ルール設定セクション
                        VStack(alignment: .leading, spacing: 16) {
                            Text("⚙️ ルール")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            
                            RulesDisplayCard(
                                timeLimit: gameRules.timeLimit,
                                winCondition: gameRules.winCondition,
                                onEdit: {
                                    uiState.setTransitionPhase("shown", for: "gameSetup_rulesEditor")
                                }
                            )
                        }
                        .padding(.horizontal)
                        
                        // 参加者数表示
                        ParticipantCountView(
                            selectedPlayersCount: selectedPlayers.count,
                            selectedComputersCount: selectedComputers.count
                        )
                        .padding(.horizontal)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .sheet(isPresented: showRulesEditorBinding) {
            RulesEditorSheet(
                rules: gameRules,
                participantCount: selectedPlayers.count + selectedComputers.count,
                onSave: { newRules in
                    gameRules = newRules
                    uiState.setTransitionPhase("hidden", for: "gameSetup_rulesEditor")
                },
                onCancel: {
                    uiState.setTransitionPhase("hidden", for: "gameSetup_rulesEditor")
                }
            )
        }
        .sheet(isPresented: $showGameStartConfirmation) {
            GameStartConfirmationSheet(
                participants: createParticipants(),
                rules: gameRules,
                onConfirm: {
                    showGameStartConfirmation = false
                    startGame()
                },
                onCancel: {
                    showGameStartConfirmation = false
                }
            )
        }
    }
    
    private func togglePlayerSelection(_ playerName: String, isSelected: Bool) {
        if isSelected {
            selectedPlayers.insert(playerName)
        } else {
            selectedPlayers.remove(playerName)
        }
        AppLogger.shared.debug("プレイヤー選択変更: \(playerName) -> \(isSelected)")
    }
    
    private func toggleComputerSelection(_ difficulty: DifficultyLevel, isSelected: Bool) {
        if isSelected {
            selectedComputers.insert(difficulty)
        } else {
            selectedComputers.remove(difficulty)
        }
        AppLogger.shared.debug("コンピュータ選択変更: \(difficulty) -> \(isSelected)")
    }
    
    private func startGame() {
        let participants = createParticipants()
        let turnOrder = participants.map { $0.id }
        let setupData = GameSetupData(
            participants: participants,
            rules: gameRules,
            turnOrder: turnOrder
        )
        
        AppLogger.shared.info("ゲーム開始: 参加者\(participants.count)人")
        onStartGame(setupData, participants, gameRules)
    }
    
    private func createParticipants() -> [GameParticipant] {
        var participants: [GameParticipant] = []
        
        // 人間プレイヤー
        for playerName in selectedPlayers {
            participants.append(GameParticipant(
                id: "human_\(playerName)",
                name: playerName,
                type: .human
            ))
        }
        
        // コンピュータプレイヤー
        for difficulty in selectedComputers {
            participants.append(GameParticipant(
                id: "computer_\(difficulty.rawValue)",
                name: "コンピュータ(\(difficulty.displayName))",
                type: .computer(difficulty: difficulty)
            ))
        }
        
        return participants.shuffled() // ランダムな順序
    }
}