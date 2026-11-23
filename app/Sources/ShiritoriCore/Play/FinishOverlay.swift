import SwiftUI

/// おわりの表示。あそぶ画面の上に重ねる。
struct FinishOverlay: View {
    let viewModel: PlayViewModel

    var body: some View {
        VStack(spacing: 28) {
            Text(Phrases.finished(viewModel.chainCount))
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)

            Button {
                Task { await viewModel.startTapped() }
            } label: {
                Text("もういっかい")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .frame(maxWidth: 280, minHeight: 72)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("もういっかい")

            Button("おわる") { viewModel.backToTitleTapped() }
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .buttonStyle(.bordered)
                .accessibilityLabel("おわる")

            // TestFlight での確認用（設計書 §9 の物差し）。公開前（M3）に外す
            Text("ちがうよ \(viewModel.stats.corrections) / きこえなかった \(viewModel.stats.unheard) / いいなおし \(viewModel.stats.retries)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityLabel("ちがうよ \(viewModel.stats.corrections)かい、きこえなかった \(viewModel.stats.unheard)かい、いいなおし \(viewModel.stats.retries)かい")
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}

#if DEBUG
#Preview {
    FinishOverlay(viewModel: .preview())
}
#endif
