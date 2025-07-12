import SwiftUI

/// ゲーム設定画面のメインビュー
public struct GameSetupView: View {
    private let onStartGame: (GameSetupData, [GameParticipant], GameRulesConfig) -> Void
    private let onCancel: () -> Void
    
    @State private var selectedPlayers: Set<String> = []
    @State private var selectedComputers: Set<DifficultyLevel> = []
    @State private var gameRules = GameRulesConfig()
    @State private var showRulesEditor = false
    
    // サンプルプレイヤーデータ
    @State private var availablePlayers = [
        PlayerData(name: "たろうくん", gamesPlayed: 5, gamesWon: 3),
        PlayerData(name: "はなちゃん", gamesPlayed: 3, gamesWon: 2),
        PlayerData(name: "けんくん", gamesPlayed: 1, gamesWon: 0)
    ]
    
    public init(
        onStartGame: @escaping (GameSetupData, [GameParticipant], GameRulesConfig) -> Void,
        onCancel: @escaping () -> Void
    ) {
        AppLogger.shared.debug("GameSetupView初期化")
        self.onStartGame = onStartGame
        self.onCancel = onCancel
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                ChildFriendlyBackground(animationSpeed: 0.3)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // ヘッダー
                        VStack(spacing: 8) {
                            Text("🎮 ゲーム せっていv")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("だれと あそぶか えらんでね")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top)
                        
                        // プレイヤー選択セクション
                        VStack(alignment: .leading, spacing: 16) {
                            Text("👥 プレイヤー")
                                .font(.title2)
                                .fontWeight(.bold)
                            
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
                            
                            RulesDisplayCard(
                                timeLimit: gameRules.timeLimit,
                                winCondition: gameRules.winCondition,
                                onEdit: {
                                    showRulesEditor = true
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
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    ChildFriendlyButton(
                        title: "もどる",
                        backgroundColor: .gray,
                        foregroundColor: .white
                    ) {
                        AppLogger.shared.info("ゲーム設定をキャンセル")
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ChildFriendlyButton(
                        title: "🎯 スタート",
                        backgroundColor: canStartGame ? .green : .gray,
                        foregroundColor: .white
                    ) {
                        startGame()
                    }
                    .disabled(!canStartGame)
                }
            }
        }
        .sheet(isPresented: $showRulesEditor) {
            RulesEditorSheet(
                rules: gameRules,
                onSave: { newRules in
                    gameRules = newRules
                    showRulesEditor = false
                },
                onCancel: {
                    showRulesEditor = false
                }
            )
        }
    }
    
    private var canStartGame: Bool {
        let totalParticipants = selectedPlayers.count + selectedComputers.count
        return totalParticipants >= 2 && totalParticipants <= gameRules.maxPlayers
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