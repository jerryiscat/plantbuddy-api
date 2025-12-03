import SwiftUI
import UIKit

// Color Extension - PlantBuddy Color Palette
extension Color {
    static let appBackground = Color(hex: "F1F3E0")  // Light cream/beige
    static let plantBuddyLightGreen = Color(hex: "D2DCB6")  // Light green
    static let plantBuddyMediumGreen = Color(hex: "A1BC98")  // Medium green
    static let plantBuddyDarkGreen = Color(hex: "778873")  // Dark green
    static let plantBuddyDarkerGreen = Color(hex: "626F47")  // Darker green
    static let plantBuddyYellowGreen = Color(hex: "A4B465")  // Yellow-green
    static let plantBuddyCream = Color(hex: "F5ECD5")  // Cream
    static let plantBuddyOrange = Color(hex: "F0BB78")  // Orange
    static let waterBlue = Color(hex: "AEDEFC")  // Water blue
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

@main
struct PlantBuddyApp: App {
    @StateObject var authManager = AuthManager()
    
    init() {
        // Set navigation bar title color to dark green
        let navAppearance = UINavigationBarAppearance()
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.plantBuddyDarkerGreen)]
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(Color.plantBuddyDarkerGreen)]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        // Configure global tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Color.plantBuddyDarkGreen) // Dark green 043915

        // Unselected state: white icons, dark green labels
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.plantBuddyDarkGreen)
        ]
        tabAppearance.stackedLayoutAppearance.normal.iconColor = .white
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttrs

        // Selected state: A4B465 icons, dark green labels
        let selectedAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.plantBuddyDarkGreen)
        ]
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.plantBuddyYellowGreen)
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttrs

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(authManager)
                .preferredColorScheme(.light)   // Force light mode, disable system dark/light switching
        }
    }
}
