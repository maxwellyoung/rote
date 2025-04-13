import SwiftUI

struct CardView: View {
    let card: Card
    @Binding var showingAnswer: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text(card.front ?? "")
                .font(.title2)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
            
            if showingAnswer {
                Divider()
                    .background(Color.hex("2C2C2E"))
                
                Text(card.back ?? "")
                    .font(.title3)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.hex("1C1C1E"))
        .cornerRadius(12)
        .padding(.horizontal)
    }
} 