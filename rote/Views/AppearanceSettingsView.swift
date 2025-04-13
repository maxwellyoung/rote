import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    @AppStorage("useCustomAccentColor") private var useCustomAccentColor = false
    
    private let colorOptions = [
        ("Purple", "5E5CE6"),
        ("Blue", "0A84FF"),
        ("Green", "30D158"),
        ("Orange", "FF9F0A"),
        ("Pink", "FF375F")
    ]
    
    var body: some View {
        List {
            Section(header: Text("Theme").foregroundColor(.gray)) {
                Toggle(isOn: $useCustomAccentColor) {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(Color.hex(accentColor))
                        Text("Custom Accent Color")
                            .foregroundColor(.white)
                    }
                }
                .tint(Color.hex(accentColor))
                .listRowBackground(Color.hex("1C1C1E"))
                
                if useCustomAccentColor {
                    ForEach(colorOptions, id: \.0) { name, hex in
                        Button(action: { accentColor = hex }) {
                            HStack {
                                Circle()
                                    .fill(Color.hex(hex))
                                    .frame(width: 24, height: 24)
                                Text(name)
                                    .foregroundColor(.white)
                                Spacer()
                                if accentColor == hex {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color.hex(hex))
                                }
                            }
                        }
                        .listRowBackground(Color.hex("1C1C1E"))
                    }
                }
            }
            
            Section(header: Text("Preview").foregroundColor(.gray)) {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ForEach(["brain", "tag", "chart.bar", "gearshape"], id: \.self) { icon in
                            Image(systemName: icon)
                                .foregroundColor(accentColor == "5E5CE6" ? .gray : Color.hex(accentColor))
                                .font(.system(size: 24))
                        }
                    }
                    .padding(.top, 8)
                    
                    Button(action: {}) {
                        Text("Sample Button")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.hex(accentColor))
                            .cornerRadius(12)
                    }
                    .disabled(true)
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.hex("1C1C1E"))
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
} 