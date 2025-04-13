import SwiftUI
import CoreData

struct ReviewView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Card.dueDate, ascending: true)],
        animation: .default
    ) private var cards: FetchedResults<Card>
    @State private var currentIndex = 0
    @State private var showingAnswer = false
    @State private var showingFeedback = false
    @State private var selectedRating: Card.Grade?
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    
    private var currentCard: Card? {
        guard !cards.isEmpty else { return nil }
        return cards[currentIndex]
    }
    
    private var progress: Double {
        guard !cards.isEmpty else { return 0 }
        return Double(currentIndex) / Double(cards.count)
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.hex("1A1A1A"), Color.hex("0A0A0A")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.hex("2C2C2E"))
                        
                        Rectangle()
                            .fill(Color.hex(accentColor))
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(height: 2)
                
                if let card = currentCard {
                    CardView(card: card, showingAnswer: $showingAnswer)
                        .transition(.opacity)
                } else {
                    EmptyStateView()
                }
                
                if showingAnswer {
                    RatingButtons(card: currentCard) { grade in
                        withAnimation {
                            selectedRating = grade
                            showingFeedback = true
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Button(action: { withAnimation { showingAnswer = true } }) {
                        Text("Show Answer")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.hex(accentColor))
                            .cornerRadius(10)
                    }
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingFeedback) {
            if let rating = selectedRating {
                FeedbackView(rating: rating) {
                    withAnimation {
                        currentCard?.scheduleReview(grade: rating)
                        nextCard()
                        showingFeedback = false
                        showingAnswer = false
                    }
                }
            }
        }
    }
    
    private func nextCard() {
        withAnimation {
            if currentIndex < cards.count - 1 {
                currentIndex += 1
            } else {
                currentIndex = 0
            }
        }
    }
}

// MARK: - Feedback View
private struct FeedbackView: View {
    let rating: Card.Grade
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: rating.icon)
                .font(.system(size: 48))
                .foregroundColor(rating.color)
            
            Text(rating.feedback)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(rating.color)
                    .cornerRadius(10)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

struct ReviewStatBox: View {
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

struct ReviewView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
} 