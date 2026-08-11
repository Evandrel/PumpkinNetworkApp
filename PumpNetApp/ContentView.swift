// xcode: set sdk=iOS

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ToolsView()
                .tabItem { Label("Tools", systemImage: "wrench.and.screwdriver.fill") }
            ArticlesView()
                .tabItem { Label("Articles", systemImage: "newspaper.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            About()
                .tabItem { Label("About", systemImage: "info.circle.fill") }
        }
        .tint(.green)
    }
}

#Preview { ContentView() }
