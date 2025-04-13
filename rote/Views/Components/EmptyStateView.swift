import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    init(icon: String = "rectangle.stack.badge.plus", title: String = "No Cards Available", message: String = "Add cards to your deck to start studying") {
        self.icon = icon
        self.title = title
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
} 