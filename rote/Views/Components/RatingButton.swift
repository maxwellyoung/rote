import SwiftUI

struct RatingButton: View {
    let rating: Card.Grade
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: rating.icon)
                .font(.system(size: 24))
                .id("icon_\(rating.rawValue)")
            
            Text(rating.rawValue)
                .font(.system(size: 13, weight: .medium))
                .id("text_\(rating.rawValue)")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .foregroundColor(rating.color)
        .background(rating.color.opacity(0.1))
        .cornerRadius(10)
        .onAppear {
            print("\n=== RatingButton Appeared ===")
            print("Rating: \(rating.rawValue)")
            print("Icon: \(rating.icon)")
            print("Color: \(rating.color)")
            print("=== End RatingButton ===\n")
        }
    }
} 