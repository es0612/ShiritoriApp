import ShiritoriCore
import SwiftUI

/// 起動だけを受け持つ。画面と状態はすべて ShiritoriCore パッケージ側にある。
@main
struct ShiritoriAppApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
