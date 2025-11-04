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

struct ModelConfig {
    var name: String
    var scale: SIMD3<Float>
    var positionXZ: SIMD2<Float>
    var yawDeg: Float
    var deltaY: Float
}

struct OverlaySetConfig {
    var limitrofes:   BoxConfig
    var catastral:    BoxConfig
    var riesgos:      SphereConfig
    var panelCat:     PanelConfig
    var panelRisk:    PanelConfig
    var PanelText: String
    var PanelTextCat : String
    
    var mejorasModel: ModelConfig
    var panelImprove: PanelConfig
    var PanelTextImprove: String
    var panorama360: ModelConfig
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
                PanelTextCat: "Predio/Nomenclatura: Vía la Calera - Sopó KM 50",
                mejorasModel: .init(
                    name: "TanqueAgua",
                    scale: SIMD3<Float>(0.2, 0.2, 0.2),
                    positionXZ: SIMD2<Float>(1.2, 0.0),
                    yawDeg: 0,
                    deltaY: 0.1
                ),
                panelImprove: .init(
                    topOffsetY: 0.4,
                    scale: SIMD3<Float>(10,10,10)
                ),
                PanelTextImprove: "Tanque de agua para limpieza de agua del río.",
                panorama360: .init(
                        name: "Parque360",
                        scale: SIMD3<Float>(10,10,10),   // suele necesitar esfera grande
                        positionXZ: SIMD2<Float>(0,0),
                        yawDeg: 0,
                        deltaY: -5
                    )
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
                PanelTextCat: "Predio/Nomenclatura: Vía Mingueo - Santa Marta KM 90",
                mejorasModel: .init(
                    name: "Molino",
                    scale: SIMD3<Float>(0.4, 0.4, 0.4),
                    positionXZ: SIMD2<Float>(-0.8, -0.2),
                    yawDeg: 20,
                    deltaY: 0.25
                ),
                panelImprove: .init(
                    topOffsetY: 0.4,
                    scale: SIMD3<Float>(10,10,10)
                ),
                PanelTextImprove: "Molino para optimización de productividad.",
                panorama360: .init(
                        name: "Cosecha360",
                        scale: SIMD3<Float>(10,10,10),
                        positionXZ: SIMD2<Float>(0,0),
                        yawDeg: 0,
                        deltaY: -5
                    )
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
    
    @State private var mejorasEntity: Entity? = nil
    @State private var mejorasPanel = Entity()
    
    @State private var needsAnchorReadd = false
    
    @StateObject private var panoCtrl = Panorama360Controller()
    @State private var panoNeedsReadd = false


