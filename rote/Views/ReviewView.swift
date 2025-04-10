import SwiftUI
import CoreData

enum ReviewRating: String {
    case again = "Again"
    case good = "Good"
    case easy = "Easy"
}

struct ReviewView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Card.dueDate, ascending: true)],
        animation: .default)
    private var cards: FetchedResults<Card>
    
    @State private var currentCardIndex = 0
    @State private var showAnswer = false
    @State private var showStats = false
    
    private var dueCards: [Card] {
        cards.filter { $0.dueDate ?? Date.distantFuture <= Date() }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.hex("1A1A1A"), Color.hex("0A0A0A")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                if dueCards.isEmpty {
                    SharedEmptyStateView(
                        systemImage: "checkmark.circle.fill",
                        title: "All caught up!",
                        message: "No cards due for review",
                        tintColor: Color.hex("30D158")
                    )
                } else if currentCardIndex < dueCards.count {
                    VStack(spacing: 24) {
                        CardView(
                            card: dueCards[currentCardIndex],
                            showAnswer: $showAnswer
                        )
                        
                        if showAnswer {
                            HStack(spacing: 16) {
                                Button(action: { updateCard(.again) }) {
                                    RatingButton(rating: .again)
                                }
                                
                                Button(action: { updateCard(.good) }) {
                                    RatingButton(rating: .good)
                                }
                                
                                Button(action: { updateCard(.easy) }) {
                                    RatingButton(rating: .easy)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showStats.toggle() }) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(Color.hex("5E5CE6"))
                    }
                }
            }
        }
    }
    
    private func updateCard(_ rating: ReviewRating) {
        let card = dueCards[currentCardIndex]
        let review = Review(context: viewContext)
        review.id = UUID()
        review.date = Date()
        review.rating = rating.rawValue
        review.card = card
        
        card.lastReviewDate = Date()
        card.reviewCount += 1
        
        switch rating {
        case .again:
            card.streak = 0
            card.interval = 1.0
        case .good:
            card.streak += 1
            card.interval = calculateNextInterval(card: card, rating: rating)
        case .easy:
            card.streak += 1
            card.interval = calculateNextInterval(card: card, rating: rating)
            card.ease = min(3.0, card.ease + 0.1)
        }
        
        card.dueDate = Calendar.current.date(byAdding: .day, value: Int(card.interval), to: Date())
        
        do {
            try viewContext.save()
            withAnimation {
                showAnswer = false
                currentCardIndex += 1
            }
        } catch {
            print("Error saving review: \(error)")
        }
    }
    
    private func calculateNextInterval(card: Card, rating: ReviewRating) -> Double {
        let currentInterval = card.interval
        let ease = card.ease
        
        switch rating {
        case .again:
            return 1.0
        case .good:
            return currentInterval * ease
        case .easy:
            return currentInterval * ease * 1.3
        }
    }
}

struct CardView: View {
    let card: Card
    @Binding var showAnswer: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    Text(card.front ?? "")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 24)
                    
                    if showAnswer {
                        Divider()
                            .background(Color.hex("2C2C2E"))
                        
                        Text(card.back ?? "")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            
            if !showAnswer {
                Button(action: { withAnimation { showAnswer.toggle() }}) {
                    Text("Show Answer")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.hex("5E5CE6"))
                }
            }
        }
        .background(Color.hex("1C1C1E"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.hex("2C2C2E"), lineWidth: 1)
        )
    }
}

struct RatingButton: View {
    let rating: ReviewRating
    
    private var color: Color {
        switch rating {
        case .again: return Color.hex("FF453A")
        case .good: return Color.hex("30D158")
        case .easy: return Color.hex("0A84FF")
        }
    }
    
    var body: some View {
        Text(rating.rawValue)
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(color)
            .cornerRadius(12)
    }
}

struct ReviewView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
} 