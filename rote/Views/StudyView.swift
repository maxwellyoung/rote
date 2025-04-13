import SwiftUI
import CoreData

struct StudyView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Card.dueDate, ascending: true)],
        animation: .default
    ) private var cards: FetchedResults<Card>
    
    @State private var currentIndex = 0
    @State private var showingAnswer = false
    @State private var showingStats = false
    @State private var showingSettings = false
    @State private var showingDeckPicker = false
    @State private var selectedDeck: Deck?
    @State private var isShuffled = false
    @State private var studyAllDecks = false
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    
    private var filteredCards: [Card] {
        let allCards = Array(cards).filter { $0.isReadyForReview }
        if studyAllDecks {
            return isShuffled ? allCards.shuffled() : allCards.sorted { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }
        } else if let selectedDeck = selectedDeck {
            let deckCards = allCards.filter { $0.deck == selectedDeck }
            return isShuffled ? deckCards.shuffled() : deckCards.sorted { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }
        }
        return []
    }
    
    private var currentCard: Card? {
        guard !filteredCards.isEmpty, currentIndex >= 0, currentIndex < filteredCards.count else {
            return nil
        }
        return filteredCards[currentIndex]
    }
    
    private var progress: Double {
        guard !filteredCards.isEmpty else { return 0 }
        return Double(currentIndex) / Double(filteredCards.count)
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
            mainContent
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                deckPickerButton
            }
            ToolbarItem(placement: .principal) {
                deckIndicator
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                menuButton
            }
        }
        .sheet(isPresented: $showingDeckPicker) { deckPickerSheet }
        .sheet(isPresented: $showingStats) { StatsView() }
        .sheet(isPresented: $showingSettings) { SettingsView() }
    }
    
    private var navigationTitle: String {
        if filteredCards.isEmpty {
            return "Study"
        }
        if studyAllDecks {
            return "Study All"
        }
        return selectedDeck?.title ?? "Study"
    }
    
    private var deckIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "rectangle.stack.fill")
                .foregroundColor(Color.hex(accentColor))
            Text(studyAllDecks ? "All Decks" : (selectedDeck?.title ?? "Select Deck"))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
        }
        .onTapGesture { showingDeckPicker = true }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.hex("1A1A1A"), Color.hex("0A0A0A")]),
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            let cards = filteredCards
            let hasCards = !cards.isEmpty
            
            if hasCards, currentCard != nil {
                progressBar
                Spacer()
                cardContent
                Spacer()
                answerControls
            } else {
                WelcomeView(
                    studyAllDecks: $studyAllDecks,
                    showingDeckPicker: $showingDeckPicker
                )
            }
        }
        .onChange(of: selectedDeck) { _, _ in
            resetStudySession()
        }
        .onChange(of: studyAllDecks) { _, _ in
            resetStudySession()
        }
        .onChange(of: isShuffled) { _, _ in
            resetStudySession()
        }
        .onAppear {
            resetStudySession()
        }
    }
    
    private var progressBar: some View {
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
    }
    
    private var cardContent: some View {
        GeometryReader { geometry in
            VStack {
                if let card = currentCard {
                    VStack {
                        Text(card.front ?? "")
                            .font(.system(size: 24, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .frame(height: showingAnswer ? geometry.size.height * 0.4 : geometry.size.height * 0.8)
                            .background(Color.hex("2C2C2E"))
                            .cornerRadius(16)
                        
                        if showingAnswer {
                            Text(card.back ?? "")
                                .font(.system(size: 20))
                                .multilineTextAlignment(.center)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .frame(height: geometry.size.height * 0.4)
                                .background(Color.hex("2C2C2E"))
                                .cornerRadius(16)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: showingAnswer)
                } else {
                    EmptyStateView()
                }
            }
            .padding()
        }
    }
    
    private var showAnswerButton: some View {
        Button {
            if currentCard != nil {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingAnswer = true
                }
            }
        } label: {
            Text("Show Answer")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    currentCard != nil 
                        ? Color.hex(accentColor)
                        : Color.hex("2C2C2E").opacity(0.3)
                )
                .cornerRadius(12)
        }
        .disabled(currentCard == nil)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private struct EmptyStateView: View {
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 48))
                    .foregroundColor(Color.hex("8E8E93"))
                Text("All caught up!")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text("No more cards to review")
                    .font(.system(size: 15))
                    .foregroundColor(Color.hex("8E8E93"))
            }
            .transition(.opacity)
        }
    }
    
    private var answerControls: some View {
        Group {
            if let card = currentCard {
                if showingAnswer {
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            ratingButton(.again, for: card)
                            ratingButton(.hard, for: card)
                        }
                        HStack(spacing: 12) {
                            ratingButton(.good, for: card)
                            ratingButton(.easy, for: card)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(.opacity)
                } else {
                    showAnswerButton
                }
            }
        }
    }
    
    private func ratingButton(_ grade: Card.Grade, for card: Card) -> some View {
        Button {
            handleRating(grade: grade, for: card)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: grade.icon)
                    .font(.system(size: 24))
                Text(grade.rawValue)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(grade.color)
            .cornerRadius(12)
        }
    }
    
    private func handleRating(grade: Card.Grade, for card: Card) {
        let cardId = card.objectID
        
        showingAnswer = false
        
        viewContext.perform {
            guard let card = try? viewContext.existingObject(with: cardId) as? Card else { return }
            card.scheduleReview(grade: grade)
            
            do {
                try viewContext.save()
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if currentIndex < filteredCards.count - 1 {
                            currentIndex += 1
                        } else {
                            currentIndex = 0
                        }
                    }
                }
            } catch {
                print("Failed to save review: \(error)")
            }
        }
    }
    
    private var deckPickerButton: some View {
        Button { showingDeckPicker = true } label: {
            Image(systemName: "rectangle.stack")
                .foregroundColor(.white)
        }
    }
    
    private var menuButton: some View {
        Menu {
            Toggle("Shuffle Cards", isOn: $isShuffled)
            Toggle("Study All Decks", isOn: $studyAllDecks)
            Button { showingStats = true } label: {
                Label("Stats", systemImage: "chart.bar")
            }
            Button { showingSettings = true } label: {
                Label("Settings", systemImage: "gear")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(.white)
        }
    }
    
    private var deckPickerSheet: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    // Cover Flow carousel with dynamic rotation.
                    GeometryReader { geometry in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: -geometry.size.width * 0.5) {
                                // "All Decks" cover.
                                DeckCover(
                                    title: "All Decks",
                                    subtitle: "\(cards.count) cards total",
                                    iconName: "rectangle.stack.fill",
                                    isSelected: studyAllDecks,
                                    width: geometry.size.width * 0.7
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        studyAllDecks = true
                                        selectedDeck = nil
                                        showingDeckPicker = false
                                    }
                                }
                                
                                // Individual deck covers.
                                ForEach(Array(cards.compactMap { $0.deck }.uniqued()), id: \.self) { deck in
                                    DeckCover(
                                        title: deck.title ?? "Untitled Deck",
                                        subtitle: "\(deck.cards?.count ?? 0) cards",
                                        iconName: "rectangle.on.rectangle",
                                        isSelected: selectedDeck == deck,
                                        width: geometry.size.width * 0.7
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                            selectedDeck = deck
                                            studyAllDecks = false
                                            showingDeckPicker = false
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, geometry.size.width * 0.4)
                            .frame(height: geometry.size.height)
                        }
                    }
                    .frame(height: 300)
                    
                    // Selected deck info.
                    VStack(spacing: 8) {
                        Text(studyAllDecks ? "All Decks" : (selectedDeck?.title ?? "Select a Deck"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Text(studyAllDecks ? "\(cards.count) cards total" : "\(selectedDeck?.cards?.count ?? 0) cards")
                            .font(.system(size: 17))
                            .foregroundColor(Color.hex("8E8E93"))
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Select Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showingDeckPicker = false }
                }
            }
        }
    }
    
    // MARK: - DeckCover with Dynamic 3D Rotation
    private struct DeckCover: View {
        let title: String
        let subtitle: String
        let iconName: String
        let isSelected: Bool
        let width: CGFloat
        @AppStorage("accentColor") private var accentColor = "5E5CE6"
        
        var body: some View {
            // Wrap content in a GeometryReader to compute dynamic rotation based on its position.
            GeometryReader { geo in
                // Calculate the cover's midX relative to the screen's centre.
                let globalMidX = geo.frame(in: .global).midX
                let screenMidX = UIScreen.main.bounds.width / 2
                let diff = abs(screenMidX - globalMidX)
                // A factor to control how the angle scales; cap at 60°.
                let rotationAngle = min(diff / 10, 60)
                
                VStack(spacing: 0) {
                    ZStack {
                        // Main cover art.
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.hex("2C2C2E"),
                                        Color.hex("1C1C1E")
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: width, height: width * 0.75)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        VStack(spacing: 16) {
                            Image(systemName: iconName)
                                .font(.system(size: 48))
                                .foregroundColor(Color.hex(accentColor))
                            VStack(spacing: 4) {
                                Text(title)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                                Text(subtitle)
                                    .font(.system(size: 15))
                                    .foregroundColor(Color.hex("8E8E93"))
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    // Reflection effect.
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.hex("2C2C2E").opacity(0.3),
                                        Color.hex("1C1C1E").opacity(0.1)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: width, height: width * 0.75)
                            .scaleEffect(x: 1, y: -0.5, anchor: .top)
                            .mask(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white.opacity(0.2), .clear]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .offset(y: -10)
                }
                .frame(width: width, height: width * 1.0)
                // Apply rotation: if selected, lock to 0; otherwise, use the computed angle.
                .rotation3DEffect(
                    .degrees(isSelected ? 0 : rotationAngle),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: isSelected ? .center : .leading,
                    perspective: 0.2
                )
                .scaleEffect(isSelected ? 1 : 0.7)
                .offset(x: isSelected ? 0 : -width * 0.2)
                .zIndex(isSelected ? 1 : 0)
            }
            .frame(width: width, height: width * 1.0)
        }
    }
    
    private func resetStudySession() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingAnswer = false
            currentIndex = 0
        }
    }
    
    private struct WelcomeView: View {
        @Binding var studyAllDecks: Bool
        @Binding var showingDeckPicker: Bool
        @AppStorage("accentColor") private var accentColor = "5E5CE6"
        
        var body: some View {
            VStack(spacing: 0) {
                Spacer()
                // Icon and Title.
                VStack(spacing: 24) {
                    Image(systemName: "rectangle.stack.badge.plus")
                        .font(.system(size: 64))
                        .foregroundColor(Color.hex("8E8E93"))
                    Text("Welcome to Rote")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                // Description.
                Text("Choose how you'd like to study")
                    .font(.system(size: 17))
                    .foregroundColor(Color.hex("8E8E93"))
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                // Action buttons.
                VStack(spacing: 16) {
                    Button {
                        withAnimation(.spring()) { studyAllDecks = true }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "rectangle.stack.fill")
                                .font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Study All Decks")
                                    .font(.system(size: 17, weight: .semibold))
                                Text("Review cards from all your decks")
                                    .font(.system(size: 13))
                                    .opacity(0.8)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    Button { showingDeckPicker = true } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Choose a Deck")
                                    .font(.system(size: 17, weight: .semibold))
                                Text("Select a specific deck to study")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.white.opacity(0.7))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.hex("2C2C2E"))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                Spacer()
                Spacer()
            }
        }
    }
}

// MARK: - Array Extension for Unique Elements
private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

struct StudyView_Previews: PreviewProvider {
    static var previews: some View {
        StudyView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
}