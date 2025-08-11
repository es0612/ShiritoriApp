import SwiftUI
import SwiftData

/// プレイヤー管理画面のメインビュー
public struct PlayerManagementView: View {
    private let onDismiss: () -> Void
    
    // UIState統合による状態管理
    @State private var uiState = UIState.shared
    @Query private var players: [Player]
    @Environment(\.modelContext) private var modelContext
    
    // 削除確認ダイアログ用の状態管理
    @State private var playerToDelete: Player?
    
    private var showAddPlayerSheet: Bool {
        uiState.getTransitionPhase("playerManagement_addPlayerSheet") == "shown"
    }
    
    private var showAddPlayerSheetBinding: Binding<Bool> {
        Binding(
            get: { showAddPlayerSheet },
            set: { newValue in
                if newValue {
                    uiState.setTransitionPhase("shown", for: "playerManagement_addPlayerSheet")
                } else {
                    uiState.setTransitionPhase("hidden", for: "playerManagement_addPlayerSheet")
                }
            }
        )
    }
    
    private var showDeleteConfirmation: Bool {
        uiState.getTransitionPhase("playerManagement_deleteConfirmation") == "shown"
    }
    
    private var showDeleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { showDeleteConfirmation },
            set: { newValue in
                if newValue {
                    uiState.setTransitionPhase("shown", for: "playerManagement_deleteConfirmation")
                } else {
                    uiState.setTransitionPhase("hidden", for: "playerManagement_deleteConfirmation")
                    playerToDelete = nil // ダイアログが閉じられた時に削除対象をクリア
                }
            }
        )
    }
    
    public init(onDismiss: @escaping () -> Void) {
        AppLogger.shared.debug("PlayerManagementView初期化")
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            ChildFriendlyBackground(animationSpeed: 0.5)
            
            VStack(spacing: 0) {
                    // 上部のボタン領域
                    HStack {
                        BackButton {
                            AppLogger.shared.info("プレイヤー管理画面を閉じる")
                            onDismiss()
                        }
                        
                        Spacer()
                        
                        ChildFriendlyButton(
                            title: "➕ ついか",
                            backgroundColor: .green,
                            foregroundColor: .white
                        ) {
                            AppLogger.shared.info("新しいプレイヤー追加を開始")
                            uiState.setTransitionPhase("shown", for: "playerManagement_addPlayerSheet")
                        }
                        .padding(.trailing, DesignSystem.Spacing.large)
                        .padding(.top, DesignSystem.Spacing.small)
                    }
                    
                    // ヘッダー
                    VStack(spacing: 8) {
                        Text("👤 プレイヤー とうろく")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text("ゲームであ そぶ ひとを とうろくしよう")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, DesignSystem.Spacing.large)
                    .padding(.bottom, DesignSystem.Spacing.standard)
                    
                    // メインコンテンツ
                    VStack(spacing: 20) {
                    if players.isEmpty {
                        EmptyPlayerListView(onAddPlayer: {
                            uiState.setTransitionPhase("shown", for: "playerManagement_addPlayerSheet")
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
                                            showDeleteConfirmation(for: player)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: showAddPlayerSheetBinding) {
            AddPlayerSheet(
                isPresented: showAddPlayerSheetBinding,
                onSave: { newPlayerName in
                    addPlayer(name: newPlayerName)
                },
                onCancel: {
                    uiState.setTransitionPhase("hidden", for: "playerManagement_addPlayerSheet")
                }
            )
        }
        .alert(playerToDelete?.name != nil ? "\(playerToDelete!.name)を けします" : "プレイヤーを けします", isPresented: showDeleteConfirmationBinding) {
            Button("キャンセル", role: .cancel) {
                AppLogger.shared.debug("プレイヤー削除をキャンセル")
            }
            
            Button("けす", role: .destructive) {
                if let player = playerToDelete {
                    confirmDeletePlayer(player)
                }
            }
        } message: {
            Text("いちど けすと、もとに もどせません。\nこのプレイヤーの せいせき も きえてしまいます。\nほんとうに けしますか？")
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
        uiState.setTransitionPhase("hidden", for: "playerManagement_addPlayerSheet")
    }
    
    private func editPlayer(_ player: Player) {
        AppLogger.shared.info("プレイヤー編集: \(player.name)")
        // 今後実装
    }
    
    private func showDeleteConfirmation(for player: Player) {
        AppLogger.shared.info("プレイヤー削除確認ダイアログ表示: \(player.name)")
        playerToDelete = player
        uiState.setTransitionPhase("shown", for: "playerManagement_deleteConfirmation")
    }
    
    private func confirmDeletePlayer(_ player: Player) {
        modelContext.delete(player)
        try? modelContext.save()
        AppLogger.shared.info("プレイヤーを削除: \(player.name)")
    }
}