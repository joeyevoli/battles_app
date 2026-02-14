import Foundation
import SwiftUI

class DataManager: ObservableObject {
    @Published var currentUser: User
    @Published var allUsers: [User]
    @Published var challenges: [Challenge]

    private let usersKey = "battles_users"
    private let challengesKey = "battles_challenges"
    private let currentUserKey = "battles_current_user_id"

    init() {
        // Initialize with defaults first, then load
        self.currentUser = User(username: "you", displayName: "You", avatarEmoji: "⚔️")
        self.allUsers = []
        self.challenges = []

        loadData()

        if allUsers.isEmpty {
            seedDemoData()
        }
    }

    // MARK: - Persistence

    private func loadData() {
        if let usersData = UserDefaults.standard.data(forKey: usersKey),
           let decoded = try? JSONDecoder().decode([User].self, from: usersData) {
            self.allUsers = decoded
        }

        if let challengesData = UserDefaults.standard.data(forKey: challengesKey),
           let decoded = try? JSONDecoder().decode([Challenge].self, from: challengesData) {
            self.challenges = decoded
        }

        if let currentIDString = UserDefaults.standard.string(forKey: currentUserKey),
           let currentID = UUID(uuidString: currentIDString),
           let user = allUsers.first(where: { $0.id == currentID }) {
            self.currentUser = user
        }
    }

    private func save() {
        if let usersData = try? JSONEncoder().encode(allUsers) {
            UserDefaults.standard.set(usersData, forKey: usersKey)
        }
        if let challengesData = try? JSONEncoder().encode(challenges) {
            UserDefaults.standard.set(challengesData, forKey: challengesKey)
        }
        UserDefaults.standard.set(currentUser.id.uuidString, forKey: currentUserKey)
    }

    // MARK: - Demo Data

