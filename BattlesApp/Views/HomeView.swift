import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showCreateChallenge = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Record Card
                    recordCard

                    // Pending Challenges (incoming)
                    if !dataManager.pendingChallengesForCurrentUser().isEmpty {
                        incomingChallengesSection
                    }

                    // Active Challenges
                    if !dataManager.activeChallengesForCurrentUser().isEmpty {
                        activeChallengesSection
                    }

                    // Recent Results
                    if !dataManager.completedChallengesForCurrentUser().isEmpty {
                        recentResultsSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Battles")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateChallenge = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showCreateChallenge) {
                CreateChallengeView()
            }
        }
    }

    private var recordCard: some View {
        let record = dataManager.record(for: dataManager.currentUser.id)
        return VStack(spacing: 16) {
            Text(dataManager.currentUser.avatarEmoji)
                .font(.system(size: 48))

            Text("Your Record")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 32) {
                StatBubble(value: "\(record.wins)", label: "Wins", color: .green)
                StatBubble(value: "\(record.losses)", label: "Losses", color: .red)
                StatBubble(value: "\(record.disputed)", label: "Disputed", color: .orange)
            }

            if record.totalCompleted > 0 {
                Text(String(format: "%.0f%% win rate", record.winPercentage))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if record.pending > 0 {
                Text("\(record.pending) active battle\(record.pending == 1 ? "" : "s")")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var incomingChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(.orange)
                Text("Incoming Challenges")
                    .font(.headline)
            }

            ForEach(dataManager.pendingChallengesForCurrentUser()) { challenge in
                NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                    ChallengeRow(challenge: challenge)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var activeChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.blue)
                Text("Active Battles")
                    .font(.headline)
            }

            ForEach(dataManager.activeChallengesForCurrentUser()) { challenge in
                NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                    ChallengeRow(challenge: challenge)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recentResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("Recent Results")
                    .font(.headline)
            }

            ForEach(dataManager.completedChallengesForCurrentUser().prefix(5)) { challenge in
                NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                    ChallengeRow(challenge: challenge)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct StatBubble: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct ChallengeRow: View {
    let challenge: Challenge
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            categoryIcon

            VStack(alignment: .leading, spacing: 4) {
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

            statusBadge
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var categoryIcon: some View {
        let cat = ChallengeCategory.allCategories.first(where: { $0.name == challenge.category })
        let icon = cat?.icon ?? "star.fill"
        return Image(systemName: icon)
            .font(.title3)
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background(categoryColor.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var categoryColor: Color {
        switch challenge.category {
        case "Sports": return .blue
        case "Fitness": return .green
        case "Gaming": return .purple
        case "Trivia": return .cyan
        case "Food": return .orange
        case "Music": return .pink
        case "Art": return .indigo
        case "Outdoor": return .mint
        case "Card Games": return .red
        case "Board Games": return .brown
        default: return .gray
        }
    }

    private var statusBadge: some View {
        Group {
            switch challenge.status {
            case .completed:
                if challenge.winnerID == dataManager.currentUser.id {
                    Label("Won", systemImage: "trophy.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                } else {
                    Label("Lost", systemImage: "xmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                }
            case .disputed:
                Label("Disputed", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            case .pending:
                if challenge.challengedID == dataManager.currentUser.id {
                    Label("Respond", systemImage: "bell.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                } else {
                    Label("Sent", systemImage: "paperplane.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)
                }
            case .awaitingResults:
                Label("Report", systemImage: "clock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.yellow)
            default:
                Text(challenge.status.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(DataManager())
}
