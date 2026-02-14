import SwiftUI

struct CreateChallengeView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: ChallengeCategory = ChallengeCategory.allCategories[0]
    @State private var selectedFriend: User?
    @State private var showFriendPicker = false

    var body: some View {
        NavigationStack {
            Form {
                // Opponent Section
                Section {
                    if let friend = selectedFriend {
                        HStack {
                            Text(friend.avatarEmoji)
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text(friend.displayName)
                                    .font(.subheadline.weight(.semibold))
                                Text("@\(friend.username)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Change") {
                                showFriendPicker = true
                            }
                            .font(.subheadline)
                        }
                    } else {
                        Button {
                            showFriendPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                    .foregroundStyle(.blue)
                                Text("Choose Opponent")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Challenge Who?")
                }

                // Category Section
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(ChallengeCategory.allCategories) { category in
                                CategoryChip(
                                    category: category,
                                    isSelected: selectedCategory.name == category.name
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Category")
                }

                // Details Section
                Section {
                    TextField("e.g. 1v1 Basketball", text: $title)

                    TextField("Describe the rules and stakes...", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Challenge Details")
                } footer: {
                    Text("Be specific about the rules so there's no argument later!")
                }

                // Preview Section
                if selectedFriend != nil && !title.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: selectedCategory.icon)
                                    .foregroundStyle(.orange)
                                Text(title)
                                    .font(.headline)
                            }
                            if !description.isEmpty {
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Text("You")
                                Image(systemName: "bolt.fill")
                                    .foregroundStyle(.orange)
                                Text("vs")
                                Image(systemName: "bolt.fill")
                                    .foregroundStyle(.orange)
                                Text(selectedFriend?.displayName ?? "")
                            }
                            .font(.subheadline.weight(.semibold))
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Preview")
                    }
                }
            }
            .navigationTitle("New Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        sendChallenge()
                    }
                    .disabled(selectedFriend == nil || title.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showFriendPicker) {
                FriendPickerView(selectedFriend: $selectedFriend)
            }
        }
    }

    private func sendChallenge() {
        guard let friend = selectedFriend else { return }
        dataManager.createChallenge(
            challengedID: friend.id,
            title: title,
            description: description,
            category: selectedCategory.name
        )
        dismiss()
    }
}

struct CategoryChip: View {
    let category: ChallengeCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.name)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.orange : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

struct FriendPickerView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFriend: User?
    @State private var searchText = ""

    var filteredFriends: [User] {
        let friends = dataManager.friends(of: dataManager.currentUser)
        if searchText.isEmpty {
            return friends
        }
        return friends.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredFriends) { friend in
                Button {
                    selectedFriend = friend
                    dismiss()
                } label: {
                    HStack {
                        Text(friend.avatarEmoji)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text(friend.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("@\(friend.username)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        let record = dataManager.record(for: friend.id)
                        Text("\(record.wins)W - \(record.losses)L")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search friends...")
            .navigationTitle("Pick Opponent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if filteredFriends.isEmpty {
                    ContentUnavailableView(
                        "No Friends Found",
                        systemImage: "person.slash",
                        description: Text("Add friends from the Friends tab to challenge them!")
                    )
                }
            }
        }
    }
}

#Preview {
    CreateChallengeView()
        .environmentObject(DataManager())
}