    private func seedDemoData() {
        let you = User(username: "you", displayName: "You", avatarEmoji: "⚔️")
        let alice = User(username: "alice", displayName: "Alice", avatarEmoji: "🏆")
        let bob = User(username: "bob", displayName: "Bob", avatarEmoji: "🎯")
        let charlie = User(username: "charlie", displayName: "Charlie", avatarEmoji: "🔥")
        let dana = User(username: "dana", displayName: "Dana", avatarEmoji: "💪")
        let evan = User(username: "evan", displayName: "Evan", avatarEmoji: "🎮")

        var mutableYou = you
        mutableYou.friendIDs = [alice.id, bob.id, charlie.id, dana.id]

        var mutableAlice = alice
        mutableAlice.friendIDs = [you.id, bob.id]

        var mutableBob = bob
        mutableBob.friendIDs = [you.id, alice.id, charlie.id]

        var mutableCharlie = charlie
        mutableCharlie.friendIDs = [you.id, bob.id]

        var mutableDana = dana
        mutableDana.friendIDs = [you.id]

        self.currentUser = mutableYou
        self.allUsers = [mutableYou, mutableAlice, mutableBob, mutableCharlie, mutableDana, evan]

        // Seed some challenges in various states
        let c1 = Challenge(
            challengerID: mutableYou.id,
            challengedID: alice.id,
            title: "1v1 Basketball",
            description: "First to 21 points, win by 2. At the park courts Saturday afternoon.",
            category: "Sports",
            status: .completed,
            createdDate: Date().addingTimeInterval(-86400 * 7),
            acceptedDate: Date().addingTimeInterval(-86400 * 6),
            completedDate: Date().addingTimeInterval(-86400 * 5),
            challengerResultClaim: .iWon,
            challengedResultClaim: .theyWon,
            winnerID: mutableYou.id,
            isDisputed: false
        )

        let c2 = Challenge(
            challengerID: bob.id,
            challengedID: mutableYou.id,
            title: "Chess Match",
            description: "Best of 3 games, 15 minute time control each.",
            category: "Board Games",
            status: .completed,
            createdDate: Date().addingTimeInterval(-86400 * 10),
            acceptedDate: Date().addingTimeInterval(-86400 * 9),
            completedDate: Date().addingTimeInterval(-86400 * 8),
            challengerResultClaim: .iWon,
            challengedResultClaim: .iWon,
            winnerID: nil,
            isDisputed: true
        )

        let c3 = Challenge(
            challengerID: charlie.id,
            challengedID: mutableYou.id,
            title: "Hot Dog Eating Contest",
            description: "Most hot dogs in 10 minutes. Loser buys lunch next week.",
            category: "Food",
            status: .pending,
            createdDate: Date().addingTimeInterval(-3600)
        )

        let c4 = Challenge(
            challengerID: mutableYou.id,
            challengedID: dana.id,
            title: "5K Race",
            description: "Run the lakefront trail. Best time wins.",
            category: "Fitness",
            status: .accepted,
            createdDate: Date().addingTimeInterval(-86400 * 2),
            acceptedDate: Date().addingTimeInterval(-86400)
        )

        let c5 = Challenge(
            challengerID: mutableYou.id,
            challengedID: bob.id,
            title: "Mario Kart Tournament",
            description: "Best of 5 races on Rainbow Road. No items allowed.",
            category: "Gaming",
            status: .awaitingResults,
            createdDate: Date().addingTimeInterval(-86400 * 3),
            acceptedDate: Date().addingTimeInterval(-86400 * 2),
            challengerResultClaim: .iWon,
            challengedResultClaim: .notReported
        )

        let c6 = Challenge(
            challengerID: alice.id,
            challengedID: bob.id,
            title: "Karaoke Battle",
            description: "Audience votes on the best performance at Friday night karaoke.",
            category: "Music",
            status: .completed,
            createdDate: Date().addingTimeInterval(-86400 * 14),
            acceptedDate: Date().addingTimeInterval(-86400 * 13),
            completedDate: Date().addingTimeInterval(-86400 * 12),
            challengerResultClaim: .theyWon,
            challengedResultClaim: .iWon,
            winnerID: bob.id,
            isDisputed: false
        )

        self.challenges = [c1, c2, c3, c4, c5, c6]
        save()
    }

    // MARK: - User Queries

    func user(for id: UUID) -> User? {
        allUsers.first(where: { $0.id == id })
    }

    func friends(of user: User) -> [User] {
        user.friendIDs.compactMap { friendID in
            allUsers.first(where: { $0.id == friendID })
        }
    }

    func nonFriends(of user: User) -> [User] {
        allUsers.filter { otherUser in
            otherUser.id != user.id && !user.friendIDs.contains(otherUser.id)
        }
    }

    // MARK: - Record Calculation

    func record(for userID: UUID) -> UserRecord {
        let userChallenges = challenges.filter {
            ($0.challengerID == userID || $0.challengedID == userID) &&
            ($0.status == .completed || $0.status == .disputed)
        }

        var wins = 0
        var losses = 0
        var disputed = 0

        for challenge in userChallenges {
            if challenge.isDisputed {
                disputed += 1
            } else if challenge.winnerID == userID {
                wins += 1
            } else if challenge.winnerID != nil {
                losses += 1
            }
        }

        let pending = challenges.filter {
            ($0.challengerID == userID || $0.challengedID == userID) &&
            ($0.status == .pending || $0.status == .accepted || $0.status == .inProgress || $0.status == .awaitingResults)
        }.count

        return UserRecord(wins: wins, losses: losses, disputed: disputed, pending: pending)
    }

    // MARK: - Challenge Queries

    func challengesForCurrentUser() -> [Challenge] {
        challenges.filter {
            $0.challengerID == currentUser.id || $0.challengedID == currentUser.id
        }
        .sorted { $0.createdDate > $1.createdDate }
    }

    func pendingChallengesForCurrentUser() -> [Challenge] {
        challengesForCurrentUser().filter {
            $0.status == .pending && $0.challengedID == currentUser.id
        }
    }