    var body: some View {
        RealityView { content in
            content.add(anchor)
            content.add(headAnchor)
            content.add(panoCtrl.anchor)
            
            // Panel que seguirá la mano
            panel.components.set(BillboardComponent())
            refreshPanelView()
            panel.isEnabled = false
            headAnchor.addChild(panel)
        } update: { content in
            if needsAnchorReadd {
                if !content.entities.contains(where: { $0 == anchor }) {
                    content.add(anchor)
                }
                needsAnchorReadd = false
            }
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
            if appModel.showPanorama360 {
                    Task { @MainActor in
                        guard
                            let sel = appModel.selectedName,
                            let cfg = overlayConfigBySelection[sel]?.panorama360
                        else { return }
                        await panoCtrl.ensure(selection: sel, config: cfg, bundle: realityKitContentBundle, headAnchor: headAnchor)
                    }
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
        }.onChange(of: appModel.showMejoras) { on in
            if on {
                Task { @MainActor in
                    await ensureMejorasModel()
                    ensureMejorasPanel()
                }
            } else {
                Task { @MainActor in
                    removeMejorasPanel()
                    removeMejorasModel()
                }
            }
        }.onChange(of: appModel.showPanorama360) { on in
            if on {
                Task { @MainActor in
                    // Oculta temporalmente el entorno normal
                    currentEntity?.isEnabled = false

                    // Apaga overlays (opcional, recomendado para evitar solapados)
                    appModel.showLimitrofes = false
                    appModel.showCatastralidad = false
                    appModel.showRiesgos = false
                    appModel.showMejoras = false

                    guard
                        let sel = appModel.selectedName,
                        let cfg = overlayConfigBySelection[sel]?.panorama360
                    else { return }

                    await panoCtrl.ensure(selection: sel, config: cfg, bundle: realityKitContentBundle, headAnchor: headAnchor)
                }
            } else {
                Task { @MainActor in
                    panoCtrl.remove()
                    // Vuelve a mostrar el entorno
                    currentEntity?.isEnabled = true
                }
            }
        }
        .onChange(of: appModel.mainWindowOpen) { isOpen in
            if !isOpen {
                Task { @MainActor in
                    _ = await dismissImmersiveSpace()
                    appModel.worldSpaceOpen = false
                }
            }
        }.onReceive(NotificationCenter.default.publisher(for: .teardownReality)) { _ in
            Task { @MainActor in
                panoCtrl.remove()
                panoCtrl.anchor = AnchorEntity(.world(transform: matrix_identity_float4x4))
                panoNeedsReadd = true
                removeLimitrofesBox()
                removeCatastralPanel(); removeCatastralBox()
                removeRiesgosPanel();  removeRiesgosSphere()
                removeMejorasPanel();  removeMejorasModel()

                anchor.children.removeAll()
                anchor = AnchorEntity(.world(transform: matrix_identity_float4x4))
                needsAnchorReadd = true
                currentEntity = nil

                stopHandTracking()

                // 3) da un frame y cierra el espacio (idempotente)
                await Task.yield()
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
                if handTask == nil { startHandTracking() }
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

            anchor.children.removeAll()
            currentEntity = nil

            anchor = AnchorEntity(.world(transform: matrix_identity_float4x4))
            needsAnchorReadd = true
        }

        
    }
    
    //MARK: Todo de Mejoras
    
    @MainActor
    private func ensureMejorasPanel() {
        guard let e = currentEntity else { return }
        
        // calcular bounds SIN el panel colgado
        if mejorasPanel.parent != nil { mejorasPanel.removeFromParent() }
        let vb = e.visualBounds(relativeTo: e)
        let topY = vb.center.y + vb.extents.y / 2
        
        mejorasPanel = Entity()
        mejorasPanel.components.set(BillboardComponent())
        
        guard let sel = appModel.selectedName,
              let txt = overlayConfigBySelection[sel]?.PanelTextImprove,
              let pCfg = overlayConfigBySelection[sel]?.panelImprove
        else { return }
        
        mejorasPanel.components.set(
            ViewAttachmentComponent(
                rootView: MejorasPanelView(nombre: appModel.selectedName, descripcion: txt)
            )
        )
        
        mejorasPanel.scale    = pCfg.scale
        mejorasPanel.position = .init(0, topY + pCfg.topOffsetY, 0)
        e.addChild(mejorasPanel)
        mejorasPanel.isEnabled = true
    }
    
    @MainActor
    private func removeMejorasPanel() {
        mejorasPanel.isEnabled = false
        mejorasPanel.removeFromParent()
        mejorasPanel = Entity()
    }
    
    struct MejorasPanelView: View {
        var nombre: String?
        var descripcion: String
        var body: some View {
            let color = Color(.sRGB, red: 0.1, green: 0.35, blue: 0.6, opacity: 1.0)
            VStack(alignment: .leading, spacing: 6) {
                Text(nombre ?? "Mejoras")
                    .font(.headline)
                    .foregroundStyle(color)
                Text(descripcion)
                    .foregroundStyle(color)
            }
            .padding(10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    @MainActor
    private func ensureMejorasModel() async {
        guard let parent = currentEntity,
              let sel = appModel.selectedName,
              let cfg = overlayConfigBySelection[sel]?.mejorasModel else { return }
        
        // Si ya existe, solo re-posiciona/re-orienta/escala y re-cuelga
        if let m = mejorasEntity {
            if m.parent != parent { m.removeFromParent(); parent.addChild(m) }
            applyMejorasTransform(m, cfg: cfg)
            m.isEnabled = true
            return
        }
        
        do {
            let entity = try await Entity(named: cfg.name, in: realityKitContentBundle)
            entity.name = "Mejoras:\(cfg.name)"
            entity.generateCollisionShapes(recursive: true)
            parent.addChild(entity)
            applyMejorasTransform(entity, cfg: cfg)
            mejorasEntity = entity
            entity.isEnabled = true
        } catch {
            log.error("No se pudo cargar mejoras (\(cfg.name, privacy: .public)): \(String(describing: error), privacy: .public)")
        }
    }
    
    @MainActor
    private func applyMejorasTransform(_ e: Entity, cfg: ModelConfig) {
        e.scale = cfg.scale
        
        // posición (X/Z de la config + Y base del parent + deltaY)
        let baseY = e.position.y
        e.position = .init(cfg.positionXZ.x, baseY + cfg.deltaY, cfg.positionXZ.y)
        
        // rotación yaw
        let rad = cfg.yawDeg * .pi / 180
        e.orientation = simd_quatf(angle: rad, axis: [0,1,0])
    }
    
    @MainActor
    private func removeMejorasModel() {
        if let m = mejorasEntity {
            m.isEnabled = false
            m.removeFromParent()
        }
        mejorasEntity = nil
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
        
        if appModel.showMejoras {
            await ensureMejorasModel()
            ensureMejorasPanel()
        }
        
        if appModel.showPanorama360 {
            currentEntity?.isEnabled = false
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
