//
//  ContentView.swift
//  rote
//
//  Created by Maxwell Young on 11/04/2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ReviewView()
                .tabItem {
                    Label("Review", systemImage: "rectangle.stack.fill")
                }
                .tag(0)
            
            EditorView()
                .tabItem {
                    Label("New", systemImage: "plus.circle.fill")
                }
                .tag(1)
            
            TagsView()
                .tabItem {
                    Label("Tags", systemImage: "tag.fill")
                }
                .tag(2)
        }
        .accentColor(.blue)
        .preferredColorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
