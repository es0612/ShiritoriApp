import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// マイクや音声認識が使えないときの画面。文字入力の代わりは v1 では用意しない。
struct UnavailableView: View {
    let viewModel: PlayViewModel
    let availability: ListeningAvailability

    var body: some View {
        VStack(spacing: 28) {
            Text(message)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            if availability == .denied {
                #if canImport(UIKit)
                Button("せっていを ひらく") { openSettings() }
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("せっていを ひらく")
                #endif

                // 設定で許可してアプリに戻ったあと、ここからやり直せる
                Button("もういちど ためす") {
                    Task { await viewModel.startTapped() }
                }
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .buttonStyle(.bordered)
                .accessibilityLabel("もういちど ためす")
            }

            Button("もどる") { viewModel.backToTitleTapped() }
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .accessibilityLabel("もどる")
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var message: String {
        switch availability {
        case .denied: "せっていで マイクと おんせいにんしきを ゆるしてね"
        case .unsupported: "この たんまつでは あそべません"
        case .ready: ""
        }
    }

    #if canImport(UIKit)
    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    #endif
}

#Preview("きょか なし") {
    UnavailableView(viewModel: .preview(), availability: .denied)
}

#Preview("ひたいおう") {
    UnavailableView(viewModel: .preview(), availability: .unsupported)
}
