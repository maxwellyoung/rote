import SwiftUI
import UniformTypeIdentifiers

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
        let fetchRequest = Card.fetchRequest()
        do {
            let cards = try viewContext.fetch(fetchRequest)
            let exportCards = cards.map { card -> [String: Any] in
                [
                    "id": card.id?.uuidString ?? UUID().uuidString,
                    "front": card.front ?? "",
                    "back": card.back ?? "",
                    "tags": card.tags ?? [],
                    "createdAt": card.createdAt ?? Date(),
                    "modifiedAt": card.modifiedAt ?? Date(),
                    "interval": card.interval,
                    "ease": card.ease,
                    "streak": card.streak,
                    "reviewCount": card.reviewCount
                ]
            }
            
            let json = try JSONSerialization.data(withJSONObject: exportCards, options: .prettyPrinted)
            exportData = json
            showingExporter = true
        } catch {
            print("Error exporting: \(error.localizedDescription)")
        }
    }
    
    private func importCards(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
            
            for cardData in json {
                let card = Card(context: viewContext)
                card.id = UUID(uuidString: cardData["id"] as? String ?? UUID().uuidString)
                card.front = cardData["front"] as? String
                card.back = cardData["back"] as? String
                card.tags = cardData["tags"] as? [String]
                card.createdAt = (cardData["createdAt"] as? String)?.iso8601Date ?? Date()
                card.modifiedAt = (cardData["modifiedAt"] as? String)?.iso8601Date ?? Date()
                card.interval = cardData["interval"] as? Double ?? 0.0
                card.ease = cardData["ease"] as? Double ?? 2.5
                card.streak = cardData["streak"] as? Int32 ?? 0
                card.reviewCount = cardData["reviewCount"] as? Int32 ?? 0
                card.dueDate = Date()
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