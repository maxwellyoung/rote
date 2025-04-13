import SwiftUI

struct ColorPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var accentColor: String
    
    private let colors = [
        "5E5CE6", // Default Blue
        "FF3B30", // Red
        "FF9500", // Orange
        "FFCC00", // Yellow
        "34C759", // Green
        "007AFF", // Blue
        "5856D6", // Indigo
        "AF52DE", // Purple
        "FF2D55", // Pink
        "E5E5EA"  // Gray
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(colors, id: \.self) { color in
                    Button(action: {
                        accentColor = color
                        dismiss()
                    }) {
                        HStack {
                            Circle()
                                .fill(Color.hex(color))
                                .frame(width: 24, height: 24)
                            
                            Spacer()
                                .frame(width: 16)
                            
                            if color == accentColor {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.hex(color))
                            }
                        }
                    }
                    .listRowBackground(Color.hex("1C1C1E"))
                }
            }
            .navigationTitle("Accent Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
} 