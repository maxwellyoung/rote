import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct BackupSettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("backupFrequency") private var backupFrequency = BackupFrequency.weekly
    @AppStorage("lastBackupDate") private var lastBackupDate: Date?
    @State private var showingBackupAlert = false
    @State private var showingRestoreAlert = false
    @State private var showingFilePicker = false
    @State private var backupData: Data?
    @State private var backupCount = 0
    
    var body: some View {
        List {
            Section(header: Text("Automatic Backups")) {
                Picker("Frequency", selection: $backupFrequency) {
                    ForEach(BackupFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                    }
                }
                
                if let lastBackup = lastBackupDate {
                    HStack {
                        Text("Last Backup")
                        Spacer()
                        Text(lastBackup, style: .date)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Section {
                Button("Backup Now") {
                    backupData = try? exportCards()
                    showingBackupAlert = true
                }
                
                Button("Restore from Backup") {
                    showingFilePicker = true
                }
            }
        }
        .navigationTitle("Backup Settings")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $showingBackupAlert,
            document: BackupDocument(data: backupData),
            contentType: .json
        ) { result in
            switch result {
            case .success:
                lastBackupDate = Date()
            case .failure(let error):
                print("Error exporting backup: \(error)")
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                if let data = try? Data(contentsOf: url) {
                    showingRestoreAlert = true
                    backupData = data
                }
            case .failure(let error):
                print("Error importing backup: \(error)")
            }
        }
        .alert("Restore Backup", isPresented: $showingRestoreAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Restore", role: .destructive) {
                if let data = backupData {
                    try? importCards(from: data)
                }
            }
        } message: {
            Text("This will replace all your current cards with the backup data. This action cannot be undone.")
        }
    }
    
    private func exportCards() throws -> Data {
        let request = NSFetchRequest<Card>(entityName: "Card")
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
                "modifiedAt": card.modifiedAt ?? Date(),
                "lastReviewDate": card.lastReviewDate as Any,
                "dueDate": card.dueDate as Any,
                "reviewCount": card.reviewCount,
                "ease": card.ease,
                "interval": card.interval,
                "streak": card.streak,
                "reviewHistory": card.reviewHistory as Any,
                "deck": card.deck?.id?.uuidString as Any
            ] as [String: Any]
        }
        
        let metadata = createBackupMetadata()
        let metadataData = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
        let cardDataJson = try JSONSerialization.data(withJSONObject: cardData, options: .prettyPrinted)
        
        // Combine metadata and card data with a separator
        var combinedData = metadataData
        combinedData.append(0x00) // Add separator
        combinedData.append(cardDataJson)
        
        return combinedData
    }
    
    private func importCards(from data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Find the separator between metadata and card data
        guard let separatorIndex = data.firstIndex(of: 0x00) else {
            throw NSError(domain: "BackupSettingsView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid backup data format"])
        }
        
        // Split the data into metadata and card data
        let metadataData = data[..<separatorIndex]
        let cardData = data[data.index(after: separatorIndex)...]
        
        // Parse metadata
        if let metadata = try? JSONSerialization.jsonObject(with: metadataData) as? [String: Any] {
            loadBackupMetadata(from: metadata)
        }
        
        // Parse and import cards
        if let cardDataArray = try? JSONSerialization.jsonObject(with: cardData) as? [[String: Any]] {
            // Delete existing cards
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Card")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            try viewContext.execute(deleteRequest)
            
            // Import new cards
            for data in cardDataArray {
                let card = Card(context: viewContext)
                card.id = UUID(uuidString: data["id"] as? String ?? "") ?? UUID()
                card.front = data["front"] as? String
                card.back = data["back"] as? String
                card.tags = data["tags"] as? [String] ?? []
                card.createdAt = data["createdAt"] as? Date
                card.modifiedAt = data["modifiedAt"] as? Date
                card.lastReviewDate = data["lastReviewDate"] as? Date
                card.dueDate = data["dueDate"] as? Date
                card.reviewCount = data["reviewCount"] as? Int32 ?? 0
                card.ease = data["ease"] as? Double ?? 2.5
                card.interval = data["interval"] as? Double ?? 1.0
                card.streak = data["streak"] as? Int32 ?? 0
                card.reviewHistory = data["reviewHistory"]
                
                if let deckId = data["deck"] as? String,
                   let uuid = UUID(uuidString: deckId) {
                    let request = NSFetchRequest<Deck>(entityName: "Deck")
                    request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
                    if let deck = try? viewContext.fetch(request).first {
                        card.deck = deck
                    }
                }
            }
            
            try viewContext.save()
        }
    }
    
    private func createBackupMetadata() -> [String: Any] {
        let metadata: [String: Any] = [
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "timestamp": Date(),
            "lastBackupDate": lastBackupDate ?? Date(),
            "backupCount": backupCount,
            "deviceName": UIDevice.current.name,
            "systemVersion": UIDevice.current.systemVersion
        ]
        return metadata
    }
    
    private func loadBackupMetadata(from metadata: [String: Any]) {
        if let timestamp = metadata["timestamp"] as? Date {
            lastBackupDate = timestamp
        }
        if let count = metadata["backupCount"] as? Int {
            backupCount = count
        }
    }
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    let data: Data?
    
    init(data: Data?) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data ?? Data())
    }
} 