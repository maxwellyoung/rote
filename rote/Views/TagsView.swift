import SwiftUI
import CoreData

struct TagsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Card.createdAt, ascending: true)],
        animation: .default)
    private var cards: FetchedResults<Card>
    
    @State private var searchText = ""
    @State private var selectedTag: String?
    
    private var tagGroups: [String: [Card]] {
        var groups: [String: [Card]] = [:]
        for card in cards {
            for tag in (card.tags ?? []) {
                if groups[tag] == nil {
                    groups[tag] = []
                }
                groups[tag]?.append(card)
            }
        }
        return groups
    }
    
    private var filteredTags: [String] {
        let tags = Array(tagGroups.keys).sorted()
        if searchText.isEmpty {
            return tags
        }
        return tags.filter { $0.localizedCaseInsensitiveContains(searchText) }
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
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.hex("8E8E93"))
                        
                        TextField("Search tags...", text: $searchText)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color.hex("8E8E93"))
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.hex("1C1C1E"))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    if filteredTags.isEmpty {
                        SharedEmptyStateView(
                            systemImage: "tag.circle.fill",
                            title: "No tags found",
                            message: searchText.isEmpty ? "Add tags to your cards to organize them" : "Try a different search term",
                            tintColor: Color.hex("5E5CE6")
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredTags, id: \.self) { tag in
                                    NavigationLink(destination: TagDetailView(tag: tag, cards: tagGroups[tag] ?? [])) {
                                        TagRowView(tag: tag, count: tagGroups[tag]?.count ?? 0)
                                    }
                                }
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TagRowView: View {
    let tag: String
    let count: Int
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.hex("5E5CE6").opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "tag.fill")
                            .foregroundColor(Color.hex("5E5CE6"))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tag)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("\(count) card\(count == 1 ? "" : "s")")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.hex("8E8E93"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.hex("8E8E93"))
            }
            .padding(16)
            .background(Color.hex("1C1C1E"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.hex("2C2C2E"), lineWidth: 1)
            )
        }
    }
}

struct TagDetailView: View {
    let tag: String
    let cards: [Card]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.hex("1A1A1A"), Color.hex("0A0A0A")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(cards, id: \.id) { card in
                        CardPreviewView(card: card)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .navigationTitle(tag)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CardPreviewView: View {
    let card: Card
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(card.front ?? "")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Text(card.back ?? "")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color.hex("8E8E93"))
                .lineLimit(3)
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                    Text(card.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "")
                        .font(.system(size: 12, weight: .medium))
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 12))
                    Text("\(String(format: "%.1f", card.interval))d")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .foregroundColor(Color.hex("8E8E93"))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.hex("1C1C1E"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.hex("2C2C2E"), lineWidth: 1)
        )
    }
}

struct TagsView_Previews: PreviewProvider {
    static var previews: some View {
        TagsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
} 