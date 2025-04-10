import SwiftUI
import CoreData

struct TagsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Card.createdAt, ascending: true)],
        animation: .default)
    private var cards: FetchedResults<Card>
    
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
    
    var body: some View {
        NavigationView {
            List {
                if tagGroups.isEmpty {
                    Text("No tags yet")
                        .foregroundColor(.gray)
                } else {
                    ForEach(Array(tagGroups.keys).sorted(), id: \.self) { tag in
                        NavigationLink(destination: TagDetailView(tag: tag, cards: tagGroups[tag] ?? [])) {
                            HStack {
                                Text(tag)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(tagGroups[tag]?.count ?? 0)")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TagDetailView: View {
    let tag: String
    let cards: [Card]
    
    var body: some View {
        List {
            ForEach(cards, id: \.id) { card in
                VStack(alignment: .leading, spacing: 12) {
                    Text(card.front ?? "")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(card.back ?? "")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text("Due: \(card.dueDate ?? Date(), formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("Interval: \(String(format: "%.1f", card.interval)) days")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle(tag)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

struct TagsView_Previews: PreviewProvider {
    static var previews: some View {
        TagsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 