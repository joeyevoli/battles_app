import SwiftUI

struct ReportResultView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @Binding var challenge: Challenge

    @State private var selectedClaim: ResultClaim?

    private var opponent: User? {
        dataManager.opponent(in: challenge)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Header
                VStack(spacing: 8) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)

                    Text("Report Result")
                        .font(.title2.weight(.bold))

                    Text("How did \"\(challenge.title)\" go?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Options
                VStack(spacing: 16) {
                    ResultOptionButton(
                        title: "I Won",
                        subtitle: "I beat \(opponent?.displayName ?? "my opponent")",
                        icon: "trophy.fill",
                        color: .green,
                        isSelected: selectedClaim == .iWon
                    ) {
                        selectedClaim = .iWon
                    }

                    ResultOptionButton(
                        title: "They Won",
                        subtitle: "\(opponent?.displayName ?? "My opponent") beat me",
                        icon: "hand.thumbsup.fill",
                        color: .blue,
                        isSelected: selectedClaim == .theyWon
                    ) {
                        selectedClaim = .theyWon
                    }
                }
                .padding(.horizontal)

                // Info
                VStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Both players must report the result. If you disagree, the battle will be marked as disputed on both records.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer()

                // Submit
                Button {
                    submitResult()
                } label: {
                    Text("Submit Result")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedClaim != nil ? Color.orange.gradient : Color.gray.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .fontWeight(.semibold)
                }
                .disabled(selectedClaim == nil)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func submitResult() {
        guard let claim = selectedClaim else { return }
        dataManager.reportResult(challengeID: challenge.id, claim: claim)
        if let updated = dataManager.challenges.first(where: { $0.id == challenge.id }) {
            challenge = updated
        }
        dismiss()
    }
}

struct ResultOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? color : .gray)
            }
            .padding(16)
            .background(isSelected ? color.opacity(0.1) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? color : .clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    let dm = DataManager()
    @State var challenge = dm.challenges.first!
    return ReportResultView(challenge: $challenge)
        .environmentObject(dm)
}
