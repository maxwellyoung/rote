import SwiftUI

enum Theme {
    enum Colors {
        static let accent = Color.hex("5E5CE6")
        static let background = Color.hex("1A1A1A")
        static let backgroundDarker = Color.hex("0A0A0A")
        static let cardBackground = Color.hex("1C1C1E")
        static let cardBorder = Color.hex("2C2C2E")
        static let secondaryText = Color.hex("8E8E93")
    }
    
    static func applyTheme() {
        // Set the accent color for the whole app
        UITabBar.appearance().unselectedItemTintColor = UIColor(Theme.Colors.secondaryText)
        UITabBar.appearance().tintColor = UIColor(Theme.Colors.accent)
        
        // Set navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(Theme.Colors.background)
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = UIColor(Theme.Colors.accent)
    }
} 