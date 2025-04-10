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
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "1A1A1A"), Color(hex: "0A0A0A")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                if tagGroups.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(tagGroups.keys).sorted(), id: \.self) { tag in
                                NavigationLink(destination: TagDetailView(tag: tag, cards: tagGroups[tag] ?? [])) {
                                    TagRowView(tag: tag, count: tagGroups[tag]?.count ?? 0)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(hex: "5E5CE6"))
                    }
                }
            }
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
                    .fill(Color(hex: "5E5CE6").opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "tag.fill")
                            .foregroundColor(Color(hex: "5E5CE6"))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tag)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("\(count) card\(count == 1 ? "" : "s")")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            .padding(16)
            .background(Color(hex: "1C1C1E"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
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
                gradient: Gradient(colors: [Color(hex: "1A1A1A"), Color(hex: "0A0A0A")]),
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
                .foregroundColor(Color(hex: "8E8E93"))
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
            .foregroundColor(Color(hex: "8E8E93"))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
        )
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "tag.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: "5E5CE6"))
            
            VStack(spacing: 8) {
                Text("No tags yet")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Add tags to your cards to organize them")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 40)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
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