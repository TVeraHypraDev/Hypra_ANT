import OSLog
import SwiftUI

private let log = Logger(subsystem: "Hypra_ANT", category: "Debug")

struct ContentView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    private let options = ["Parque", "Cosecha"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Elige un terreno para explorar")
                .font(.largeTitle).bold()
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { name in
                    Button {
                        Task {
                            appModel.showLimitrofes   = false
                            appModel.showCatastralidad = false
                            appModel.showRiesgos      = false
                            appModel.showMejoras      = false
                            appModel.selectedName = nil
                            appModel.selectedName = name
                            if !appModel.worldSpaceOpen {
                                log.info("Btn \(name) -> abrir ImmersiveSpace")
                                let ok = await openImmersiveSpace(id: "WorldSpace")
                                let _ = await openImmersiveSpace(id: "WorldSpace")
                                appModel.worldSpaceOpen = true
                                log.info("openImmersiveSpace -> \(String(describing: ok), privacy: .public)")
                            }
                            
                        }
                    } label: {
                        let isSelected = (appModel.selectedName == name)
                        
                        HStack(spacing: 10) {
                            Image(
                                systemName: isSelected
                                ? "checkmark.circle.fill"
                                : "cube.transparent"
                            )
                            .imageScale(.large)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(isSelected ? .green : .secondary)
                            .frame(width: 28)
                            .animation(
                                .easeInOut(duration: 0.15),
                                value: isSelected
                            )
                            
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
            .frame(maxWidth: .infinity)
            if appModel.selectedName != nil {
                Divider().padding(.top, 6)

                VStack(spacing: 12) {
                    // Fila 1: tres botones
                    HStack(spacing: 12) {

                        // Catastralidad
                        Button {
                            let willTurnOn = !appModel.showCatastralidad
                            appModel.showCatastralidad.toggle()
                            if willTurnOn {
                                appModel.showLimitrofes = false
                                appModel.showRiesgos = false
                                appModel.showMejoras = false
                            }
                        } label: {
                            let on = appModel.showCatastralidad
                            HStack {
                                Image(systemName: on ? "checkmark.circle.fill" : "square.on.square")
                                    .symbolRenderingMode(.hierarchical)
                                Text("Catastral")
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(appModel.showCatastralidad ? .green : .accentColor)

                        // Limítrofes
                        Button {
                            let willTurnOn = !appModel.showLimitrofes
                            appModel.showLimitrofes.toggle()
                            if willTurnOn {
                                appModel.showCatastralidad = false
                                appModel.showRiesgos = false
                                appModel.showMejoras = false
                            }
                        } label: {
                            let on = appModel.showLimitrofes
                            HStack {
                                Image(systemName: on ? "checkmark.circle.fill" : "square.dashed")
                                    .symbolRenderingMode(.hierarchical)
                                Text("Limítrofes")
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(appModel.showLimitrofes ? .green : .accentColor)

                        // Riesgos
                        Button {
                            let willTurnOn = !appModel.showRiesgos
                            appModel.showRiesgos.toggle()
                            if willTurnOn {
                                appModel.showLimitrofes = false
                                appModel.showCatastralidad = false
                                appModel.showMejoras = false
                            }
                        } label: {
                            let on = appModel.showRiesgos
                            HStack {
                                Image(systemName: on ? "checkmark.circle.fill" : "exclamationmark.triangle")
                                    .symbolRenderingMode(.hierarchical)
                                Text("Riesgos")
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(appModel.showRiesgos ? .red : .accentColor)
                    }

                    // Fila 2: dos botones
                    HStack(spacing: 12) {

                        // Mejoras
                        Button {
                            let willTurnOn = !appModel.showMejoras
                            appModel.showMejoras.toggle()
                            if willTurnOn {
                                appModel.showRiesgos = false
                                appModel.showLimitrofes = false
                                appModel.showCatastralidad = false
                            }
                        } label: {
                            let on = appModel.showMejoras
                            HStack {
                                Image(systemName: on ? "checkmark.circle.fill" : "wrench.and.screwdriver")
                                    .symbolRenderingMode(.hierarchical)
                                Text("Mejoras")
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(appModel.showMejoras ? .mint : .accentColor)

                        // 360
                        Button {
                            appModel.showPanorama360.toggle()
                        } label: {
                            let isOn = appModel.showPanorama360
                            let title: String = {
                                switch appModel.selectedName {
                                case "Parque":  return isOn ? "Salir de Parque 360" : "Entrar a Parque 360"
                                case "Cosecha": return isOn ? "Salir de Cosecha 360" : "Entrar a Cosecha 360"
                                default:        return "Entrar a 360"
                                }
                            }()
                            HStack {
                                Image(systemName: isOn ? "checkmark.circle.fill" : "view.3d")
                                Text(title)
                                    .lineLimit(2)                 // ← permite 2 líneas
                                    .minimumScaleFactor(0.85)     // ← reduce si hace falta
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(appModel.showPanorama360 ? .purple : .accentColor)
                    }
                }
                .frame(maxWidth: .infinity)

            }
        }.onAppear { appModel.mainWindowOpen = true }
            .onDisappear {
                appModel.mainWindowOpen = false
                
                Task { @MainActor in
                    guard appModel.lockWorldSpace == false else {
                        return
                    }
                    
                    appModel.showLimitrofes = false
                    appModel.showCatastralidad = false
                    appModel.showRiesgos = false
                    appModel.showMejoras = false
                    NotificationCenter.default.post(name: .teardownReality, object: nil)
                    _ = await dismissImmersiveSpace()
                    appModel.worldSpaceOpen = false
                }
            }
            .onChange(of: appModel.worldSpaceOpen) { isOpen in
                guard appModel.lockWorldSpace, appModel.mainWindowOpen, !isOpen else { return }
                guard appModel.selectedName != nil, appModel.isShuttingDown == false else { return }
                
                Task { @MainActor in
                    
                    await Task.yield()
                    let _ = await openImmersiveSpace(id: "WorldSpace")
                    appModel.worldSpaceOpen = true
                }
            }
            .padding(24)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environmentObject(AppModel())
}
