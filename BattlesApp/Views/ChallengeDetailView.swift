import SwiftUI

struct ChallengeDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @State var challenge: Challenge
    @State private var showReportResult = false

    private var challenger: User? {
        dataManager.user(for: challenge.challengerID)
    }

    private var challenged: User? {
        dataManager.user(for: challenge.challengedID)
    }

    private var isInvitedChallenge: Bool {
        challenge.challengedEmail != nil && challenged == nil
    }

    private var isChallenger: Bool {
        challenge.challengerID == dataManager.currentUser?.id
    }

    private var isChallenged: Bool {
        challenge.challengedID == dataManager.currentUser?.id
    }

    private var currentUserClaim: ResultClaim {
        isChallenger ? challenge.challengerResultClaim : challenge.challengedResultClaim
    }

    private var opponentClaim: ResultClaim {
        isChallenger ? challenge.challengedResultClaim : challenge.challengerResultClaim
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerCard

                // Status
                statusCard

                // Result claims (if any)
                if challenge.challengerResultClaim != .notReported ||
                   challenge.challengedResultClaim != .notReported {
                    resultClaimsCard
                }

                // Actions
                actionsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Battle Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showReportResult) {
            ReportResultView(challenge: $challenge)
        }
        .onAppear {
            refreshChallenge()
        }
    }

    private var headerCard: some View {
        VStack(spacing: 16) {
            // Category badge
            let cat = ChallengeCategory.allCategories.first(where: { $0.name == challenge.category })
            HStack {
                Image(systemName: cat?.icon ?? "star.fill")
                Text(challenge.category)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.orange)

            // Title
            Text(challenge.title)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)

            // VS Display
            HStack(spacing: 20) {
                VStack {
                    Text(challenger?.avatarEmoji ?? "?")
                        .font(.system(size: 40))
                    Text(challenger?.displayName ?? "Unknown")
                        .font(.caption.weight(.semibold))
                    if isChallenger {
                        Text("(You)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack {
                    Text("VS")
                        .font(.title3.weight(.black))
                        .foregroundStyle(.orange)
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.orange)
                }

                VStack {
                    if isInvitedChallenge {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.blue)
                        Text(challenge.challengedEmail ?? "Invited")
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("(Invited)")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    } else {
                        Text(challenged?.avatarEmoji ?? "?")
                            .font(.system(size: 40))
                        Text(challenged?.displayName ?? "Unknown")
                            .font(.caption.weight(.semibold))
                        if isChallenged {
                            Text("(You)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Description
            if !challenge.description.isEmpty {
                Text(challenge.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }

            // Date
            Text("Created \(challenge.createdDate.formatted(.relative(presentation: .named)))")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var statusCard: some View {
        HStack {
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundStyle(statusColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.headline)
                Text(statusSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(statusColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var resultClaimsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Result Claims")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenger?.displayName ?? "Challenger")
                        .font(.subheadline.weight(.semibold))
                    resultClaimBadge(claim: challenge.challengerResultClaim, isChallenger: true)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(challenged?.displayName ?? "Challenged")
                        .font(.subheadline.weight(.semibold))
                    resultClaimBadge(claim: challenge.challengedResultClaim, isChallenger: false)
                }
            }

            if challenge.isDisputed {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Both players claim to have won. This battle is disputed!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if challenge.status == .completed, let winnerID = challenge.winnerID {
                let winnerName = dataManager.user(for: winnerID)?.displayName ?? "Unknown"
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                    Text("\(winnerName) wins! Both players agree on the result.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func resultClaimBadge(claim: ResultClaim, isChallenger: Bool) -> some View {
        switch claim {
        case .iWon:
            Label("Claims Win", systemImage: "trophy.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .theyWon:
            Label("Concedes", systemImage: "hand.thumbsup.fill")
                .font(.caption)
                .foregroundStyle(.blue)
        case .notReported:
            Label("Pending", systemImage: "clock.fill")
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }

    @ViewBuilder
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Pending challenge: Accept/Decline
            if challenge.status == .pending && isChallenged {
                Button {
                    dataManager.acceptChallenge(challenge.id)
                    refreshChallenge()
                } label: {
                    Label("Accept Challenge", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .fontWeight(.semibold)
                }

                Button {
                    dataManager.declineChallenge(challenge.id)
                    refreshChallenge()
                } label: {
                    Label("Decline", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .fontWeight(.semibold)
                }
            }

            // Accepted: Mark as in progress
            if challenge.status == .accepted {
                Button {
                    dataManager.markInProgress(challenge.id)
                    refreshChallenge()
                } label: {
                    Label("Start Battle", systemImage: "flame.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .fontWeight(.semibold)
                }
            }

            // In progress or awaiting results: Report result
            if (challenge.status == .inProgress || challenge.status == .awaitingResults) &&
               currentUserClaim == .notReported {
                Button {
                    showReportResult = true
                } label: {
                    Label("Report Result", systemImage: "flag.checkered")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .fontWeight(.semibold)
                }
            }

            // Waiting for opponent to report
            if challenge.status == .awaitingResults && currentUserClaim != .notReported && opponentClaim == .notReported {
                HStack {
                    ProgressView()
                    Text("Waiting for opponent to report their result...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
    }

    private var statusIcon: String {
        if isInvitedChallenge && challenge.status == .pending {
            return "envelope.fill"
        }
        switch challenge.status {
        case .pending: return "hourglass"
        case .accepted: return "handshake.fill"
        case .declined: return "xmark.octagon.fill"
        case .inProgress: return "flame.fill"
        case .awaitingResults: return "clock.badge.questionmark.fill"
        case .completed: return "trophy.fill"
        case .disputed: return "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        if isInvitedChallenge && challenge.status == .pending {
            return .blue
        }
        switch challenge.status {
        case .pending: return .orange
        case .accepted: return .blue
        case .declined: return .gray
        case .inProgress: return .purple
        case .awaitingResults: return .yellow
        case .completed: return .green
        case .disputed: return .red
        }
    }

    private var statusTitle: String {
        if isInvitedChallenge && challenge.status == .pending {
            return "Invitation Sent"
        }
        switch challenge.status {
        case .pending:
            return isChallenged ? "You've Been Challenged!" : "Challenge Sent"
        case .accepted:
            return "Challenge Accepted"
        case .declined:
            return "Challenge Declined"
        case .inProgress:
            return "Battle In Progress"
        case .awaitingResults:
            return "Awaiting Results"
        case .completed:
            if challenge.winnerID == dataManager.currentUser?.id {
                return "You Won!"
            } else {
                return "You Lost"
            }
        case .disputed:
            return "Result Disputed"
        }
    }

    private var statusSubtitle: String {
        if isInvitedChallenge && challenge.status == .pending {
            return "Waiting for \(challenge.challengedEmail ?? "them") to create an account"
        }
        switch challenge.status {
        case .pending:
            return isChallenged ? "Accept or decline this challenge" : "Waiting for response..."
        case .accepted:
            return "Time to battle! Tap Start when ready."
        case .declined:
            return "This challenge was declined."
        case .inProgress:
            return "Go compete! Report the result when done."
        case .awaitingResults:
            return "Waiting for both players to report."
        case .completed:
            return "Both players agreed on the outcome."
        case .disputed:
            return "Players couldn't agree on who won."
        }
    }

    private func refreshChallenge() {
        if let updated = dataManager.challenges.first(where: { $0.id == challenge.id }) {
            challenge = updated
        }
    }
}

#Preview {
    let dm = DataManager()
    let challenge = dm.challenges.first!
    return NavigationStack {
        ChallengeDetailView(challenge: challenge)
    }
    .environmentObject(dm)
}
