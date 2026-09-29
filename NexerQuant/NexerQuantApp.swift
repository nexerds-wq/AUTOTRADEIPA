import SwiftUI

@main
struct NexerQuantApp: App {
    @StateObject private var store = TradingStore()
    var body: some Scene {
        WindowGroup { RootView().environmentObject(store) }
    }
}
