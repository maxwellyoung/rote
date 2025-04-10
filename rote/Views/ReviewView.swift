import SwiftUI

struct ReviewView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Card.dueDate, ascending: true)],
        predicate: NSPredicate(format: "dueDate <= %@", Date() as NSDate),
        animation: .default)
    private var cards: FetchedResults<Card>
    
    @State private var offset = CGSize.zero
    @State private var color: Color = .black
    @State private var showingAnswer = false
    
    // Haptic feedback generators
    private let impactMed = UIImpactFeedbackGenerator(style: .medium)
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if let card = cards.first {
                    CardView(card: card, showingAnswer: $showingAnswer)
                        .offset(x: offset.width, y: offset.height)
                        .rotationEffect(.degrees(Double(offset.width / 40)))
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    offset = gesture.translation
                                    withAnimation {
                                        color = getColorForGesture(offset)
                                    }
                                    // Light haptic when dragging
                                    if abs(offset.width).truncatingRemainder(dividingBy: 50) < 1 ||
                                       abs(offset.height).truncatingRemainder(dividingBy: 50) < 1 {
                                        impactLight.impactOccurred()
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        handleSwipe(offset)
                                    }
                                }
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: offset)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.green)
                        Text("All caught up!")
                            .font(.title)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        Text("Come back later for more cards")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut, value: cards.isEmpty)
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func getColorForGesture(_ gesture: CGSize) -> Color {
        if abs(gesture.height) > abs(gesture.width) && gesture.height < 0 {
            // Swiping up - Easy
            let normalizedHeight = min(abs(gesture.height) / UIScreen.main.bounds.height, 0.8)
            return .blue.opacity(normalizedHeight)
        } else {
            // Swiping horizontally
            let normalizedWidth = abs(gesture.width) / UIScreen.main.bounds.width
            if gesture.width > 0 {
                return .green.opacity(min(normalizedWidth, 0.8))
            } else {
                return .red.opacity(min(normalizedWidth, 0.8))
            }
        }
    }
    
    private func handleSwipe(_ gesture: CGSize) {
        let card = cards.first!
        
        // Determine the primary direction of the swipe
        if abs(gesture.height) > abs(gesture.width) && gesture.height < -100 {
            // Swipe up - Easy
            impactMed.impactOccurred()
            updateCard(card, rating: .easy)
            offset = CGSize(width: 0, height: -500)
        } else {
            switch gesture.width {
            case -500...(-150):
                // Swipe left - Again
                impactMed.impactOccurred()
                updateCard(card, rating: .again)
                offset = CGSize(width: -500, height: 0)
            case 150...500:
                // Swipe right - Good
                impactMed.impactOccurred()
                updateCard(card, rating: .good)
                offset = CGSize(width: 500, height: 0)
            default:
                offset = .zero
            }
        }
        
        // Reset position after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            offset = .zero
            showingAnswer = false
        }
    }
    
    private func updateCard(_ card: Card, rating: ReviewRating) {
        let (newInterval, newEase) = calculateNextReview(card: card, rating: rating)
        
        // Update card properties
        card.interval = newInterval
        card.ease = newEase
        card.dueDate = Date().addingTimeInterval(newInterval * 86400) // Convert days to seconds
        card.lastReviewDate = Date()
        card.reviewCount += 1
        
        // Create new review record
        let review = Review(context: viewContext)
        review.date = Date()
        review.rating = rating.rawValue
        review.ease = newEase
        review.interval = newInterval
        review.card = card
        
        // Update streak
        let calendar = Calendar.current
        if let lastReview = card.lastReviewDate,
           calendar.isDateInToday(lastReview) || calendar.isDateInYesterday(lastReview) {
            card.streak += 1
        } else {
            card.streak = 1
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    private func calculateNextReview(card: Card, rating: ReviewRating) -> (interval: Double, ease: Double) {
        // Implementation of the SM-2 algorithm
        var ease = card.ease
        var interval = card.interval
        
        switch rating {
        case .again:
            // Failed recall, reset interval and reduce ease
            ease = max(1.3, ease - 0.2)
            interval = 1.0
            
        case .good:
            if interval <= 1.0 {
                // First successful recall
                interval = 4.0
            } else {
                // Regular review, increase interval
                interval *= ease
            }
            // Small ease adjustment
            ease = max(1.3, ease - 0.08)
            
        case .easy:
            if interval <= 1.0 {
                // First successful recall with high confidence
                interval = 7.0
            } else {
                // Easy review, increase interval more
                interval *= (ease * 1.3)
            }
            // Increase ease
            ease = min(2.5, ease + 0.15)
        }
        
        // Ensure minimum interval of 1 day
        interval = max(1.0, interval)
        
        return (interval, ease)
    }
}

enum ReviewRating {
    case again
    case good
    case easy
    
    var rawValue: Int {
        switch self {
        case .again: return 1
        case .good: return 2
        case .easy: return 3
        }
    }
}

struct CardView: View {
    let card: Card
    @Binding var showingAnswer: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                Text(showingAnswer ? (card.back ?? "") : (card.front ?? ""))
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 150)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.2))
                            .shadow(color: .white.opacity(0.1), radius: 10, x: 0, y: 0)
                    )
                    .padding(.horizontal)
                
                if !showingAnswer {
                    Text("Tap to reveal")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom)
                }
                
                if let tags = card.tags {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    showingAnswer.toggle()
                }
            }
            
            Spacer()
            
            HStack(spacing: 40) {
                Image(systemName: "arrow.left")
                    .foregroundColor(.red)
                    .opacity(0.8)
                Text("Again")
                    .foregroundColor(.gray)
                Spacer()
                Text("Good")
                    .foregroundColor(.gray)
                Image(systemName: "arrow.right")
                    .foregroundColor(.green)
                    .opacity(0.8)
            }
            .font(.subheadline)
            .padding(.horizontal, 40)
            .padding(.vertical, 8)
            
            Text("Swipe up for Easy")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

struct ReviewView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 