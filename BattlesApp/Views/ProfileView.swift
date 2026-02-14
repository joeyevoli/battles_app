import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var dataManager: DataManager

    private var record: UserRecord {
        dataManager.record(for: dataManager.currentUser.id)
    }

    private var completedChallenges: [Challenge] {
        dataManager.completedChallengesForCurrentUser()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader

                    // Stats Grid
                    statsGrid

                    // Battle History
                    battleHistory

                    // Head-to-Head Records
                    headToHeadSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Text(dataManager.currentUser.avatarEmoji)
                .font(.system(size: 64))

            Text(dataManager.currentUser.displayName)
                .font(.title.weight(.bold))

            Text("@\(dataManager.currentUser.username)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Joined \(dataManager.currentUser.joinDate.formatted(.dateTime.month().year()))")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var statsGrid: some View {
        VStack(spacing: 12) {
            Text("Overall Record")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                StatCard(
                    title: "Wins",
                    value: "\(record.wins)",
                    icon: "trophy.fill",
                    color: .green
                )
                StatCard(
                    title: "Losses",
                    value: "\(record.losses)",
                    icon: "xmark.circle.fill",
                    color: .red
                )
                StatCard(
                    title: "Disputed",
                    value: "\(record.disputed)",
                    icon: "exclamationmark.triangle.fill",
                    color: .orange
                )
                StatCard(
                    title: "Win Rate",
                    value: String(format: "%.0f%%", record.winPercentage),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )
            }

            HStack {
                Label("\(record.totalCompleted) completed", systemImage: "checkmark.circle")
                Spacer()
                Label("\(record.pending) active", systemImage: "flame")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
        }
    }

    private var battleHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Battle History")
                .font(.headline)

            if completedChallenges.isEmpty {
                Text("No completed battles yet. Challenge someone!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(completedChallenges) { challenge in
                    NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                        HistoryRow(challenge: challenge)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var headToHeadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Head-to-Head")
                .font(.headline)

            let friends = dataManager.friends(of: dataManager.currentUser)
            if friends.isEmpty {
                Text("Add friends to see head-to-head records.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(friends) { friend in
                    let h2h = headToHead(against: friend.id)
                    if h2h.total > 0 {
                        NavigationLink(destination: OtherUserProfileView(user: friend)) {
                            HeadToHeadRow(opponent: friend, wins: h2h.wins, losses: h2h.losses, disputed: h2h.disputed)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func headToHead(against opponentID: UUID) -> (wins: Int, losses: Int, disputed: Int, total: Int) {
        let matches = dataManager.challenges(between: dataManager.currentUser.id, and: opponentID)
            .filter { $0.status == .completed || $0.status == .disputed }

        var wins = 0
        var losses = 0
        var disputed = 0

        for match in matches {
            if match.isDisputed {
                disputed += 1
            } else if match.winnerID == dataManager.currentUser.id {
                wins += 1
            } else if match.winnerID != nil {
                losses += 1
            }
        }

        return (wins, losses, disputed, matches.count)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct HistoryRow: View {
    let challenge: Challenge
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        HStack(spacing: 12) {
            // Result icon
            if challenge.isDisputed {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .frame(width: 32)
            } else if challenge.winnerID == dataManager.currentUser.id {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.green)
                    .frame(width: 32)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .frame(width: 32)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(challenge.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                if let opponent = dataManager.opponent(in: challenge) {
                    Text("vs \(opponent.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let date = challenge.completedDate {
                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct HeadToHeadRow: View {
    let opponent: User
    let wins: Int
    let losses: Int
    let disputed: Int

    var body: some View {
        HStack(spacing: 12) {
            Text(opponent.avatarEmoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(opponent.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("\(wins + losses + disputed) battles")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Text("\(wins)W")
                    .foregroundStyle(.green)
                Text("\(losses)L")
                    .foregroundStyle(.red)
                if disputed > 0 {
                    Text("\(disputed)D")
                        .foregroundStyle(.orange)
                }
            }
            .font(.caption.weight(.semibold))

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ProfileView()
        .environmentObject(DataManager())
}
