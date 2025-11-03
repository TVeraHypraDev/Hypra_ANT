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
            .frame(maxWidth: 800)
            if appModel.selectedName != nil {
                Divider().padding(.top, 6)
                HStack(spacing: 12) {
                    // Catastralidad (funcional)
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
                            Image(
                                systemName: on
                                ? "checkmark.circle.fill"
                                : "square.on.square"
                            )
                            .symbolRenderingMode(.hierarchical)
                            Text("Catastral")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(appModel.showCatastralidad ? .green : .accentColor)
                    
                    // Limítrofes (funcional)
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
                            Image(
                                systemName: on
                                ? "checkmark.circle.fill" : "square.dashed"
                            )
                            .symbolRenderingMode(.hierarchical)
                            Text("Limítrofes")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(appModel.showLimitrofes ? .green : .accentColor)
                    
                    // Riesgos (funcional)
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
                            Image(
                                systemName: on
                                ? "checkmark.circle.fill"
                                : "exclamationmark.triangle"
                            )
                            .symbolRenderingMode(.hierarchical)
                            Text("Riesgos")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(appModel.showRiesgos ? .red : .accentColor)
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
                            Image(
                                systemName: on
                                ? "checkmark.circle.fill"
                                : "wrench.and.screwdriver"
                            )
                            .symbolRenderingMode(.hierarchical)
                            Text("Mejoras")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(appModel.showMejoras ? .mint : .accentColor)
                }
                .frame(maxWidth: 800, maxHeight: .infinity)
            }
        }.onAppear { appModel.mainWindowOpen = true }
            .onDisappear {
                appModel.mainWindowOpen = false
                
                Task { @MainActor in
                    guard appModel.lockWorldSpace == false else {
                        // Bloqueado: NO cierres el Immersive Space.
                        // Solo marca flags; el espacio seguirá vivo.
                        return
                    }
                    
                    // (Solo si no está bloqueado) — tu limpieza previa:
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
                    // Pequeño yield para evitar carrera con onDisappear/onAppear
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
