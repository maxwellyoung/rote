import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.hex("1A1A1A"), Color.hex("0A0A0A")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                List {
                    Section {
                        NavigationLink(destination: Text("Appearance Settings")) {
                            Label("Appearance", systemImage: "paintbrush")
                        }
                        
                        NavigationLink(destination: Text("Notification Settings")) {
                            Label("Notifications", systemImage: "bell")
                        }
                        
                        NavigationLink(destination: Text("Review Settings")) {
                            Label("Review Settings", systemImage: "gear")
                        }
                    }
                    .listRowBackground(Color.hex("1C1C1E"))
                    .foregroundColor(.white)
                    
                    Section {
                        NavigationLink(destination: Text("Import/Export")) {
                            Label("Import/Export", systemImage: "square.and.arrow.up.on.square")
                        }
                        
                        NavigationLink(destination: Text("Backup")) {
                            Label("Backup", systemImage: "externaldrive")
                        }
                    }
                    .listRowBackground(Color.hex("1C1C1E"))
                    .foregroundColor(.white)
                    
                    Section {
                        NavigationLink(destination: Text("About")) {
                            Label("About", systemImage: "info.circle")
                        }
                    }
                    .listRowBackground(Color.hex("1C1C1E"))
                    .foregroundColor(.white)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
} 