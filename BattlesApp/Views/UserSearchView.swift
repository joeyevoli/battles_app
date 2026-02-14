import SwiftUI

struct UserSearchView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var availableUsers: [User] {
        let nonFriends = dataManager.nonFriends(of: dataManager.currentUser)
        if searchText.isEmpty {
            return nonFriends
        }
        return nonFriends.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if availableUsers.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ForEach(availableUsers) { user in
                        HStack(spacing: 12) {
                            Text(user.avatarEmoji)
                                .font(.title)
                                .frame(width: 44, height: 44)
                                .background(Color(.systemGray5))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.displayName)
                                    .font(.subheadline.weight(.semibold))
                                Text("@\(user.username)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                dataManager.addFriend(user.id)
                            } label: {
                                if dataManager.currentUser.friendIDs.contains(user.id) {
                                    Label("Added", systemImage: "checkmark")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.green)
                                } else {
                                    Label("Add", systemImage: "plus")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(.blue.gradient)
                                        .clipShape(Capsule())
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search by name or username...")
            .navigationTitle("Find Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    UserSearchView()
        .environmentObject(DataManager())
}