    func activeChallengesForCurrentUser() -> [Challenge] {
        challengesForCurrentUser().filter {
            $0.status == .accepted || $0.status == .inProgress || $0.status == .awaitingResults
        }
    }

    func completedChallengesForCurrentUser() -> [Challenge] {
        challengesForCurrentUser().filter {
            $0.status == .completed || $0.status == .disputed
        }
    }

    func challenges(between userA: UUID, and userB: UUID) -> [Challenge] {
        challenges.filter {
            ($0.challengerID == userA && $0.challengedID == userB) ||
            ($0.challengerID == userB && $0.challengedID == userA)
        }
        .sorted { $0.createdDate > $1.createdDate }
    }

    // MARK: - Challenge Actions

    func createChallenge(challengedID: UUID, title: String, description: String, category: String) {
        let challenge = Challenge(
            challengerID: currentUser.id,
            challengedID: challengedID,
            title: title,
            description: description,
            category: category
        )
        challenges.append(challenge)
        save()
    }

    func acceptChallenge(_ challengeID: UUID) {
        guard let index = challenges.firstIndex(where: { $0.id == challengeID }) else { return }
        challenges[index].status = .accepted
        challenges[index].acceptedDate = Date()
        save()
    }

    func declineChallenge(_ challengeID: UUID) {
        guard let index = challenges.firstIndex(where: { $0.id == challengeID }) else { return }
        challenges[index].status = .declined
        save()
    }

    func markInProgress(_ challengeID: UUID) {
        guard let index = challenges.firstIndex(where: { $0.id == challengeID }) else { return }
        challenges[index].status = .inProgress
        save()
    }

    func reportResult(challengeID: UUID, claim: ResultClaim) {
        guard let index = challenges.firstIndex(where: { $0.id == challengeID }) else { return }

        let isChallenger = challenges[index].challengerID == currentUser.id

        if isChallenger {
            challenges[index].challengerResultClaim = claim
        } else {
            challenges[index].challengedResultClaim = claim
        }

        challenges[index].status = .awaitingResults

        // Check if both have reported
        let c = challenges[index]
        if c.challengerResultClaim != .notReported && c.challengedResultClaim != .notReported {
            challenges[index].completedDate = Date()

            if c.isResultAgreed {
                challenges[index].status = .completed
                challenges[index].winnerID = c.agreedWinnerID
                challenges[index].isDisputed = false
            } else {
                challenges[index].status = .disputed
                challenges[index].isDisputed = true
                challenges[index].winnerID = nil
            }
        }

        save()
    }

    // MARK: - Friend Actions

    func addFriend(_ friendID: UUID) {
        guard !currentUser.friendIDs.contains(friendID) else { return }
        currentUser.friendIDs.append(friendID)

        if let index = allUsers.firstIndex(where: { $0.id == currentUser.id }) {
            allUsers[index] = currentUser
        }

        // Mutual friendship
        if let friendIndex = allUsers.firstIndex(where: { $0.id == friendID }) {
            if !allUsers[friendIndex].friendIDs.contains(currentUser.id) {
                allUsers[friendIndex].friendIDs.append(currentUser.id)
            }
        }

        save()
    }

    func removeFriend(_ friendID: UUID) {
        currentUser.friendIDs.removeAll { $0 == friendID }

        if let index = allUsers.firstIndex(where: { $0.id == currentUser.id }) {
            allUsers[index] = currentUser
        }

        if let friendIndex = allUsers.firstIndex(where: { $0.id == friendID }) {
            allUsers[friendIndex].friendIDs.removeAll { $0 == currentUser.id }
        }

        save()
    }

    func opponent(in challenge: Challenge) -> User? {
        let opponentID = challenge.challengerID == currentUser.id
            ? challenge.challengedID
            : challenge.challengerID
        return user(for: opponentID)
    }
}
