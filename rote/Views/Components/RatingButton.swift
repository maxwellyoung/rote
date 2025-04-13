import SwiftUI

struct RatingButton: View {
    let rating: Card.Grade
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: rating.icon)
                .font(.system(size: 24))
            
            Text(rating.rawValue)
                .font(.system(size: 13, weight: .medium))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .foregroundColor(rating.color)
        .background(rating.color.opacity(0.1))
        .cornerRadius(10)
    }
} 