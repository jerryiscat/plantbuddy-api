import SwiftUI

struct SignUpSuccessView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var navigateToMain = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
            
            // Success Message
            Text("You Successfully Signed Up!")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("Welcome to PlantBuddy! 🌱")
                .font(.title2)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Spacer()
            
            // Explore Button
            Button(action: {
                navigateToMain = true
            }) {
                Text("Explore")
                    .font(.headline)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.plantBuddyMediumGreen)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
        .fullScreenCover(isPresented: $navigateToMain) {
            ContentView().environmentObject(authManager)
        }
    }
}

#Preview {
    SignUpSuccessView().environmentObject(AuthManager())
}

