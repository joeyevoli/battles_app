import SwiftUI

struct ChallengesListView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedFilter: ChallengeFilter = .all
    @State private var showCreateChallenge = false

    enum ChallengeFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case active = "Active"
        case completed = "Completed"
        case disputed = "Disputed"
    }

    var filteredChallenges: [Challenge] {
        let all = dataManager.challengesForCurrentUser()
        switch selectedFilter {
        case .all:
            return all
        case .pending:
            return all.filter { $0.status == .pending }
        case .active:
            return all.filter { $0.status == .accepted || $0.status == .inProgress || $0.status == .awaitingResults }
        case .completed:
            return all.filter { $0.status == .completed }
        case .disputed:
            return all.filter { $0.status == .disputed }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ChallengeFilter.allCases, id: \.self) { filter in
                            FilterPill(
                                title: filter.rawValue,
                                count: countFor(filter),
                                isSelected: selectedFilter == filter
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(Color(.systemBackground))

                // List
                if filteredChallenges.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        emptyTitle,
                        systemImage: emptyIcon,
                        description: Text(emptyDescription)
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(filteredChallenges) { challenge in
                            NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                                ChallengeRow(challenge: challenge)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Battles")
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

    private func countFor(_ filter: ChallengeFilter) -> Int {
        let all = dataManager.challengesForCurrentUser()
        switch filter {
        case .all: return all.count
        case .pending: return all.filter { $0.status == .pending }.count
        case .active: return all.filter { $0.status == .accepted || $0.status == .inProgress || $0.status == .awaitingResults }.count
        case .completed: return all.filter { $0.status == .completed }.count
        case .disputed: return all.filter { $0.status == .disputed }.count
        }
    }

    private var emptyTitle: String {
        switch selectedFilter {
        case .all: return "No Battles Yet"
        case .pending: return "No Pending Challenges"
        case .active: return "No Active Battles"
        case .completed: return "No Completed Battles"
        case .disputed: return "No Disputes"
        }
    }

    private var emptyIcon: String {
        switch selectedFilter {
        case .all: return "bolt.slash"
        case .pending: return "bell.slash"
        case .active: return "flame.slash"
        case .completed: return "trophy.slash"
        case .disputed: return "checkmark.shield"
        }
    }

    private var emptyDescription: String {
        switch selectedFilter {
        case .all: return "Challenge a friend to get started!"
        case .pending: return "No challenges waiting for a response."
        case .active: return "No battles happening right now."
        case .completed: return "Complete some battles to see them here."
        case .disputed: return "No disputed results. Good sportsmanship!"
        }
    }
}

struct FilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                if count > 0 {
                    Text("\(count)")
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? .white.opacity(0.3) : .secondary.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.orange : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    ChallengesListView()
        .environmentObject(DataManager())
}
