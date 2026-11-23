import SwiftUI

/// あそぶ画面（設計書 §5.1）。M1 では見た目を作り込まず、文字とボタンだけ。
struct PlayView: View {
    let viewModel: PlayViewModel

    var body: some View {
        VStack(spacing: 20) {
            header
            Spacer(minLength: 0)
            appWord
            Text(Phrases.nextHead(viewModel.headLabel))
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Spacer(minLength: 0)
            micButton
            heardRow
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack {
            Text("⭐ \(viewModel.chainCount)かい つながった")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .accessibilityLabel("\(viewModel.chainCount)かい つながった")
            Spacer()
            Button("おしまい") { viewModel.finishTapped() }
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .buttonStyle(.bordered)
                .accessibilityLabel("おしまい")
        }
    }

    /// アプリの言葉。次に使う文字が分かるよう、最後の文字を強調する
    private var appWord: some View {
        let reading = viewModel.appWord?.reading ?? ""
        return (Text(String(reading.dropLast())) + Text(String(reading.suffix(1))).foregroundStyle(.tint))
            .font(.system(size: 64, weight: .heavy, design: .rounded))
            .minimumScaleFactor(0.3)
            .lineLimit(1)
            .accessibilityLabel(reading)
    }

    private var micButton: some View {
        Button {
            Task { await viewModel.micTapped() }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: viewModel.phase == .listening ? "waveform" : "mic.fill")
                    .font(.system(size: 64))
                Text(micCaption)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: 320, minHeight: 180)
        }
        .buttonStyle(.borderedProminent)
        .tint(viewModel.phase == .listening ? .red : .accentColor)
        // 子供の番のときだけ押せる。アプリが話している間に押しても、自分の声を拾わないようにするため
        .disabled(viewModel.phase != .waitingForChild)
        .accessibilityLabel(micCaption)
    }

    private var micCaption: String {
        switch viewModel.phase {
        case .listening: "きいてるよ…"
        case .waitingForChild: "おして はなしてね"
        default: "ちょっと まってね"
        }
    }

    /// 聞き取った言葉と「ちがうよ」。聞き間違いを、子供にも横にいる親にも分かるようにする
    private var heardRow: some View {
        HStack(spacing: 12) {
            if let heard = viewModel.heardReading {
                Text("きこえた: 「\(heard)」")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            } else if viewModel.lastVerdict == .unreadable {
                Text("きこえなかったよ")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
            }
            if viewModel.canUndo {
                Button("ちがうよ") { viewModel.undoTapped() }
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .buttonStyle(.bordered)
                    .accessibilityLabel("ちがうよ。いいなおす")
            }
        }
        .frame(minHeight: 48)
    }
}

#Preview {
    PlayView(viewModel: .preview())
}
