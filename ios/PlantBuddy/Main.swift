import SwiftUI

struct MainView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isCheckingAuth = true

    var body: some View {
        Group {
            if isCheckingAuth {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBackground)
                    .onAppear {
                        // Small delay to ensure AuthManager is initialized
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isCheckingAuth = false
                        }
                    }
            } else if authManager.isAuthenticated {
                ContentView()
                    .background(Color.appBackground.ignoresSafeArea())
            } else {
                AuthView()
                    .background(Color.appBackground.ignoresSafeArea())
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}

#Preview {
    MainView().environmentObject(AuthManager())
}
