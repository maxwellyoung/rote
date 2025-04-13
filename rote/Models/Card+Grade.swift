import SwiftUI

extension Card.Grade {
    var icon: String {
        switch self {
        case .again: return "arrow.counterclockwise"
        case .hard: return "exclamationmark.triangle"
        case .good: return "checkmark"
        case .easy: return "star"
        }
    }
    
    var color: Color {
        switch self {
        case .again: return .hex("FF3B30")
        case .hard: return .hex("FF9500")
        case .good: return .hex("34C759")
        case .easy: return .hex("5E5CE6")
        }
    }
} 