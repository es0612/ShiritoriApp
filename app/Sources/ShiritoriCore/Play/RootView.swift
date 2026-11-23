import SwiftUI

/// アプリの最初の画面。状態に合わせて、タイトル・あそぶ画面・あそべない画面を出し分ける。
public struct RootView: View {
    @State private var viewModel: PlayViewModel

    /// 本物の部品（同梱の辞書・端末内の音声認識・OS の読み上げ）で組み立てる
    public init() {
        let bank: WordBank
        do {
            bank = try WordBank.bundled()
        } catch {
            // 同梱の辞書が読めないのはビルドの不備。落とさず、空の辞書で「ことばが なくなっちゃった」に進ませる
            AppLog.play.error("辞書を読み込めない: \(String(describing: error), privacy: .public)")
            bank = WordBank(words: [])
        }
        self.init(viewModel: PlayViewModel(bank: bank, listener: OnDeviceSpeechListener(), speaker: SystemSpeaker()))
    }

    /// プレビューやテストで、偽物の部品を入れた状態を渡す
    public init(viewModel: PlayViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        switch viewModel.phase {
        case .title:
            TitleView(viewModel: viewModel)
        case .unavailable(let availability):
            UnavailableView(viewModel: viewModel, availability: availability)
        case .appSpeaking, .waitingForChild, .listening, .finished:
            PlayView(viewModel: viewModel)
                .overlay {
                    if viewModel.phase == .finished {
                        FinishOverlay(viewModel: viewModel)
                    }
                }
        }
    }
}

#if DEBUG
#Preview("タイトル") {
    RootView(viewModel: .preview())
}
#endif
