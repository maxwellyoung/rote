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
            Button {
                print("\n=== Rating Button Tapped ===")
                print("Grade: Again")
                print("Card ID: \(card?.id?.uuidString ?? "nil")")
                onRating(.again)
                print("=== End Rating Button Tap ===\n")
            } label: {
                RatingButton(rating: .again)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button {
                print("\n=== Rating Button Tapped ===")
                print("Grade: Hard")
                print("Card ID: \(card?.id?.uuidString ?? "nil")")
                onRating(.hard)
                print("=== End Rating Button Tap ===\n")
            } label: {
                RatingButton(rating: .hard)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button {
                print("\n=== Rating Button Tapped ===")
                print("Grade: Good")
                print("Card ID: \(card?.id?.uuidString ?? "nil")")
                onRating(.good)
                print("=== End Rating Button Tap ===\n")
            } label: {
                RatingButton(rating: .good)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button {
                print("\n=== Rating Button Tapped ===")
                print("Grade: Easy")
                print("Card ID: \(card?.id?.uuidString ?? "nil")")
                onRating(.easy)
                print("=== End Rating Button Tap ===\n")
            } label: {
                RatingButton(rating: .easy)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
        .onAppear {
            print("\n=== RatingButtons View Appeared ===")
            print("Card ID: \(card?.id?.uuidString ?? "nil")")
            print("Available grades: Again, Hard, Good, Easy")
            print("=== End RatingButtons ===\n")
        }
    }
} 