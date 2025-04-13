import SwiftUI

// MARK: - Accent Colors
enum AccentColor: String, CaseIterable {
    case blue = "5E5CE6"
    case green = "34C759"
    case orange = "FF9500"
    case pink = "FF2D55"
    case purple = "AF52DE"
    case red = "FF3B30"
    case yellow = "FFCC00"
    
    var name: String {
        switch self {
        case .blue: return "Blue"
        case .green: return "Green"
        case .orange: return "Orange"
        case .pink: return "Pink"
        case .purple: return "Purple"
        case .red: return "Red"
        case .yellow: return "Yellow"
        }
    }
    
    var color: Color {
        Color.hex(self.rawValue)
    }
}

// MARK: - Shared Components
struct TagChip: View {
    let tag: String
    let onDelete: () -> Void
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    
    var body: some View {
        HStack(spacing: 8) {
            Text(tag)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.hex(accentColor))
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color.hex(accentColor))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.hex(accentColor).opacity(0.1))
        .cornerRadius(8)
    }
}

struct SharedEmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    let tintColor: Color
    
    init(
        systemImage: String = "checkmark.circle.fill",
        title: String = "All caught up!",
        message: String = "Come back later for more cards",
        tintColor: Color = Color.hex("34C759")
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
                    .foregroundColor(Color.hex("8E8E93"))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - View Extensions


// MARK: - Color Extensions
extension Color {
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
