import SwiftUI

/// プレイヤー管理画面のメインビュー
public struct PlayerManagementView: View {
    private let onDismiss: () -> Void
    
    @State private var showAddPlayerSheet = false
    @State private var players: [PlayerData] = []
    
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
            loadPlayers()
        }
    }
    
    private func loadPlayers() {
        // テスト用のサンプルデータ
        players = [
            PlayerData(name: "たろうくん", gamesPlayed: 5, gamesWon: 3),
            PlayerData(name: "はなちゃん", gamesPlayed: 3, gamesWon: 2),
            PlayerData(name: "けんくん", gamesPlayed: 1, gamesWon: 0)
        ]
        AppLogger.shared.info("プレイヤーデータを読み込み: \(players.count)人")
    }
    
    private func addPlayer(name: String) {
        let newPlayer = PlayerData(name: name, gamesPlayed: 0, gamesWon: 0)
        players.append(newPlayer)
        AppLogger.shared.info("新しいプレイヤーを追加: \(name)")
        showAddPlayerSheet = false
    }
    
    private func editPlayer(_ player: PlayerData) {
        AppLogger.shared.info("プレイヤー編集: \(player.name)")
        // 今後実装
    }
    
    private func deletePlayer(_ player: PlayerData) {
        players.removeAll { $0.name == player.name }
        AppLogger.shared.info("プレイヤーを削除: \(player.name)")
    }
}

/// プレイヤーのデータ構造体
public struct PlayerData {
    public let name: String
    public let gamesPlayed: Int
    public let gamesWon: Int
    
    public var winRate: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(gamesWon) / Double(gamesPlayed)
    }
    
    public init(name: String, gamesPlayed: Int, gamesWon: Int) {
        self.name = name
        self.gamesPlayed = gamesPlayed
        self.gamesWon = gamesWon
    }
}