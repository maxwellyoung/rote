import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    @AppStorage("useCustomAccentColor") private var useCustomAccentColor = false
    @State private var selectedTab = Tab.study
    
    private enum Tab {
        case study
        case decks
        case analytics
        case tags
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            StudyView()
                .tabItem {
                    Label("Study", systemImage: "brain.fill")
                }
                .tag(Tab.study)
            
            DeckListView()
                .tabItem {
                    Label("Decks", systemImage: "square.stack.fill")
                }
                .tag(Tab.decks)
            
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.analytics)
            
            TagsView()
                .tabItem {
                    Label("Tags", systemImage: "tag.fill")
                }
                .tag(Tab.tags)
        }
        .tint(Color.hex(accentColor))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
} 