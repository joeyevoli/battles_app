import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showUserSearch = false
    @State private var showCreateChallenge = false
    @State private var challengeTarget: User?

    var friends: [User] {
        dataManager.friends(of: dataManager.currentUser)
    }

    var body: some View {
        NavigationStack {
            Group {
                if friends.isEmpty {
                    ContentUnavailableView(
                        "No Friends Yet",
                        systemImage: "person.2.slash",
                        description: Text("Tap the + button to find and add friends!")
                    )
                } else {
                    List {
                        ForEach(friends) { friend in
                            NavigationLink(destination: OtherUserProfileView(user: friend)) {
                                FriendRow(friend: friend) {
                                    challengeTarget = friend
                                    showCreateChallenge = true
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showUserSearch = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showUserSearch) {
                UserSearchView()
            }
            .sheet(isPresented: $showCreateChallenge) {
                CreateChallengeView()
            }
        }
    }
}

struct FriendRow: View {
    let friend: User
    let onChallenge: () -> Void
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        HStack(spacing: 12) {
            Text(friend.avatarEmoji)
                .font(.title)
                .frame(width: 44, height: 44)
                .background(Color(.systemGray5))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.displayName)
                    .font(.subheadline.weight(.semibold))
                Text("@\(friend.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                let record = dataManager.record(for: friend.id)
                Text("\(record.wins)W - \(record.losses)L - \(record.disputed)D")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button {
                onChallenge()
            } label: {
                Image(systemName: "bolt.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(.orange.gradient)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FriendsView()
        .environmentObject(DataManager())
}
