import SwiftUI

class CardViewModel: ObservableObject {
    @Published var front: String = ""
    @Published var back: String = ""
    @Published var tags: [String] = []
    
    var isValid: Bool {
        !front.isEmpty && !back.isEmpty
    }
    
    func reset() {
        front = ""
        back = ""
        tags = []
    }
} 