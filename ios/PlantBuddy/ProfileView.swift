import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isEditingUsername = false
    @State private var isEditingEmail = false
    @State private var updatedUsername = ""
    @State private var updatedEmail = ""
    @State private var notificationsEnabled = true
    @State private var wateringReminderTime = Date()
    @State private var showExportAlert = false
    
    // Mock stats
    @State private var plantsAlive = 5
    @State private var daysStreak = 100
    
    @State private var showAlert = false
    @State private var alertMessage = ""

    // Add a helper for the colors, assuming the extension is in your project
    private let primaryGreen = Color.plantBuddyMediumGreen
    private let darkGreen = Color.plantBuddyDarkerGreen

    var body: some View {
        // Use NavigationStack for modern SwiftUI, assuming iOS 16+
        NavigationStack {
            // Replaced ScrollView with List for a settings-like appearance
            List {
                // --- 1. Green Thumb Stats Section ---
                VStack(spacing: 15) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.system(size: 50))
                        .foregroundColor(primaryGreen)
                      
                    Text("Green Thumb Stats")
                        .font(.title2)
                        .bold()
                        .foregroundColor(darkGreen)
                      
                    Text("You have kept \(plantsAlive) plants alive for \(daysStreak) days!")
                        .font(.headline)
                        .foregroundColor(darkGreen)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.plantBuddyLightGreen.opacity(0.4))
                .cornerRadius(12)
                .listRowBackground(Color.appBackground) // Match background color
                .listRowSeparator(.hidden) // Remove the list separator for this custom block
                
                // --- 2. User Profile Section ---
                if let userProfile = authManager.userProfile {
                    Section("Profile") {
                        // Username Row
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.black)
                                .font(.title2)

                            VStack(alignment: .leading) {
                                Text("Username")
                                    .font(.headline)
                                    .foregroundColor(.black)

                                if isEditingUsername {
                                    TextField("Enter new username", text: $updatedUsername)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .foregroundColor(darkGreen)
                                } else {
                                    Text(userProfile.username)
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                }
                            }
                            Spacer()

                            Button(action: {
                                if isEditingUsername {
                                    updateUsername()
                                }
                                isEditingUsername.toggle()
                                // Disable other editing when one is active
                                if isEditingUsername { isEditingEmail = false }
                            }) {
                                Image(systemName: isEditingUsername ? "checkmark.circle.fill" : "pencil.circle")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(.black)
                            }
                        }

                        // Email Row
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.black)
                                .font(.title2)

                            VStack(alignment: .leading) {
                                Text("Email")
                                    .font(.headline)
                                    .foregroundColor(.black)

                                if isEditingEmail {
                                    TextField("Enter new email", text: $updatedEmail)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .foregroundColor(darkGreen)
                                } else {
                                    Text(userProfile.email)
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                }
                            }
                            Spacer()

                            Button(action: {
                                if isEditingEmail {
                                    updateEmail()
                                }
                                isEditingEmail.toggle()
                                // Disable other editing when one is active
                                if isEditingEmail { isEditingUsername = false }
                            }) {
                                Image(systemName: isEditingEmail ? "checkmark.circle.fill" : "pencil.circle")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(.black)
                            }
                        }
                    } // End Section Profile
                    .listRowBackground(Color.plantBuddyCream) // Set custom row background
                }
                
                // --- 3. Preferences & Notifications Section ---
                Section("Settings") {
                    // Notifications Toggle
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Push Notifications", systemImage: "bell.fill").foregroundColor(.black)
                    }
                    .tint(primaryGreen) // Set the toggle color

                    // Watering Reminder Time
                    DatePicker(selection: $wateringReminderTime, displayedComponents: .hourAndMinute) {
                        Label("Reminder Time", systemImage: "clock.fill").foregroundColor(.black)
                    }
                } // End Section Settings
                .listRowBackground(Color.plantBuddyCream)
                
                // --- 4. Data Management ---
                Section {
                    // Export Data Button
                    Button(action: {
                        exportData()
                    }) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                            .foregroundColor(.black)
                    }
                }
                .listRowBackground(Color.plantBuddyCream)

            } // End List
            .background(Color.appBackground.ignoresSafeArea())
            .scrollContentBackground(.hidden) // Hide default list background (needed for custom List background)
            .navigationTitle("Profile")
            .toolbar {
                // Sign Out Button in Toolbar (Common pattern for profile screens)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out", role: .destructive) {
                        authManager.signOut()
                    }
                    .foregroundColor(.red) // Explicitly set color for clarity
                }
            }
            .onAppear {
                if let userProfile = authManager.userProfile {
                    // Initialize state variables on appear
                    updatedUsername = userProfile.username
                    updatedEmail = userProfile.email
                } else {
                    authManager.fetchUserProfile()
                }
            }
            // Alerts remain the same
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Update Failed"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .alert("Data Exported", isPresented: $showExportAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your plant data has been exported successfully!")
            }
        } // End NavigationStack
    }

    func updateUsername() {
        let originalUsername = authManager.userProfile?.username ?? ""
        guard !updatedUsername.isEmpty, updatedUsername != originalUsername else {
            updatedUsername = originalUsername
            return
        }

        authManager.updateUserProfile(username: updatedUsername, email: nil) { success, errorMessage in
            if !success {
                alertMessage = errorMessage ?? "Failed to update username."
                showAlert = true
                updatedUsername = originalUsername
            }
        }
    }

    func updateEmail() {
        let originalEmail = authManager.userProfile?.email ?? ""
        guard !updatedEmail.isEmpty, updatedEmail != originalEmail else {
            updatedEmail = originalEmail
            return
        }

        authManager.updateUserProfile(username: nil, email: updatedEmail) { success, errorMessage in
            if !success {
                alertMessage = errorMessage ?? "Failed to update email."
                showAlert = true
                updatedEmail = originalEmail
            }
        }
    }
    
    func exportData() {
        // TODO: Implement actual data export
        // For now, just show success message
        showExportAlert = true
    }
}

#Preview {
    ProfileView().environmentObject(AuthManager())
}
