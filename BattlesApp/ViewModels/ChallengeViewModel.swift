import Foundation
import SwiftUI

class ChallengeViewModel: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var showCreateChallenge = false

    enum Tab: Int {
        case home = 0
        case battles = 1
        case friends = 2
        case profile = 3
    }

    func navigateToTab(_ tab: Tab) {
        selectedTab = tab.rawValue
    }
}
