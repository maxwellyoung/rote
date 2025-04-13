import SwiftUI

struct RatingButtons: View {
    let card: Card?
    let onRating: (Card.Grade) -> Void
    
    init(card: Card?, onRating: @escaping (Card.Grade) -> Void) {
        self.card = card
        self.onRating = onRating
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: { onRating(.again) }) {
                RatingButton(rating: Card.Grade.again)
            }
            
            Button(action: { onRating(.hard) }) {
                RatingButton(rating: Card.Grade.hard)
            }
            
            Button(action: { onRating(.good) }) {
                RatingButton(rating: Card.Grade.good)
            }
            
            Button(action: { onRating(.easy) }) {
                RatingButton(rating: Card.Grade.easy)
            }
        }
        .padding(.horizontal)
    }
} 