import SwiftUI
import SwiftData

/// プレイヤー管理画面のメインビュー
public struct PlayerManagementView: View {
    private let onDismiss: () -> Void
    
    @State private var showAddPlayerSheet = false
    @Query private var players: [Player]
    @Environment(\.modelContext) private var modelContext
    
    public init(onDismiss: @escaping () -> Void) {
        AppLogger.shared.debug("PlayerManagementView初期化")
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                ChildFriendlyBackground(animationSpeed: 0.5)
                
                VStack(spacing: 20) {
                    if players.isEmpty {
                        EmptyPlayerListView(onAddPlayer: {
                            showAddPlayerSheet = true
                        })
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(players, id: \.name) { player in
                                    PlayerCardView(
                                        playerName: player.name,
                                        gamesPlayed: player.gamesPlayed,
                                        gamesWon: player.gamesWon,
                                        onEdit: {
                                            editPlayer(player)
                                        },
                                        onDelete: {
                                            deletePlayer(player)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("👤 プレイヤー とうろく")
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    ChildFriendlyButton(
                        title: "もどる",
                        backgroundColor: .gray,
                        foregroundColor: .white
                    ) {
                        AppLogger.shared.info("プレイヤー管理画面を閉じる")
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ChildFriendlyButton(
                        title: "➕ ついか",
                        backgroundColor: .green,
                        foregroundColor: .white
                    ) {
                        AppLogger.shared.info("新しいプレイヤー追加を開始")
                        showAddPlayerSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showAddPlayerSheet) {
            AddPlayerSheet(
                isPresented: $showAddPlayerSheet,
                onSave: { newPlayerName in
                    addPlayer(name: newPlayerName)
                },
                onCancel: {
                    showAddPlayerSheet = false
                }
            )
        }
        .onAppear {
            initializeDefaultPlayersIfNeeded()
        }
    }
    
    private func initializeDefaultPlayersIfNeeded() {
        if players.isEmpty {
            let defaultPlayers = [
                Player(name: "たろうくん"),
                Player(name: "はなちゃん"),
                Player(name: "けんくん")
            ]
            
            for player in defaultPlayers {
                modelContext.insert(player)
            }
            
            // 初期統計データの設定
            defaultPlayers[0].updateStats(won: true)
            defaultPlayers[0].updateStats(won: false)
            defaultPlayers[0].updateStats(won: true)
            defaultPlayers[0].updateStats(won: true)
            defaultPlayers[0].updateStats(won: false)
            
            defaultPlayers[1].updateStats(won: true)
            defaultPlayers[1].updateStats(won: false)
            defaultPlayers[1].updateStats(won: true)
            
            defaultPlayers[2].updateStats(won: false)
            
            try? modelContext.save()
            AppLogger.shared.info("初期プレイヤーデータを作成: \(defaultPlayers.count)人")
        }
    }
    
    private func addPlayer(name: String) {
        let newPlayer = Player(name: name)
        modelContext.insert(newPlayer)
        try? modelContext.save()
        AppLogger.shared.info("新しいプレイヤーを追加: \(name)")
        showAddPlayerSheet = false
    }
    
    private func editPlayer(_ player: Player) {
        AppLogger.shared.info("プレイヤー編集: \(player.name)")
        // 今後実装
    }
    
    private func deletePlayer(_ player: Player) {
        modelContext.delete(player)
        try? modelContext.save()
        AppLogger.shared.info("プレイヤーを削除: \(player.name)")
    }
}