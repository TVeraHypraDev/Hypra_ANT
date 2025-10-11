import SwiftUI

@main
struct Hypra_ANTApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(appModel)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 700, height: 560)

        ImmersiveSpace(id: "WorldSpace") {
            ImmersiveView()
                .environmentObject(appModel)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed) // Puedes usar .full si lo prefieres
    }
}
