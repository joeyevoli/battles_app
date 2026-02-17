import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showPendingChallengesAlert = false

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "flame.fill")
                }

            ChallengesListView()
                .tabItem {
                    Label("Battles", systemImage: "bolt.fill")
                }

            FriendsView()
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .tint(.orange)
        .onAppear {
            if dataManager.pendingChallengeCountOnSignup > 0 {
                showPendingChallengesAlert = true
            }
        }
        .alert("You've Been Challenged!", isPresented: $showPendingChallengesAlert) {
            Button("Let's Go!") {
                dataManager.pendingChallengeCountOnSignup = 0
            }
        } message: {
            let count = dataManager.pendingChallengeCountOnSignup
            Text("You have \(count) pending challenge\(count == 1 ? "" : "s") waiting for you! Check your incoming challenges to accept.")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager())
}
