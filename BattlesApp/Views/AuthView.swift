import SwiftUI

struct AuthView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var isCreatingAccount = false
    @State private var email = ""
    @State private var username = ""
    @State private var displayName = ""
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)

                    // Logo / Branding
                    VStack(spacing: 12) {
                        Image(systemName: "bolt.circle.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(.orange.gradient)

                        Text("Battles")
                            .font(.largeTitle.weight(.black))

                        Text("Challenge anyone. Compete in anything.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Form
                    VStack(spacing: 16) {
                        if isCreatingAccount {
                            createAccountForm
                        } else {
                            signInForm
                        }
                    }
                    .padding(.horizontal, 24)

                    // Toggle between sign in / create account
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isCreatingAccount.toggle()
                            errorMessage = ""
                            showError = false
                        }
                    } label: {
                        if isCreatingAccount {
                            Text("Already have an account? **Sign In**")
                                .font(.subheadline)
                        } else {
                            Text("Don't have an account? **Create One**")
                                .font(.subheadline)
                        }
                    }
                    .foregroundStyle(.secondary)

                    Spacer(minLength: 20)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private var signInForm: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Email")
                    .font(.subheadline.weight(.medium))
                TextField("Enter your email address", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(12)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if showError {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                attemptSignIn()
            } label: {
                Text("Sign In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(email.isEmpty ? Color.gray.gradient : Color.orange.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .fontWeight(.semibold)
            }
            .disabled(email.isEmpty)
        }
    }

    private var createAccountForm: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Email")
                    .font(.subheadline.weight(.medium))
                TextField("you@example.com", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(12)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Username")
                    .font(.subheadline.weight(.medium))
                TextField("Choose a username", text: $username)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(12)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Display Name")
                    .font(.subheadline.weight(.medium))
                TextField("How others will see you", text: $displayName)
                    .textContentType(.name)
                    .padding(12)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if showError {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                attemptCreateAccount()
            } label: {
                Text("Create Account")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canCreateAccount ? Color.orange.gradient : Color.gray.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .fontWeight(.semibold)
            }
            .disabled(!canCreateAccount)
        }
    }

    private var canCreateAccount: Bool {
        !email.isEmpty && !username.isEmpty && !displayName.isEmpty && email.contains("@")
    }

    private func attemptSignIn() {
        if dataManager.signIn(email: email) {
            errorMessage = ""
            showError = false
        } else {
            errorMessage = "No account found with that email. Create one below!"
            showError = true
        }
    }

    private func attemptCreateAccount() {
        guard email.contains("@") else {
            errorMessage = "Please enter a valid email address."
            showError = true
            return
        }

        if dataManager.isEmailTaken(email) {
            errorMessage = "An account with this email already exists. Try signing in."
            showError = true
            return
        }

        if dataManager.isUsernameTaken(username) {
            errorMessage = "This username is already taken. Try another one."
            showError = true
            return
        }

        if dataManager.createAccount(email: email, username: username, displayName: displayName) {
            errorMessage = ""
            showError = false
        } else {
            errorMessage = "Could not create account. Please try again."
            showError = true
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(DataManager())
}
