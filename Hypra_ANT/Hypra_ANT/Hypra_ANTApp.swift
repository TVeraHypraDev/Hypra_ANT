import SwiftUI

@main
struct Hypra_ANTApp: App {
    @StateObject private var appModel = AppModel()
    @Environment(\.openWindow) private var openWindow
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView().environmentObject(appModel)
        }.windowResizability(.contentSize)
            .defaultSize(width: 700, height: 560)
        .onChange(of: scenePhase) { phase in
                    if phase == .active, !appModel.mainWindowOpen {
                        openWindow(id: "main")
                    }
                }
        ImmersiveSpace(id: "WorldSpace") {
            ImmersiveView().environmentObject(appModel)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
