import SwiftUI
import OSLog
private let log = Logger(subsystem: "Hypra_ANT", category: "Debug")

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
                            log.info("Btn \(name) -> abrir ImmersiveSpace")
                            appModel.selectedName = name               // 1) primero define el modelo
                            let ok = await openImmersiveSpace(id: "WorldSpace")  // 2) ábrelo una sola vez
                            appModel.showLimitrofes = false
                            log.info("openImmersiveSpace -> \(String(describing: ok), privacy: .public)")
                            
                        }
                    } label: {
                        let isSelected = (appModel.selectedName == name)

                        HStack(spacing: 10) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "cube.transparent")
                                .imageScale(.large)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(isSelected ? .green : .secondary)
                                .frame(width: 28)
                                .animation(.easeInOut(duration: 0.15), value: isSelected)

                            Text(name)
                                .font(.title2).bold()
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }

                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .frame(maxWidth: 520)
            if appModel.selectedName != nil {
                            Divider().padding(.top, 6)
                            HStack(spacing: 12) {
                                // Catastralidad (placeholder)
                                Button {
                                    // pendiente
                                } label: {
                                    HStack {
                                        Image(systemName: "square.on.square")
                                        Text("Catastralidad")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.bordered)

                                // Limítrofes (funcional)
                                Button {
                                    appModel.showLimitrofes.toggle()
                                } label: {
                                    let on = appModel.showLimitrofes
                                    HStack {
                                        Image(systemName: on ? "checkmark.circle.fill" : "square.dashed")
                                            .symbolRenderingMode(.hierarchical)
                                        Text("Limítrofes")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(appModel.showLimitrofes ? .green : .accentColor)

                                // Riesgos (placeholder)
                                Button {
                                    // pendiente
                                } label: {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle")
                                        Text("Riesgos")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.bordered)
                            }
                            .frame(maxWidth: 520)
                        }
        }
        .padding(24)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environmentObject(AppModel())
}
