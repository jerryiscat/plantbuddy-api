import SwiftUI

struct AuthView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showPassword = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSignUpSuccess = false
    @State private var showForgotPassword = false
    @State private var forgotPasswordEmail = ""
    @State private var showForgotPasswordAlert = false
    @State private var forgotPasswordMessage = ""
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        if showSignUpSuccess {
            SignUpSuccessView().environmentObject(authManager)
        } else if authManager.isAuthenticated {
            ContentView()
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, 40)
                    
                    // Username Field
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .padding(.horizontal)
                    
                    // Email Field (only for sign up)
                    if isSignUp {
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .padding(.horizontal)
                    }
                    
                    // Password Field with Eye Icon
                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                        } else {
                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                        }
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Error Message
                    if showError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Sign In/Up Button
                    Button(action: {
                        if isSignUp {
                            signUp()
                        } else {
                            signIn()
                        }
                    }) {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.plantBuddyMediumGreen)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Forgot Password Link (only for sign in)
                    if !isSignUp {
                        Button(action: {
                            showForgotPassword = true
                        }) {
                            Text("Forgot Password?")
                                .foregroundColor(Color.plantBuddyMediumGreen)
                                .font(.subheadline)
                        }
                        .padding(.top, 5)
                    }
                    
                    // Toggle Sign In/Up
                    Button(action: {
                        isSignUp.toggle()
                        showError = false
                        errorMessage = ""
                        username = ""
                        email = ""
                        password = ""
                    }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .foregroundColor(Color.plantBuddyDarkerGreen)
                            .font(.subheadline)
                    }
                    .padding(.top, 10)
                }
                .padding(.vertical, 20)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView(
                    email: $forgotPasswordEmail,
                    isPresented: $showForgotPassword,
                    onSuccess: { message in
                        forgotPasswordMessage = message
                        showForgotPasswordAlert = true
                    }
                )
            }
            .alert("Password Reset", isPresented: $showForgotPasswordAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(forgotPasswordMessage)
            }
        }
    }
    
    private func signUp() {
        // Validate password
        if password.count < 8 {
            showError = true
            errorMessage = "Password must be at least 8 characters long."
            return
        }
        
        // Basic email validation
        if !email.contains("@") || !email.contains(".") {
            showError = true
            errorMessage = "Please enter a valid email address."
            return
        }
        
        showError = false
        authManager.signUp(username: username, email: email, password: password) { success, error in
            if success {
                showSignUpSuccess = true
            } else {
                showError = true
                errorMessage = error ?? "Sign up failed. Please try again."
            }
        }
    }
    
    private func signIn() {
        showError = false
        authManager.signIn(username: username, password: password) { success, error in
            if success {
                showError = false
            } else {
                showError = true
                errorMessage = error ?? "Invalid username or password. Please try again."
            }
        }
    }
}

// Forgot Password View
struct ForgotPasswordView: View {
    @Binding var email: String
    @Binding var isPresented: Bool
    let onSuccess: (String) -> Void
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Reset Password")
                    .font(.title)
                    .bold()
                    .padding(.top, 20)
                
                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal)
                
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    resetPassword()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Send Reset Link")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Color.plantBuddyMediumGreen)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(isLoading || email.isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func resetPassword() {
        guard !email.isEmpty else {
            showError = true
            errorMessage = "Please enter your email address."
            return
        }
        
        guard email.contains("@") && email.contains(".") else {
            showError = true
            errorMessage = "Please enter a valid email address."
            return
        }
        
        isLoading = true
        showError = false
        
        authManager.requestPasswordReset(email: email) { success, message in
            isLoading = false
            if success {
                onSuccess(message ?? "Password reset link sent to your email.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isPresented = false
                }
            } else {
                showError = true
                errorMessage = message ?? "Failed to send reset email. Please try again."
            }
        }
    }
}

#Preview {
    AuthView().environmentObject(AuthManager())
}
