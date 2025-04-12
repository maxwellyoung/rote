import SwiftUI
import CoreData

struct BuiltInDecksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: BuiltInDeck.DeckCategory?
    @State private var importingDeck: BuiltInDeck?
    @State private var showingImportConfirmation = false
    
    private var groupedDecks: [BuiltInDeck.DeckCategory: [BuiltInDeck]] {
        Dictionary(grouping: BuiltInDeck.allDecks) { $0.category }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.hex("1A1A1A"), Color.hex("1A1A1A").opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(Array(groupedDecks.keys.sorted { $0.rawValue < $1.rawValue }), id: \.self) { category in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(category.rawValue)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 16) {
                                        ForEach(groupedDecks[category] ?? [], id: \.id) { deck in
                                            DeckCard(deck: deck) {
                                                importingDeck = deck
                                                showingImportConfirmation = true
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Built-in Decks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.hex("5E5CE6"))
                }
            }
            .alert("Import Deck", isPresented: $showingImportConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Import") {
                    if let deck = importingDeck {
                        importDeck(deck)
                    }
                }
            } message: {
                if let deck = importingDeck {
                    Text("Import \(deck.cards.count) cards from '\(deck.name)'?")
                }
            }
        }
    }
    
    private func importDeck(_ deck: BuiltInDeck) {
        for builtInCard in deck.cards {
            let card = Card(context: viewContext)
            card.id = UUID()
            card.front = builtInCard.front
            card.back = builtInCard.back
            card.tags = builtInCard.tags
            card.createdAt = Date()
            card.modifiedAt = Date()
            card.interval = 0
            card.ease = 2.5
            card.streak = 0
            card.reviewCount = 0
            card.dueDate = Date()
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error importing deck: \(error)")
        }
    }
}

struct DeckCard: View {
    let deck: BuiltInDeck
    let onImport: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: deck.imageSystemName)
                    .font(.system(size: 24))
                    .foregroundColor(Color.hex("5E5CE6"))
                
                Spacer()
                
                Button(action: onImport) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.hex("5E5CE6"))
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(deck.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(deck.description)
                    .font(.system(size: 14))
                    .foregroundColor(Color.hex("8E8E93"))
                    .lineLimit(3)
                
                Text("\(deck.cards.count) cards")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.hex("5E5CE6"))
            }
        }
        .padding(16)
        .frame(width: 280)
        .background(Color.hex("1C1C1E"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.hex("2C2C2E"), lineWidth: 1)
        )
    }
} 