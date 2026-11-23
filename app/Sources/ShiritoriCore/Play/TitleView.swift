import SwiftUI

/// タイトル。ボタンは「はじめる」1つだけ（登録や設定を挟まず、すぐ遊べるように）。
struct TitleView: View {
    let viewModel: PlayViewModel

    var body: some View {
        VStack(spacing: 48) {
            Text("おんせい しりとり")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)

            Button {
                Task { await viewModel.startTapped() }
            } label: {
                Text("はじめる")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .frame(maxWidth: 320, minHeight: 96)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("はじめる")
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    TitleView(viewModel: .preview())
}
