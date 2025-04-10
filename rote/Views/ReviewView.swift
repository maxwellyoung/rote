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
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if let card = cards.first {
                    CardView(card: card, showingAnswer: $showingAnswer)
                        .offset(x: offset.width, y: 0)
                        .rotationEffect(.degrees(Double(offset.width / 40)))
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    offset = gesture.translation
                                    withAnimation {
                                        color = offset.width > 0 ? .green : .red
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation {
                                        swipeCard(width: offset.width)
                                        color = .black
                                    }
                                }
                        )
                } else {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text("All caught up!")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func swipeCard(width: CGFloat) {
        switch width {
        case -500...(-150):
            // Swipe left - Again
            updateCard(cards.first!, rating: .again)
            offset = CGSize(width: -500, height: 0)
        case 150...500:
            // Swipe right - Good
            updateCard(cards.first!, rating: .good)
            offset = CGSize(width: 500, height: 0)
        default:
            offset = .zero
        }
        
        // Reset position after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            offset = .zero
            showingAnswer = false
        }
    }
    
    private func updateCard(_ card: Card, rating: ReviewRating) {
        // TODO: Implement SM-2 algorithm
        let newInterval = calculateNewInterval(card: card, rating: rating)
        card.interval = newInterval
        card.dueDate = Date().addingTimeInterval(newInterval * 86400) // Convert days to seconds
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    private func calculateNewInterval(card: Card, rating: ReviewRating) -> Double {
        // Simplified SM-2 implementation
        switch rating {
        case .again:
            return 1.0 // Review tomorrow
        case .good:
            return card.interval * 2.5 // Double the interval
        }
    }
}

enum ReviewRating {
    case again
    case good
}

struct CardView: View {
    let card: Card
    @Binding var showingAnswer: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            Text(showingAnswer ? (card.back ?? "") : (card.front ?? ""))
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(16)
                .padding()
                .onTapGesture {
                    withAnimation {
                        showingAnswer.toggle()
                    }
                }
            
            Spacer()
            
            if !showingAnswer {
                Text("Tap to reveal")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            }
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