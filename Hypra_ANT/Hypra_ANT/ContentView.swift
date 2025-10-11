import SwiftUI

struct ContentView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @EnvironmentObject private var appModel: AppModel

    private let options = ["Parque", "Edificio", "Iglesia", "Parqueadero"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Elige un terreno para explorar")
                .font(.largeTitle).bold()
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                ForEach(options, id: \.self) { name in
                    Button {
                        Task {
                            appModel.selectedName = name
                            _ = await openImmersiveSpace(id: "WorldSpace")
                        }
                    } label: {
                        HStack {
                            Image(systemName: "cube.transparent")
                            Text(name).font(.title2).bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .frame(maxWidth: 520)
        }
        .padding(24)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environmentObject(AppModel())
}
