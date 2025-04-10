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
                
                VStack(spacing: 24) {
                    // Stats summary
                    HStack(spacing: 24) {
                        StatBox(title: "Due", value: "\(dueCards.count)")
                        StatBox(title: "Reviewed", value: "\(currentCardIndex)")
                        StatBox(title: "Success", value: "85%")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    if dueCards.isEmpty {
                        SharedEmptyStateView(
                            systemImage: "checkmark.circle.fill",
                            title: "All caught up!",
                            message: "No cards due for review",
                            tintColor: Color.hex("30D158")
                        )
                    } else if currentCardIndex < dueCards.count {
                        CardView(
                            card: dueCards[currentCardIndex],
                            showAnswer: $showAnswer
                        )
                        .padding(.horizontal, 16)
                        
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
                            .padding(.horizontal, 16)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func updateCard(_ rating: ReviewRating) {
        let card = dueCards[currentCardIndex]
        let review = Review(context: viewContext)
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

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.hex("8E8E93"))
            
            Text(value)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.hex("1C1C1E"))
        .cornerRadius(12)
    }
}

struct CardView: View {
    let card: Card
    @Binding var showAnswer: Bool
    @State private var isFlipped = false
    
    var body: some View {
        ZStack {
            // Front of card
            frontView
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
            
            // Back of card
            backView
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .animation(.easeInOut(duration: 0.5), value: isFlipped)
        .frame(height: 400)
        .onTapGesture {
            withAnimation {
                isFlipped.toggle()
                showAnswer.toggle()
            }
        }
    }
    
    private var frontView: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(card.front ?? "")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let tags = card.tags {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.hex("5E5CE6"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.hex("5E5CE6").opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            Spacer()
            
            Text("Tap to flip")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.hex("8E8E93"))
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.hex("1C1C1E"))
        .cornerRadius(16)
    }
    
    private var backView: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(card.back ?? "")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 13))
                    Text("\(String(format: "%.1f", card.interval))d")
                        .font(.system(size: 13, weight: .medium))
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "flame")
                        .font(.system(size: 13))
                    Text("\(card.streak)")
                        .font(.system(size: 13, weight: .medium))
                }
            }
            .foregroundColor(Color.hex("8E8E93"))
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.hex("1C1C1E"))
        .cornerRadius(16)
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