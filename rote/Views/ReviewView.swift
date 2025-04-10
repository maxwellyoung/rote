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
                        .offset(x: offset.width, y: 0)
                        .rotationEffect(.degrees(Double(offset.width / 40)))
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    offset = gesture.translation
                                    withAnimation {
                                        color = getColorForOffset(offset.width)
                                    }
                                    // Light haptic when dragging
                                    if abs(offset.width).truncatingRemainder(dividingBy: 50) < 1 {
                                        impactLight.impactOccurred()
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        handleSwipe(width: offset.width)
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
    
    private func getColorForOffset(_ width: CGFloat) -> Color {
        let normalizedWidth = abs(width) / UIScreen.main.bounds.width
        if width > 0 {
            return .green.opacity(min(normalizedWidth, 0.8))
        } else {
            return .red.opacity(min(normalizedWidth, 0.8))
        }
    }
    
    private func handleSwipe(width: CGFloat) {
        switch width {
        case -500...(-150):
            // Swipe left - Again
            impactMed.impactOccurred()
            updateCard(cards.first!, rating: .again)
            offset = CGSize(width: -500, height: 0)
        case 150...500:
            // Swipe right - Good
            impactMed.impactOccurred()
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
            return max(1.0, card.interval * 2.5) // Double the interval, minimum 1 day
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
            .padding(.bottom, 20)
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