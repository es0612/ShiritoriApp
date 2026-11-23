import SwiftUI

/// アプリの最初の画面。いまは土台だけで、あそぶ画面は M1 で足す。
public struct RootView: View {
    public init() {}

    public var body: some View {
        Text("おんせい しりとり")
            .font(.largeTitle.bold())
            .accessibilityLabel("おんせい しりとり")
    }
}

#Preview {
    RootView()
}
