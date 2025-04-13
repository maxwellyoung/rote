import SwiftUI

struct AboutView: View {
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 64))
                        .foregroundColor(Color.hex(accentColor))
                    
                    Text("Rote")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.system(size: 15))
                        .foregroundColor(Color.hex("8E8E93"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .listRowBackground(Color.hex("1C1C1E"))
            }
            
            Section(header: Text("About").foregroundColor(.gray)) {
                Text("Rote is a beautiful and intuitive spaced repetition app designed to help you learn and remember anything.")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.hex("1C1C1E"))
            }
            
            Section(header: Text("Features").foregroundColor(.gray)) {
                FeatureRow(icon: "sparkles", title: "Beautiful Design", description: "Clean, modern interface with dark mode")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Spaced Repetition", description: "Scientifically proven learning method")
                FeatureRow(icon: "text.alignleft", title: "Markdown Support", description: "Rich text formatting for your cards")
                FeatureRow(icon: "tag", title: "Smart Tags", description: "Organize cards your way")
                FeatureRow(icon: "icloud", title: "iCloud Sync", description: "Seamless sync across devices")
            }
            
            Section(header: Text("Links").foregroundColor(.gray)) {
                Link(destination: URL(string: "https://github.com/yourusername/rote")!) {
                    HStack {
                        Image(systemName: "swift")
                            .foregroundColor(Color.hex(accentColor))
                        Text("Open Source")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14))
                            .foregroundColor(Color.hex("8E8E93"))
                    }
                }
                .listRowBackground(Color.hex("1C1C1E"))
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color.hex("5E5CE6"))
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
            }
            
            Text(description)
                .font(.system(size: 15))
                .foregroundColor(Color.hex("8E8E93"))
        }
        .padding(.vertical, 8)
        .listRowBackground(Color.hex("1C1C1E"))
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AboutView()
        }
        .preferredColorScheme(.dark)
    }
} 