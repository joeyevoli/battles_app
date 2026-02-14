import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: UUID
    var email: String
    var username: String
    var displayName: String
    var avatarEmoji: String
    var friendIDs: [UUID]
    var joinDate: Date

    init(
        id: UUID = UUID(),
        email: String,
        username: String,
        displayName: String,
        avatarEmoji: String = "⚔️",
        friendIDs: [UUID] = [],
        joinDate: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.username = username
        self.displayName = displayName
        self.avatarEmoji = avatarEmoji
        self.friendIDs = friendIDs
        self.joinDate = joinDate
    }
}

struct UserRecord: Equatable {
    let wins: Int
    let losses: Int
    let disputed: Int
    let pending: Int

    var totalCompleted: Int { wins + losses + disputed }

    var winPercentage: Double {
        guard totalCompleted > 0 else { return 0 }
        return Double(wins) / Double(totalCompleted) * 100
    }
}
