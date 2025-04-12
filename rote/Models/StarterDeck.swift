import Foundation

struct StarterCard: Codable {
    let id: String
    let front: String
    let back: String
    let type: String?
    let tags: [String]
    let topic: String?
}

struct StarterDeck: Codable {
    let name: String
    let description: String
    let cards: [StarterCard]
    
    static func loadDSADeck() -> StarterDeck? {
        guard let url = Bundle.main.url(forResource: "recall_dsa_starter_deck", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let deck = try? JSONDecoder().decode(StarterDeck.self, from: data) else {
            return nil
        }
        return deck
    }
}