import SwiftUI

struct OtherUserProfileView: View {
    @EnvironmentObject var dataManager: DataManager
    let user: User
    @State private var showCreateChallenge = false

    private var record: UserRecord {
        dataManager.record(for: user.id)
    }

    private var headToHead: (wins: Int, losses: Int, disputed: Int) {
        guard let currentUserID = dataManager.currentUser?.id else { return (0, 0, 0) }
        let matches = dataManager.challenges(between: currentUserID, and: user.id)
            .filter { $0.status == .completed || $0.status == .disputed }

        var wins = 0
        var losses = 0
        var disputed = 0

        for match in matches {
            if match.isDisputed {
                disputed += 1
            } else if match.winnerID == currentUserID {
                wins += 1
            } else if match.winnerID != nil {
                losses += 1
            }
        }

        return (wins, losses, disputed)
    }

    private var sharedHistory: [Challenge] {
        guard let currentUserID = dataManager.currentUser?.id else { return [] }
        return dataManager.challenges(between: currentUserID, and: user.id)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 12) {
                    Text(user.avatarEmoji)
                        .font(.system(size: 64))

                    Text(user.displayName)
                        .font(.title.weight(.bold))

                    Text("@\(user.username)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(user.email)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Their overall record
                    HStack(spacing: 20) {
                        StatBubble(value: "\(record.wins)", label: "Wins", color: .green)
                        StatBubble(value: "\(record.losses)", label: "Losses", color: .red)
                        StatBubble(value: "\(record.disputed)", label: "Disputed", color: .orange)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // Challenge button
                Button {
                    showCreateChallenge = true
                } label: {
                    Label("Challenge \(user.displayName)", systemImage: "bolt.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .fontWeight(.semibold)
                }

                // Head to Head
                let h2h = headToHead
                if h2h.wins + h2h.losses + h2h.disputed > 0 {
                    VStack(spacing: 12) {
                        Text("Your Head-to-Head")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 0) {
                            let total = h2h.wins + h2h.losses + h2h.disputed
                            if h2h.wins > 0 {
                                Rectangle()
                                    .fill(.green)
                                    .frame(width: barWidth(count: h2h.wins, total: total))
                            }
                            if h2h.losses > 0 {
                                Rectangle()
                                    .fill(.red)
                                    .frame(width: barWidth(count: h2h.losses, total: total))
                            }
                            if h2h.disputed > 0 {
                                Rectangle()
                                    .fill(.orange)
                                    .frame(width: barWidth(count: h2h.disputed, total: total))
                            }
                        }
                        .frame(height: 12)
                        .clipShape(Capsule())

                        HStack {
                            Label("\(h2h.wins) Wins", systemImage: "trophy.fill")
                                .foregroundStyle(.green)
                            Spacer()
                            Label("\(h2h.losses) Losses", systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            if h2h.disputed > 0 {
                                Spacer()
                                Label("\(h2h.disputed) Disputed", systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                        .font(.caption.weight(.semibold))
                    }
                    .padding(16)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Shared battle history
                if !sharedHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Battle History")
                            .font(.headline)

                        ForEach(sharedHistory) { challenge in
                            NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                                HistoryRow(challenge: challenge)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Friend management
                if (dataManager.currentUser?.friendIDs ?? []).contains(user.id) {
                    Button(role: .destructive) {
                        dataManager.removeFriend(user.id)
                    } label: {
                        Label("Remove Friend", systemImage: "person.badge.minus")
                            .font(.subheadline)
                    }
                    .padding(.top, 8)
                } else {
                    Button {
                        dataManager.addFriend(user.id)
                    } label: {
                        Label("Add Friend", systemImage: "person.badge.plus")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue.gradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(user.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCreateChallenge) {
            CreateChallengeView()
        }
    }

    private func barWidth(count: Int, total: Int) -> CGFloat {
        guard total > 0 else { return 0 }
        let maxWidth: CGFloat = UIScreen.main.bounds.width - 64
        return maxWidth * CGFloat(count) / CGFloat(total)
    }
}

#Preview {
    let dm = DataManager()
    let friend = dm.allUsers[1]
    return NavigationStack {
        OtherUserProfileView(user: friend)
    }
    .environmentObject(dm)
}
