import Foundation
import SwiftUI

class DataManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isSignedIn: Bool = false
    @Published var allUsers: [User]
    @Published var challenges: [Challenge]
    @Published var pendingChallengeCountOnSignup: Int = 0

    private let usersKey = "battles_users"
    private let challengesKey = "battles_challenges"
    private let currentUserKey = "battles_current_user_id"

    init() {
        self.allUsers = []
        self.challenges = []

        loadData()

        if let currentIDString = UserDefaults.standard.string(forKey: currentUserKey),
           let currentID = UUID(uuidString: currentIDString),
           let user = allUsers.first(where: { $0.id == currentID }) {
            self.currentUser = user
            self.isSignedIn = true
        }

        if allUsers.isEmpty {
            seedDemoData()
        }
    }

    // MARK: - Auth

    func signIn(email: String) -> Bool {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard let user = allUsers.first(where: { $0.email.lowercased() == normalizedEmail }) else {
            return false
        }
        currentUser = user
        isSignedIn = true
        UserDefaults.standard.set(user.id.uuidString, forKey: currentUserKey)
        return true
    }

    func createAccount(email: String, username: String, displayName: String) -> Bool {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedUsername = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if email or username already taken
        if allUsers.contains(where: { $0.email.lowercased() == normalizedEmail }) {
            return false
        }
        if allUsers.contains(where: { $0.username.lowercased() == normalizedUsername }) {
            return false
        }

        let newUser = User(
            email: normalizedEmail,
            username: normalizedUsername,
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        allUsers.append(newUser)

        // Link any pending invited challenges to this new account
        let linkedCount = linkPendingChallenges(for: newUser)
        if linkedCount > 0 {
            pendingChallengeCountOnSignup = linkedCount
        }

        currentUser = newUser
        isSignedIn = true
        save()
        return true
    }

    func signOut() {
        currentUser = nil
        isSignedIn = false
        UserDefaults.standard.removeObject(forKey: currentUserKey)
    }

    func isEmailTaken(_ email: String) -> Bool {
        let normalized = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return allUsers.contains(where: { $0.email.lowercased() == normalized })
    }

    func isUsernameTaken(_ username: String) -> Bool {
        let normalized = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return allUsers.contains(where: { $0.username.lowercased() == normalized })
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
    }

    private func save() {
        if let usersData = try? JSONEncoder().encode(allUsers) {
            UserDefaults.standard.set(usersData, forKey: usersKey)
        }
        if let challengesData = try? JSONEncoder().encode(challenges) {
            UserDefaults.standard.set(challengesData, forKey: challengesKey)
        }
        if let currentUser = currentUser {
            UserDefaults.standard.set(currentUser.id.uuidString, forKey: currentUserKey)
        }
    }

    // MARK: - Demo Data

    private func seedDemoData() {
        let alice = User(email: "alice@example.com", username: "alice", displayName: "Alice", avatarEmoji: "🏆")
        let bob = User(email: "bob@example.com", username: "bob", displayName: "Bob", avatarEmoji: "🎯")
        let charlie = User(email: "charlie@example.com", username: "charlie", displayName: "Charlie", avatarEmoji: "🔥")
        let dana = User(email: "dana@example.com", username: "dana", displayName: "Dana", avatarEmoji: "💪")
        let evan = User(email: "evan@example.com", username: "evan", displayName: "Evan", avatarEmoji: "🎮")

        var mutableAlice = alice
        mutableAlice.friendIDs = [bob.id]

        var mutableBob = bob
        mutableBob.friendIDs = [alice.id, charlie.id]

        var mutableCharlie = charlie
        mutableCharlie.friendIDs = [bob.id]

        self.allUsers = [mutableAlice, mutableBob, mutableCharlie, dana, evan]

        // Seed some challenges between demo users
        let c1 = Challenge(
            challengerID: alice.id,
            challengedID: bob.id,
            title: "1v1 Basketball",
            description: "First to 21 points, win by 2. At the park courts Saturday afternoon.",
            category: "Sports",
            status: .completed,
            createdDate: Date().addingTimeInterval(-86400 * 7),
            acceptedDate: Date().addingTimeInterval(-86400 * 6),
            completedDate: Date().addingTimeInterval(-86400 * 5),
            challengerResultClaim: .iWon,
            challengedResultClaim: .theyWon,
            winnerID: alice.id,
            isDisputed: false
        )

        let c2 = Challenge(
            challengerID: bob.id,
            challengedID: charlie.id,
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

        self.challenges = [c1, c2, c3]
        save()
    }

    // MARK: - User Queries

    func user(for id: UUID) -> User? {
        allUsers.first(where: { $0.id == id })
    }

    func findUser(byEmailOrUsername query: String) -> User? {
        let normalized = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return allUsers.first(where: {
            $0.email.lowercased() == normalized || $0.username.lowercased() == normalized
        })
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
        guard let currentUser = currentUser else { return [] }
        return challenges.filter {
            $0.challengerID == currentUser.id || $0.challengedID == currentUser.id
        }
        .sorted { $0.createdDate > $1.createdDate }
    }

    func pendingChallengesForCurrentUser() -> [Challenge] {
        guard let currentUser = currentUser else { return [] }
        return challengesForCurrentUser().filter {
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
        guard let currentUser = currentUser else { return }
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

    func createChallengeByEmail(challengedEmail: String, title: String, description: String, category: String) {
        guard let currentUser = currentUser else { return }
        let normalizedEmail = challengedEmail.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let placeholderID = UUID()
        let challenge = Challenge(
            challengerID: currentUser.id,
            challengedID: placeholderID,
            challengedEmail: normalizedEmail,
            title: title,
            description: description,
            category: category
        )
        challenges.append(challenge)
        save()
        sendInvitationEmail(to: normalizedEmail, challengerName: currentUser.displayName, challengeTitle: title)
    }

    @discardableResult
    private func linkPendingChallenges(for user: User) -> Int {
        let normalizedEmail = user.email.lowercased()
        var count = 0
        for index in challenges.indices {
            if let email = challenges[index].challengedEmail,
               email.lowercased() == normalizedEmail,
               challenges[index].status == .pending {
                challenges[index].challengedID = user.id
                count += 1
            }
        }
        return count
    }

    private func sendInvitationEmail(to email: String, challengerName: String, challengeTitle: String) {
        // In a production app, this would call a backend API to send a real email.
        // For now, we log the simulated email send.
        print("[Battles] Invitation email sent to \(email): \(challengerName) challenged you to \"\(challengeTitle)\"! Create an account to accept.")
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
        guard let currentUser = currentUser else { return }
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
        guard var currentUser = currentUser else { return }
        guard !currentUser.friendIDs.contains(friendID) else { return }
        currentUser.friendIDs.append(friendID)
        self.currentUser = currentUser

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
        guard var currentUser = currentUser else { return }
        currentUser.friendIDs.removeAll { $0 == friendID }
        self.currentUser = currentUser

        if let index = allUsers.firstIndex(where: { $0.id == currentUser.id }) {
            allUsers[index] = currentUser
        }

        if let friendIndex = allUsers.firstIndex(where: { $0.id == friendID }) {
            allUsers[friendIndex].friendIDs.removeAll { $0 == currentUser.id }
        }

        save()
    }

    func opponent(in challenge: Challenge) -> User? {
        guard let currentUser = currentUser else { return nil }
        let opponentID = challenge.challengerID == currentUser.id
            ? challenge.challengedID
            : challenge.challengerID
        return user(for: opponentID)
    }
}
