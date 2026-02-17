import Foundation

enum ChallengeStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case accepted = "Accepted"
    case declined = "Declined"
    case inProgress = "In Progress"
    case awaitingResults = "Awaiting Results"
    case completed = "Completed"
    case disputed = "Disputed"

    var color: String {
        switch self {
        case .pending: return "orange"
        case .accepted: return "blue"
        case .declined: return "gray"
        case .inProgress: return "purple"
        case .awaitingResults: return "yellow"
        case .completed: return "green"
        case .disputed: return "red"
        }
    }
}

enum ResultClaim: String, Codable {
    case iWon = "I Won"
    case theyWon = "They Won"
    case notReported = "Not Reported"
}

struct Challenge: Identifiable, Codable {
    let id: UUID
    let challengerID: UUID
    var challengedID: UUID
    var challengedEmail: String?
    var title: String
    var description: String
    var category: String
    var status: ChallengeStatus
    var createdDate: Date
    var acceptedDate: Date?
    var completedDate: Date?

    var challengerResultClaim: ResultClaim
    var challengedResultClaim: ResultClaim

    var winnerID: UUID?
    var isDisputed: Bool

    init(
        id: UUID = UUID(),
        challengerID: UUID,
        challengedID: UUID,
        challengedEmail: String? = nil,
        title: String,
        description: String,
        category: String = "General",
        status: ChallengeStatus = .pending,
        createdDate: Date = Date(),
        acceptedDate: Date? = nil,
        completedDate: Date? = nil,
        challengerResultClaim: ResultClaim = .notReported,
        challengedResultClaim: ResultClaim = .notReported,
        winnerID: UUID? = nil,
        isDisputed: Bool = false
    ) {
        self.id = id
        self.challengerID = challengerID
        self.challengedID = challengedID
        self.challengedEmail = challengedEmail
        self.title = title
        self.description = description
        self.category = category
        self.status = status
        self.createdDate = createdDate
        self.acceptedDate = acceptedDate
        self.completedDate = completedDate
        self.challengerResultClaim = challengerResultClaim
        self.challengedResultClaim = challengedResultClaim
        self.winnerID = winnerID
        self.isDisputed = isDisputed
    }

    var isResultAgreed: Bool {
        guard challengerResultClaim != .notReported,
              challengedResultClaim != .notReported else {
            return false
        }

        let challengerSaysChallenger = challengerResultClaim == .iWon
        let challengedSaysChallenger = challengedResultClaim == .theyWon

        let challengerSaysChallenged = challengerResultClaim == .theyWon
        let challengedSaysChallenged = challengedResultClaim == .iWon

        return (challengerSaysChallenger && challengedSaysChallenger) ||
               (challengerSaysChallenged && challengedSaysChallenged)
    }

    var agreedWinnerID: UUID? {
        guard isResultAgreed else { return nil }

        if challengerResultClaim == .iWon {
            return challengerID
        } else {
            return challengedID
        }
    }
}

struct ChallengeCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String

    static let allCategories: [ChallengeCategory] = [
        ChallengeCategory(name: "Sports", icon: "sportscourt.fill"),
        ChallengeCategory(name: "Fitness", icon: "figure.run"),
        ChallengeCategory(name: "Gaming", icon: "gamecontroller.fill"),
        ChallengeCategory(name: "Trivia", icon: "brain.head.profile"),
        ChallengeCategory(name: "Food", icon: "fork.knife"),
        ChallengeCategory(name: "Music", icon: "music.note"),
        ChallengeCategory(name: "Art", icon: "paintbrush.fill"),
        ChallengeCategory(name: "Outdoor", icon: "leaf.fill"),
        ChallengeCategory(name: "Card Games", icon: "suit.spade.fill"),
        ChallengeCategory(name: "Board Games", icon: "dice.fill"),
        ChallengeCategory(name: "Custom", icon: "star.fill"),
    ]
}
