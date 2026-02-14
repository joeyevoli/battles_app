import SwiftUI

@main
struct BattlesAppApp: App {
    @StateObject private var dataManager = DataManager()

    var body: some Scene {
        WindowGroup {
            if dataManager.isSignedIn {
                ContentView()
                    .environmentObject(dataManager)
            } else {
                AuthView()
                    .environmentObject(dataManager)
            }
        }
    }
}
