import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ScanTabView()
                .tabItem {
                    Label("Scan", systemImage: "camera.viewfinder")
                }
            AccuracyTestView()
                .tabItem {
                    Label("Accuracy Test", systemImage: "ruler")
                }
        }
    }
}

#Preview {
    ContentView()
}
