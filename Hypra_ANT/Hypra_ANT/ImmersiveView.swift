import ARKit
import OSLog
import RealityKit
import RealityKitContent
import SwiftUI
import Combine

extension Notification.Name {
    static let teardownReality = Notification.Name("teardownReality")
}

private let htLog = Logger(subsystem: "Hypra_ANT", category: "HandTracking")
private let log = Logger(subsystem: "Hypra_ANT", category: "HandTracking")

struct ModelTuning {
    var uniformScale: Float? = nil
    var position: SIMD3<Float>? = nil
    var rotationEuler: SIMD3<Float>? = nil
}

//MARK: Dedo medio e índice
struct HandPanelView: View {
    let selection: String?
    let info: [String: PlaceInfo]

    var body: some View {
        if let sel = selection, let p = info[sel] {
            VStack(alignment: .leading, spacing: 6) {
                Text(sel).font(.headline)
                HStack { Text("Aforo máximo:").bold(); Text("\(p.aforoMaximo)") }
                HStack { Text("Metros cuadrados:").bold(); Text("\(p.m2) m²") }
                HStack { Text("Año de construcción:").bold(); Text("\(p.anioConstruccion)") }
                HStack { Text("Dirección:").bold(); Text(p.direccion) }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        } else {
            Text("Por favor selecciona un paisaje")
                .font(.headline)
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}


// Datos del panel
struct PlaceInfo {
    let aforoMaximo: Int
    let m2: Int
    let anioConstruccion: Int
    let direccion: String
}


private let placeInfo: [String: PlaceInfo] = [
    "Parque":      .init(aforoMaximo: 1200, m2: 8500, anioConstruccion: 1998, direccion: "Cra 10 #20-30"),
    "Cosecha":    .init(aforoMaximo: 600,  m2: 4200, anioConstruccion: 2010, direccion: "Av. Central 123")
]


private let tunings: [String: ModelTuning] = [
    "Parque": .init(uniformScale: 0.2, position: [0, 0, 0]),
    "Cosecha": .init(uniformScale: 0.4, position: [0, 0, 0])
]


struct BoxConfig {
    var scale: SIMD3<Float>
    var positionXZ: SIMD2<Float>
    var yawDeg: Float
}

struct SphereConfig {
    var radius: Float
    var positionXZ: SIMD2<Float>
    var deltaY: Float
}

struct PanelConfig {
    var topOffsetY: Float
    var scale: SIMD3<Float>
}

struct OverlaySetConfig {
    var limitrofes:   BoxConfig
    var catastral:    BoxConfig
    var riesgos:      SphereConfig
    var panelCat:     PanelConfig
    var panelRisk:    PanelConfig
    var PanelText: String
    var PanelTextCat : String
}
//MARK: Información de objetos
let overlayConfigBySelection: [String: OverlaySetConfig] = [

    "Parque":
        .init(
            // Limítrofes
            limitrofes: .init(
                scale:      SIMD3<Float>(4.5, 0.4, 5.0),
                positionXZ: SIMD2<Float>(0.75, 0.2),
                yawDeg:     353
            ),
            // Catastralidad
            catastral: .init(
                scale:      SIMD3<Float>(0.5, 0.5, 5.0),
                positionXZ: SIMD2<Float>(-1.79, 0.0),
                yawDeg:     353
            ),
            // Riesgos
            riesgos: .init(
                radius:     0.6,
                positionXZ: SIMD2<Float>(0.0, 0.3),
                deltaY:     -0.05
            ),
            panelCat:  .init(topOffsetY: 0.4, scale: SIMD3<Float>(10,10,10)),
            panelRisk: .init(topOffsetY: 0.4, scale: SIMD3<Float>(10,10,10)),
            PanelText: "Posible inundación por cercanía al río.",
            PanelTextCat: "Predio/Nomenclatura: Vía la Calera - Sopó KM 50"
        ),

    "Cosecha":
            .init(
                // Limítrofes
                limitrofes: .init(
                    scale:      SIMD3<Float>(2.0, 0.3, 2.7),
                    positionXZ: SIMD2<Float>(-0.05, 0.4),
                    yawDeg:     92
                ),
                // Catastralidad
                catastral: .init(
                    scale:      SIMD3<Float>(0.2, 0.2, 5.0),
                    positionXZ: SIMD2<Float>(-0.7, -0.72),
                    yawDeg:     92
                ),
                // Riesgos
                riesgos: .init(
                    radius:     0.6,
                    positionXZ: SIMD2<Float>(0.8, 0.3),
                    deltaY:     -0.05
                ),
                panelCat:  .init(topOffsetY: 0.4, scale: SIMD3<Float>(10,10,10)),
                panelRisk: .init(topOffsetY: 0.4, scale: SIMD3<Float>(10,10,10)),
                PanelText: "Cosechas altamente combustibles en temporada seca.",
                PanelTextCat: "Predio/Nomenclatura: Vía Mingueo - Santa Marta KM 90"
            )
]


struct CatastralPanelView: View {
    var nombre: String?
    var descripcion : String?
    var body: some View {
        let color = Color(.sRGB, red: 0.0, green: 0.4, blue: 0.0, opacity: 1.0)
        VStack(alignment: .leading, spacing: 6) {
            Text(nombre ?? "Información Catastral").font(.headline).foregroundStyle(color)
            Text(descripcion ?? "Predio/Nomenclatura: Vía la Calera - Sopó KM 404")
                .foregroundStyle(color)
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

//MARK: Immersive View
struct ImmersiveView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    @State private var headAnchor = AnchorEntity(.head)
    @State private var limitrofesBox: ModelEntity? = nil

    @State private var anchor = AnchorEntity(
        .world(transform: matrix_identity_float4x4)
    )
    @State private var needsGestureInstall = false
    @State private var currentEntity: Entity? = nil
    @State private var isLoading = false

    @State private var arSession = ARKitSession()
    @State private var handProvider = HandTrackingProvider()
    @State private var handTask: Task<Void, Never>? = nil

    @State private var showHandPanel = false
    @State private var panel = Entity()
    
    @State private var catastralBox: ModelEntity? = nil
    @State private var catastralPanel = Entity()
    
    @State private var riesgosSphere: ModelEntity? = nil
    @State private var riesgosPanel = Entity()

    var body: some View {
        RealityView { content in
            content.add(anchor)
            content.add(headAnchor)

            // Panel que seguirá la mano
            panel.components.set(BillboardComponent())
            refreshPanelView()
            panel.isEnabled = false
            headAnchor.addChild(panel)
        }update: { content in
            
        }
        
        .onChange(of: showHandPanel) { newValue in
            panel.isEnabled = newValue
        }.onChange(of: appModel.selectedName) { _ in
            refreshPanelView()
        }
        .task(id: appModel.selectedName) {
            if let name = appModel.selectedName {
                await loadOrReplaceModel(name: name)
            }
        }.onAppear {
            appModel.worldSpaceOpen = true
            log.info("ImmersiveView onAppear")
            guard HandTrackingProvider.isSupported else {
                log.error("HandTracking NO soportado en este dispositivo/sim")
                return
            }
            log.info("HandTracking soportado. Iniciando sesión ARKit…")
            startHandTracking()
        }
        .onChange(of: appModel.showLimitrofes) { on in
            if on { Task { await MainActor.run { ensureLimitrofesBox() } } }
            else   { Task { await MainActor.run { removeLimitrofesBox() } } }
        }
        .onChange(of: appModel.showCatastralidad) { on in
            if on {
                Task { await MainActor.run {
                    ensureCatastralBox()
                    ensureCatastralPanel()
                } }
            } else {
                Task { await MainActor.run {
                    removeCatastralPanel()
                    removeCatastralBox()
                } }
            }
        }
        .onChange(of: appModel.showRiesgos) { on in
            if on {
                Task { await MainActor.run {
                    ensureRiesgosSphere()
                    ensureRiesgosPanel()
                } }
            } else {
                Task { await MainActor.run {
                    removeRiesgosPanel()
                    removeRiesgosSphere()
                } }
            }
        }
        .onChange(of: appModel.mainWindowOpen) { isOpen in
                    if !isOpen {
                        Task { @MainActor in
                            _ = await dismissImmersiveSpace()
                            appModel.worldSpaceOpen = false
                        }
                    }
                }
        
        .onReceive(NotificationCenter.default.publisher(for: .teardownReality)) { _ in
            Task { @MainActor in
                // 1) desmonta overlays y escena (como ya lo tenías)
                removeLimitrofesBox()
                removeCatastralPanel(); removeCatastralBox()
                removeRiesgosPanel();  removeRiesgosSphere()
                anchor.children.removeAll()
                currentEntity = nil
                stopHandTracking()

                // 2) cierra el ImmersiveSpace desde la propia escena inmersiva ✅
                _ = await dismissImmersiveSpace()
                appModel.worldSpaceOpen = false
            }
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                htLog.info(
                    "scenePhase = active -> (re)start hand tracking si es necesario"
                )
                // Solo arranca si no hay task corriendo
                if handTask == nil { startHandTracking() }
                // Si la sesión quedó pausada, re-lánzala
                if handProvider.state != .running {
                    Task {
                        do {
                            htLog.info(
                                "Reanudando ARKitSession.run por provider.state=\(String(describing: handProvider.state), privacy: .public)"
                            )
                            try await arSession.run([handProvider])
                        } catch {
                            htLog.error(
                                "Error reanudando ARKitSession: \(String(describing: error), privacy: .public)"
                            )
                        }
                    }
                }

            case .inactive, .background:
                htLog.info(
                    "scenePhase = \(String(describing: phase)) -> pausar tracking"
                )
                stopHandTracking()
                panel.isEnabled = false
                showHandPanel = false

            @unknown default:
                break
            }
        }.onDisappear {
            appModel.worldSpaceOpen = false
            stopHandTracking()
        }

    }
    
    //MARK: Todo de Riesgos

    @MainActor
    private func ensureRiesgosSphere() {
        guard let e = currentEntity else { return }

        if let s = riesgosSphere {
            if s.parent != e { s.removeFromParent(); e.addChild(s) }
            applyRiesgosSize(s)
            s.isEnabled = true
            return
        }

        let mat = SimpleMaterial(
            color: .init(red: 0.5, green: 0.0, blue: 0.0, alpha: 0.6),
            roughness: 0.9,
            isMetallic: false
        )

        let mesh = MeshResource.generateSphere(radius: 1)
        let sphere = ModelEntity(mesh: mesh, materials: [mat])
        sphere.name = "RiesgosSphere"
        sphere.collision = nil

        e.addChild(sphere)

        guard let sel = appModel.selectedName,
              let cfg = overlayConfigBySelection[sel]?.riesgos else { return }

        // radius
        sphere.scale = .init(repeating: cfg.radius)
        let baseY = sphere.position.y
        sphere.position = .init(cfg.positionXZ.x, baseY + cfg.deltaY, cfg.positionXZ.y)

        riesgosSphere = sphere
        sphere.isEnabled = true
    }

    @MainActor
    private func applyRiesgosSize(_ sphere: ModelEntity) {
        guard let sel = appModel.selectedName,
              let cfg = overlayConfigBySelection[sel]?.riesgos else { return }

        // radius
        sphere.scale = .init(repeating: cfg.radius)
    }

    @MainActor
    private func removeRiesgosSphere() {
        if let s = riesgosSphere {
            s.isEnabled = false
            s.removeFromParent()
        }
        riesgosSphere = nil
    }


    struct RiesgosPanelView: View {
        var nombre: String?
        var descripcion: String?
        var body: some View {
            let color = Color(.sRGB, red: 0.5, green: 0.0, blue: 0.0, opacity: 1.0)
            VStack(alignment: .leading, spacing: 6) {
                Text(nombre ?? "Riesgos")
                    .font(.headline)
                    .foregroundStyle(color)
                Text(descripcion ?? "Aqui hay un riesgo")
                    .foregroundStyle(color)
            }
            .padding(10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    @MainActor
    private func ensureRiesgosPanel() {
        guard let e = currentEntity else { return }

        if riesgosPanel.parent != nil {
            riesgosPanel.removeFromParent()
        }
        
        let vb = e.visualBounds(relativeTo: e)
        let topY = vb.center.y + vb.extents.y / 2

        riesgosPanel = Entity()

        riesgosPanel.components.set(BillboardComponent())
        
        guard let sel = appModel.selectedName,
              let text = overlayConfigBySelection[sel]?.PanelText,
            let catCfg = overlayConfigBySelection[sel]?.panelRisk
        else { return }
        
        riesgosPanel.components.set(
            ViewAttachmentComponent(rootView: RiesgosPanelView(nombre: appModel.selectedName, descripcion: text))
        )

        riesgosPanel.scale = catCfg.scale
        riesgosPanel.position = .init(0, topY + catCfg.topOffsetY, 0)
        e.addChild(riesgosPanel)
        riesgosPanel.isEnabled = true
    }


    @MainActor
    private func removeRiesgosPanel() {
        riesgosPanel.isEnabled = false
        riesgosPanel.removeFromParent()
    }
    
    //MARK: Todo de catastral

    @MainActor
    private func ensureCatastralPanel() {
        guard let e = currentEntity else { return }

        if catastralPanel.parent != nil {
            catastralPanel.removeFromParent()
        }
        
        let vb = e.visualBounds(relativeTo: e)
        let topY = vb.center.y + vb.extents.y / 2

        catastralPanel = Entity()

        catastralPanel.components.set(BillboardComponent())

        guard let sel = appModel.selectedName,
              let texto = overlayConfigBySelection[sel]?.PanelTextCat,
              let catCfg = overlayConfigBySelection[sel]?.panelCat
        else { return }

        catastralPanel.components.set(
            ViewAttachmentComponent(
                rootView: CatastralPanelView(nombre: appModel.selectedName, descripcion: texto)
            )
        )
        catastralPanel.scale    = catCfg.scale
        catastralPanel.position = .init(0, topY + catCfg.topOffsetY, 0)
        e.addChild(catastralPanel)
        catastralPanel.isEnabled = true
    }

    @MainActor
    private func removeCatastralPanel() {
        catastralPanel.isEnabled = false
        catastralPanel.removeFromParent()
        catastralPanel = Entity()
    }


    
    @MainActor
    private func ensureCatastralBox() {
        guard let e = currentEntity else { return }

        if let box = catastralBox {
            if box.parent != e { box.removeFromParent(); e.addChild(box) }
            applyCatastralSize(box)
            box.isEnabled = true
            return
        }

        let mat = SimpleMaterial(
            color: .init(red: 0.0, green: 0.4, blue: 0.0, alpha: 0.6),
            roughness: 0.9,
            isMetallic: false
        )

        let mesh = MeshResource.generateBox(width: 1, height: 1, depth: 1)
        let box  = ModelEntity(mesh: mesh, materials: [mat])
        box.name = "CatastralBox"
        box.collision = nil

        guard let sel = appModel.selectedName,
              let cfg = overlayConfigBySelection[sel]?.catastral else { return }

        e.addChild(box)
        
        box.scale = cfg.scale
        let keepY = box.position.y
        box.position = .init(cfg.positionXZ.x, keepY, cfg.positionXZ.y)
        let rad = cfg.yawDeg * .pi / 180
        box.orientation = simd_quatf(angle: rad, axis: [0,1,0])


        catastralBox = box
        box.isEnabled = true
    }

    @MainActor
    private func removeCatastralBox() {
        if let box = catastralBox {
            box.isEnabled = false
            box.removeFromParent()
        }
        catastralBox = nil
    }

    @MainActor
    private func applyCatastralSize(_ box: ModelEntity) {
        guard let sel = appModel.selectedName,
              let cfg = overlayConfigBySelection[sel]?.catastral else { return }

        box.scale = cfg.scale
    }

    //MARK: Todo de limítrofes
    
    @MainActor
    private func ensureLimitrofesBox() {
        guard let e = currentEntity else { return }

        if let box = limitrofesBox {
            if box.parent != e { box.removeFromParent(); e.addChild(box) }
            applyLimitrofesSize(box)
            box.isEnabled = true
            return
        }

        // Crear nuevo
        let mat = SimpleMaterial(
            color: .init(red: 1, green: 1, blue: 1, alpha: 0.02),
            roughness: 0.05,
            isMetallic: false
        )

        // Y úsalo al crear el box:
        let mesh = MeshResource.generateBox(width: 1, height: 1, depth: 1)
        let box  = ModelEntity(mesh: mesh, materials: [mat])

        box.name = "LimitrofesBox"
        box.collision = nil
        
        e.addChild(box)

        guard let sel = appModel.selectedName,
              let cfg = overlayConfigBySelection[sel]?.limitrofes else { return }

        
        box.scale = cfg.scale
        
        let keepY = box.position.y
        box.position = .init(cfg.positionXZ.x, keepY, cfg.positionXZ.y)
        
        let rad = cfg.yawDeg * .pi / 180
        box.orientation = simd_quatf(angle: rad, axis: [0,1,0])
	
        limitrofesBox = box
        box.isEnabled = true
    }

    
    @MainActor
    private func removeLimitrofesBox() {
        if let box = limitrofesBox {
            box.isEnabled = false
            box.removeFromParent()
        }
        limitrofesBox = nil
    }

    @MainActor
    private func applyLimitrofesSize(_ box: ModelEntity) {
        guard let sel = appModel.selectedName,
              let cfg = overlayConfigBySelection[sel]?.limitrofes else { return }

        box.scale = cfg.scale
    }

    //MARK: Agregar modelo (terreno)
    
    @MainActor
    private func loadOrReplaceModel(name: String) async {

        log.info("Cargando modelo: \(name, privacy: .public)")
        let t0 = Date()

        isLoading = true
        defer { isLoading = false }

        do {
            let entity = try await Entity(
                named: name,
                in: realityKitContentBundle
            )
            entity.name = name

            entity.components.set(
                InputTargetComponent(allowedInputTypes: [.indirect, .direct])
            )
            entity.generateCollisionShapes(recursive: true)
            entity.components.set(ManipulationComponent())

            anchor.children.removeAll()
            anchor.addChild(entity)
            currentEntity = entity

            
            anchor.position = [-1.0, 1.2, -1.0]

            if let tuning = tunings[name] {
                if let u = tuning.uniformScale {
                    entity.scale = .init(repeating: u)
                }
                if let r = tuning.rotationEuler {
                    let rot =
                        simd_quatf(angle: r.y, axis: [0, 1, 0])
                        * simd_quatf(angle: r.x, axis: [1, 0, 0])
                        * simd_quatf(angle: r.z, axis: [0, 0, 1])
                    entity.orientation = rot
                }
                if let p = tuning.position {
                    entity.position = p
                } else {
                    dropToGround(entity)
                }
            } else {
                dropToGround(entity)
            }

            log.info(
                "Modelo \(name, privacy: .public) cargado. children=\(entity.children.count)"
            )

        } catch {
            print("Error cargando \(name): \(error)")
        }
        
        
        if appModel.showCatastralidad {
            ensureCatastralBox()
            ensureCatastralPanel()
        }
        if appModel.showRiesgos {
            ensureRiesgosSphere()
            ensureRiesgosPanel()
        }
        
        if appModel.showLimitrofes{
            ensureLimitrofesBox()
        }


    }
    
    
    private func dropToGround(_ entity: Entity) {
        let b = entity.visualBounds(relativeTo: nil)
        let minY = b.center.y - b.extents.y / 2
        entity.position.y -= minY
    }
    
    //MARK: Seguimiento de manos

    private func stopHandTracking() {
        htLog.info("stopHandTracking(): cancelando task y parando ARKitSession")
        handTask?.cancel()
        handTask = nil
        Task { try? await arSession.stop() }
    }

    private func startHandTracking() {
        if handTask != nil {
            htLog.info("startHandTracking(): ya había una tarea corriendo")
            return
        }

        if !HandTrackingProvider.isSupported {
            htLog.error(
                "HandTrackingProvider.isSupported == false (¿simulador? ¿falta capability?)"
            )
            return
        }

        htLog.info(
            "startHandTracking(): iniciando Task de ARKitSession + HandTrackingProvider"
        )

        panel.isEnabled = false
        showHandPanel = false

        handTask = Task {
            htLog.info("ARKitSession.run([handProvider])…")
            do {
                try await arSession.run([handProvider])
                htLog.info(
                    "ARKitSession.run OK — provider.state=\(String(describing: handProvider.state), privacy: .public)"
                )
            } catch {
                htLog.error(
                    "ARKitSession.run ERROR: \(String(describing: error), privacy: .public)"
                )
                return
            }

            var updatesCount = 0
            Task.detached { [updatesCount] in
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                if updatesCount == 0 {
                    htLog.warning(
                        "No han llegado anchorUpdates tras 5s. Revisar: ImmersiveSpace abierto, luz/cámara, permisos, capability."
                    )
                    htLog.warning(
                        "Estado actual — provider.state=\(String(describing: handProvider.state), privacy: .public)"
                    )
                }
            }

            htLog.info("Esperando handProvider.anchorUpdates…")
            for await update in handProvider.anchorUpdates {
                updatesCount += 1
                if updatesCount == 1 {
                    htLog.info("¡Primer anchorUpdate recibido!")
                } else if updatesCount % 30 == 0 {
                    htLog.debug(
                        "anchorUpdates recibidos: \(updatesCount, privacy: .public)"
                    )
                }

                let handAnchor = update.anchor

                guard handAnchor.isTracked else {
                    htLog.debug("anchor recibido pero isTracked == false")
                    continue
                }

                htLog.debug(
                    "anchor.tracked con chirality=\(String(describing: handAnchor.chirality), privacy: .public)"
                )

                guard let skel = handAnchor.handSkeleton else {
                    htLog.debug("anchor sin handSkeleton")
                    continue
                }

                let thumb = skel.joint(.thumbTip)
                let middle = skel.joint(.middleFingerTip)
                let wrist = skel.joint(.wrist)

                guard thumb.isTracked, middle.isTracked, wrist.isTracked else {
                    htLog.debug(
                        "joints no tracked — thumb:\(thumb.isTracked, privacy: .public) middle:\(middle.isTracked, privacy: .public) wrist:\(wrist.isTracked, privacy: .public)"
                    )
                    continue
                }

                let thumbW =
                    handAnchor.originFromAnchorTransform
                    * thumb.anchorFromJointTransform
                let middleW =
                    handAnchor.originFromAnchorTransform
                    * middle.anchorFromJointTransform

                let pT = SIMD3<Float>(
                    thumbW.columns.3.x,
                    thumbW.columns.3.y,
                    thumbW.columns.3.z
                )
                let pM = SIMD3<Float>(
                    middleW.columns.3.x,
                    middleW.columns.3.y,
                    middleW.columns.3.z
                )
                let d = simd_distance(pT, pM)

                htLog.debug(
                    "thumb(\(pT.x, format: .fixed(precision: 2)),\(pT.y, format: .fixed(precision: 2)),\(pT.z, format: .fixed(precision: 2)))  middle(\(pM.x, format: .fixed(precision: 2)),\(pM.y, format: .fixed(precision: 2)),\(pM.z, format: .fixed(precision: 2)))  dist=\(d, format: .fixed(precision: 3))"
                )

                let pinch = d < 0.02


                await MainActor.run {
                        showHandPanel = pinch
                        panel.isEnabled = pinch
                        if pinch {
                            panel.position = [0, 0, -0.6]
                        }
                    }
            }
            htLog.info(
                "anchorUpdates loop finalizado (handProvider dejó de emitir)"
            )
        }
    }
    
    private func refreshPanelView() {
        panel.components.set(
            ViewAttachmentComponent(
                rootView: HandPanelView(selection: appModel.selectedName, info: placeInfo)
            )
        )
    }

}
