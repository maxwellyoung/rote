import SwiftUI

// MARK: - Shared Components
struct SharedEmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    let tintColor: Color
    
    init(
        systemImage: String = "checkmark.circle.fill",
        title: String = "All caught up!",
        message: String = "Come back later for more cards",
        tintColor: Color = .accentColor
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.tintColor = tintColor
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: systemImage)
                .font(.system(size: 64))
                .foregroundColor(tintColor)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Extensions
extension Color {
    enum Theme {
        // Background colors
        static let background = Color.hex("111111")
        static let secondaryBackground = Color.hex("1C1C1E")
        static let tertiaryBackground = Color.hex("2C2C2E")
        
        // Text colors
        static let primaryText = Color.white
        static let secondaryText = Color.hex("8E8E93")
        
        // Accent colors
        static let accent = Color.hex("7C7AE6")  // More muted purple
        static let success = Color.hex("4EA67A")  // Muted green
        static let warning = Color.hex("B5873D")  // Muted orange
        static let error = Color.hex("B55B5B")    // Muted red
        
        // Card colors
        static let cardBackground = Color.hex("1C1C1E")
        static let cardBorder = Color.hex("2C2C2E")
        
        // Rating colors
        static let againRating = Color.hex("B55B5B")  // Muted red
        static let goodRating = Color.hex("4EA67A")   // Muted green
        static let easyRating = Color.hex("5B8AB5")   // Muted blue
        
        // Tag colors
        static let tagBackground = Color.hex("7C7AE6").opacity(0.15)
        static let tagText = Color.hex("7C7AE6")
    }
    
    static func hex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 