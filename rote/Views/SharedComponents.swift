import SwiftUI

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct MarkdownText: View {
    let text: String
    
    var body: some View {
        if let attributedString = try? AttributedString(markdown: text) {
            Text(attributedString)
                .font(.system(size: 17))
                .foregroundColor(.white)
        } else {
            Text(text)
                .font(.system(size: 17))
                .foregroundColor(.white)
        }
    }
} 
