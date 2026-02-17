import SwiftUI

struct CreateChallengeView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: ChallengeCategory = ChallengeCategory.allCategories[0]
    @State private var selectedOpponent: User?
    @State private var inviteEmail: String?
    @State private var showFriendPicker = false
    @State private var opponentSearchText = ""
    @State private var lookupErrorMessage = ""
    @State private var showLookupError = false
    @State private var showInviteOption = false
    @State private var showInviteSentAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // Opponent Section
                Section {
                    if let opponent = selectedOpponent {
                        HStack {
                            Text(opponent.avatarEmoji)
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text(opponent.displayName)
                                    .font(.subheadline.weight(.semibold))
                                Text("@\(opponent.username)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(opponent.email)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Button("Change") {
                                selectedOpponent = nil
                                opponentSearchText = ""
                                lookupErrorMessage = ""
                                showLookupError = false
                                showInviteOption = false
                            }
                            .font(.subheadline)
                        }
                    } else if let email = inviteEmail {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text(email)
                                    .font(.subheadline.weight(.semibold))
                                Text("Not on Battles yet - will receive an invite")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Change") {
                                inviteEmail = nil
                                opponentSearchText = ""
                                lookupErrorMessage = ""
                                showLookupError = false
                                showInviteOption = false
                            }
                            .font(.subheadline)
                        }
                    } else {
                        // Email / username lookup
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                TextField("Enter email or username", text: $opponentSearchText)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)

                                Button {
                                    lookupOpponent()
                                } label: {
                                    Text("Find")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(opponentSearchText.isEmpty ? Color.gray : Color.orange)
                                        .clipShape(Capsule())
                                }
                                .disabled(opponentSearchText.isEmpty)
                            }

                            if showLookupError {
                                Text(lookupErrorMessage)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }

                            if showInviteOption {
                                Button {
                                    inviteEmail = opponentSearchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                                    showLookupError = false
                                    showInviteOption = false
                                } label: {
                                    HStack {
                                        Image(systemName: "envelope.badge.person.crop")
                                            .foregroundStyle(.blue)
                                        Text("Invite them & create challenge")
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Image(systemName: "arrow.right.circle.fill")
                                            .foregroundStyle(.blue)
                                    }
                                    .padding(10)
                                    .background(.blue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }

                        // Divider with "or"
                        HStack {
                            Rectangle()
                                .fill(Color(.separator))
                                .frame(height: 1)
                            Text("or")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Rectangle()
                                .fill(Color(.separator))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 4)

                        // Pick from friends
                        Button {
                            showFriendPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundStyle(.blue)
                                Text("Choose from Friends")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Challenge Who?")
                } footer: {
                    if selectedOpponent == nil && inviteEmail == nil {
                        Text("Enter their email address or username to find them, or pick from your friends list.")
                    }
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
                if (selectedOpponent != nil || inviteEmail != nil) && !title.isEmpty {
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
                                Text(dataManager.currentUser?.displayName ?? "You")
                                Image(systemName: "bolt.fill")
                                    .foregroundStyle(.orange)
                                Text("vs")
                                Image(systemName: "bolt.fill")
                                    .foregroundStyle(.orange)
                                Text(selectedOpponent?.displayName ?? inviteEmail ?? "")
                            }
                            .font(.subheadline.weight(.semibold))

                            if inviteEmail != nil {
                                HStack(spacing: 4) {
                                    Image(systemName: "envelope.fill")
                                        .font(.caption2)
                                    Text("An invite email will be sent")
                                        .font(.caption)
                                }
                                .foregroundStyle(.blue)
                            }
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
                    Button(inviteEmail != nil ? "Send & Invite" : "Send") {
                        sendChallenge()
                    }
                    .disabled((selectedOpponent == nil && inviteEmail == nil) || title.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showFriendPicker) {
                FriendPickerView(selectedFriend: $selectedOpponent)
            }
            .alert("Invitation Sent!", isPresented: $showInviteSentAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("We've sent an email to \(inviteEmail ?? "them") inviting them to join Battles. Your challenge will be waiting for them when they create their account!")
            }
        }
    }

    private func lookupOpponent() {
        showLookupError = false
        showInviteOption = false
        let query = opponentSearchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else { return }

        if let found = dataManager.findUser(byEmailOrUsername: query) {
            if found.id == dataManager.currentUser?.id {
                lookupErrorMessage = "You can't challenge yourself!"
                showLookupError = true
            } else {
                selectedOpponent = found
                showLookupError = false
            }
        } else {
            if query.contains("@") && query.contains(".") {
                lookupErrorMessage = "No account found for \"\(query)\"."
                showLookupError = true
                showInviteOption = true
            } else {
                lookupErrorMessage = "No user found with \"\(query)\". Try their email address to send an invite."
                showLookupError = true
            }
        }
    }

    private func sendChallenge() {
        if let opponent = selectedOpponent {
            dataManager.createChallenge(
                challengedID: opponent.id,
                title: title,
                description: description,
                category: selectedCategory.name
            )
            dismiss()
        } else if let email = inviteEmail {
            dataManager.createChallengeByEmail(
                challengedEmail: email,
                title: title,
                description: description,
                category: selectedCategory.name
            )
            showInviteSentAlert = true
        }
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
        guard let currentUser = dataManager.currentUser else { return [] }
        let friends = dataManager.friends(of: currentUser)
        if searchText.isEmpty {
            return friends
        }
        return friends.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText)
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
