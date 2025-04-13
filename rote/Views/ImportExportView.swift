import SwiftUI
import UniformTypeIdentifiers
import CoreData

struct ImportExportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var exportData: Data?
    
    var body: some View {
        List {
            Section {
                Button(action: exportCards) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color.hex("5E5CE6"))
                        Text("Export Cards")
                            .foregroundColor(.white)
                    }
                }
                .sheet(isPresented: $showingExporter) {
                    if let data = exportData {
                        ShareSheet(activityItems: [data])
                    }
                }
                
                Button(action: { showingImporter = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(Color.hex("5E5CE6"))
                        Text("Import Cards")
                            .foregroundColor(.white)
                    }
                }
                .fileImporter(
                    isPresented: $showingImporter,
                    allowedContentTypes: [.json],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        guard let url = urls.first else { return }
                        importCards(from: url)
                    case .failure(let error):
                        print("Error importing: \(error.localizedDescription)")
                    }
                }
            }
            .listRowBackground(Color.hex("1C1C1E"))
        }
        .navigationTitle("Import/Export")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    private func exportCards() {
        let request = NSFetchRequest<Card>(entityName: "Card")
        do {
            let cards = try viewContext.fetch(request)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            let cardData = cards.map { card in
                [
                    "id": card.id?.uuidString ?? "",
                    "front": card.front ?? "",
                    "back": card.back ?? "",
                    "tags": card.tags,
                    "createdAt": card.createdAt ?? Date(),
                    "modifiedAt": card.modifiedAt ?? Date()
                ] as [String: Any]
            }
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: cardData, options: .prettyPrinted) {
                exportData = jsonData
                showingExporter = true
            }
        } catch {
            print("Error exporting cards: \(error)")
        }
    }
    
    private func importCards(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
            let formatter = ISO8601DateFormatter()
            
            for cardData in json {
                let card = Card(context: viewContext)
                card.id = UUID(uuidString: cardData["id"] as? String ?? UUID().uuidString)
                card.front = cardData["front"] as? String
                card.back = cardData["back"] as? String
                card.tags = (cardData["tags"] as? [String]) ?? []
                
                // Handle dates
                if let createdAtString = cardData["createdAt"] as? String {
                    card.createdAt = formatter.date(from: createdAtString)
                }
                if let modifiedAtString = cardData["modifiedAt"] as? String {
                    card.modifiedAt = formatter.date(from: modifiedAtString)
                }
                if let lastReviewDateString = cardData["lastReviewDate"] as? String {
                    card.lastReviewDate = formatter.date(from: lastReviewDateString)
                }
                if let dueDateString = cardData["dueDate"] as? String {
                    card.dueDate = formatter.date(from: dueDateString)
                }
                
                // Handle numeric values
                card.interval = cardData["interval"] as? Double ?? 0.0
                card.ease = cardData["ease"] as? Double ?? 2.5
                card.streak = cardData["streak"] as? Int32 ?? 0
                card.reviewCount = cardData["reviewCount"] as? Int32 ?? 0
                
                // Handle review history
                if let history = cardData["reviewHistory"] as? [[String: Any]] {
                    card.reviewHistory = history
                }
            }
            
            try viewContext.save()
        } catch {
            print("Error importing: \(error.localizedDescription)")
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension String {
    var iso8601Date: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: self)
    }
} 