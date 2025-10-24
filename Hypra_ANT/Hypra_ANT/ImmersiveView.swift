import ARKit
import OSLog
import RealityKit
import RealityKitContent
import SwiftUI

private let htLog = Logger(subsystem: "Hypra_ANT", category: "HandTracking")
private let log = Logger(subsystem: "Hypra_ANT", category: "HandTracking")

// Ajustes opcionales por modelo
struct ModelTuning {
    var uniformScale: Float? = nil
    var position: SIMD3<Float>? = nil
    var rotationEuler: SIMD3<Float>? = nil  // (pitch, yaw, roll) en radianes
}

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

// Ajusta estos valores reales a tu proyecto
private let placeInfo: [String: PlaceInfo] = [
    "Parque":      .init(aforoMaximo: 1200, m2: 8500, anioConstruccion: 1998, direccion: "Cra 10 #20-30"),
    "Edificio":    .init(aforoMaximo: 600,  m2: 4200, anioConstruccion: 2010, direccion: "Av. Central 123"),
    "Iglesia":     .init(aforoMaximo: 400,  m2: 1800, anioConstruccion: 1954, direccion: "Calle 7 #5-12"),
    "Parqueadero": .init(aforoMaximo: 300,  m2: 3200, anioConstruccion: 2018, direccion: "Transv. 4 #45-16"),
]


private let tunings: [String: ModelTuning] = [
    "Parque": .init(uniformScale: 0.2, position: [0, 0, 0]),
    "Edificio": .init(uniformScale: 0.7, position: [0, 0, 0]),
    "Iglesia": .init(uniformScale: 0.01, position: [0, 0, 0]),
    "Parqueadero": .init(uniformScale: 0.15, position: [0, 0, 0]),
]

struct CatastralPanelView: View {
    var nombre: String?
    var body: some View {
        let color = Color(.sRGB, red: 0.0, green: 0.4, blue: 0.0, opacity: 1.0)
        VStack(alignment: .leading, spacing: 6) {
            Text(nombre ?? "Catastralidad").font(.headline).foregroundStyle(color)
            Text("Predio/Nomenclatura: Calle 10 # 20-30")
                .foregroundStyle(color)
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}


struct ImmersiveView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openWindow) private var openWindow
    @State private var reopenedMainOnce = false
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
            // ⬇️ Mueve el panel para que siempre quede frente a la cabeza
            
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
            log.info("ImmersiveView onAppear")
            guard HandTrackingProvider.isSupported else {
                log.error("HandTracking NO soportado en este dispositivo/sim")
                return
            }
            log.info("HandTracking soportado. Iniciando sesión ARKit…")
            startHandTracking()
        }.task {
            if !reopenedMainOnce {
                reopenedMainOnce = true
                openWindow(id: "main")
            }
        }.onChange(of: appModel.showLimitrofes) { on in
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
                stopHandTracking()  // cancela task + arSession.stop()
                panel.isEnabled = false
                showHandPanel = false

            @unknown default:
                break
            }
        }

    }
    
    // ====== RIESGOS: esfera rojo oscuro + panel ======

    @MainActor
    private func ensureRiesgosSphere() {
        guard let e = currentEntity else { return }

        if let s = riesgosSphere {
            if s.parent != e { s.removeFromParent(); e.addChild(s) }
            applyRiesgosSize(s)
            s.isEnabled = true
            return
        }

        // Material: rojo oscuro, misma transparencia que catastralidad (alpha 0.4)
        let mat = SimpleMaterial(
            color: .init(red: 0.5, green: 0.0, blue: 0.0, alpha: 0.6),
            roughness: 0.9,
            isMetallic: false
        )

        let mesh = MeshResource.generateSphere(radius: 1) // base 1m, luego escalamos
        let sphere = ModelEntity(mesh: mesh, materials: [mat])
        sphere.name = "RiesgosSphere"
        sphere.collision = nil

        e.addChild(sphere)

        // Posición centrada respecto al modelo; preserva Y si quieres
        let y = sphere.position.y - 0.05
        sphere.position = .init(0, y, 0.3)

        applyRiesgosSize(sphere)

        riesgosSphere = sphere
        sphere.isEnabled = true
    }

    @MainActor
    private func applyRiesgosSize(_ sphere: ModelEntity) {
        let r = appModel.riskSphereRadius
        sphere.scale = .init(repeating: r) // uniforme
    }

    @MainActor
    private func removeRiesgosSphere() {
        if let s = riesgosSphere {
            s.isEnabled = false
            s.removeFromParent()
        }
        riesgosSphere = nil
    }

    // ====== Panel de Riesgos (texto rojo oscuro que mira a la cabeza) ======

    struct RiesgosPanelView: View {
        var nombre: String?
        var body: some View {
            let color = Color(.sRGB, red: 0.5, green: 0.0, blue: 0.0, opacity: 1.0) // rojo oscuro
            VStack(alignment: .leading, spacing: 6) {
                Text(nombre ?? "Riesgos")
                    .font(.headline)
                    .foregroundStyle(color)
                Text("Posible riesgo de inhundamiento por cercanía al río.")
                    .foregroundStyle(color)
            }
            .padding(10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    @MainActor
    private func ensureRiesgosPanel() {
        guard let e = currentEntity else { return }

        if riesgosPanel.components[BillboardComponent.self] == nil {
            riesgosPanel.components.set(BillboardComponent()) // siempre mira a la cabeza
        }
        riesgosPanel.components.set(
            ViewAttachmentComponent(rootView: RiesgosPanelView(nombre: appModel.selectedName))
        )

        if riesgosPanel.parent != e {
            riesgosPanel.removeFromParent()
            e.addChild(riesgosPanel)
        }

        // Coloca el panel por encima del modelo (usa bounds locales)
        let vb = e.visualBounds(relativeTo: e)
        let topY = vb.center.y + vb.extents.y / 2
        riesgosPanel.scale = .init(10.0, 10.0, 10.0)
        riesgosPanel.position = .init(0, topY + 0.4, 0)
        riesgosPanel.isEnabled = true
    }

    @MainActor
    private func removeRiesgosPanel() {
        riesgosPanel.isEnabled = false
        riesgosPanel.removeFromParent()
    }

    
    @MainActor
    private func ensureCatastralPanel() {
        guard let e = currentEntity else { return }

        // Configura una vez: billboard + rootView
        if catastralPanel.components[BillboardComponent.self] == nil {
            catastralPanel.components.set(BillboardComponent())
        }
        catastralPanel.components.set(
            ViewAttachmentComponent(rootView: CatastralPanelView(nombre: appModel.selectedName))
        )

        if catastralPanel.parent != e {
            catastralPanel.removeFromParent()
            e.addChild(catastralPanel)
        }

        // Colócalo sobre el modelo (usamos bounds locales del entity)
        let vb = e.visualBounds(relativeTo: e)
        let topY = vb.center.y + vb.extents.y / 2
        catastralPanel.scale = .init(10.0, 10.0, 10.0)
        catastralPanel.position = .init(0, topY + 0.4, 0) // 12 cm sobre el “techo”
        catastralPanel.isEnabled = true
    }

    @MainActor
    private func removeCatastralPanel() {
        catastralPanel.isEnabled = false
        catastralPanel.removeFromParent()
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

        // Material “vidrio” verde oscuro
        let mat = SimpleMaterial(
            color: .init(red: 0.0, green: 0.4, blue: 0.0, alpha: 0.6),
            roughness: 0.9,
            isMetallic: false
        )

        let mesh = MeshResource.generateBox(width: 1, height: 1, depth: 1)
        let box  = ModelEntity(mesh: mesh, materials: [mat])
        box.name = "CatastralBox"
        box.collision = nil

        e.addChild(box)
        
        let deg: Float = 353
        let rad = deg * .pi / 180
        box.orientation = simd_quatf(angle: rad, axis: [0, 1, 0])
        

        // Posición local: conserva Y y ajusta X/Z si quieres
        let y = box.position.y
        box.position = .init(-1.79, y, 0)  // céntrico; cambia X/Z si necesitas

        applyCatastralSize(box)

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
        box.scale = [appModel.catBoxWidth, appModel.catBoxHeight, appModel.catBoxDepth]
    }

    
    /// Crea (si hace falta) y ancla el cubo de limítrofes al currentEntity.
    @MainActor
    private func ensureLimitrofesBox() {
        guard let e = currentEntity else { return }

        // Si ya existe, solo actualiza tamaño y asegúrate que está colgado del entity
        if let box = limitrofesBox {
            if box.parent != e { box.removeFromParent(); e.addChild(box) }
            applyLimitrofesSize(box)
            box.isEnabled = true
            return
        }

        // Crear nuevo
        let mat = SimpleMaterial(
            color: .init(red: 1, green: 1, blue: 1, alpha: 0.02),  // 15% opaco (85% transparente)
            roughness: 0.05,
            isMetallic: false
        )

        // Y úsalo al crear el box:
        let mesh = MeshResource.generateBox(width: 1, height: 1, depth: 1)
        let box  = ModelEntity(mesh: mesh, materials: [mat])

        box.name = "LimitrofesBox"
        box.collision = nil // no necesitamos colisiones

        // Colgar directamente del modelo para que LO SIGA si lo mueves/rotas/escalas
        e.addChild(box)

        // Centrarlo en el origen del modelo (ajusta si quieres alinearlo a ground)
        // Mantiene Y, cambia X y Z
        let y = box.position.y
        box.position = SIMD3<Float>(0.75, y, 0.2)
        
        
        let deg: Float = 353
        let rad = deg * .pi / 180
        box.orientation = simd_quatf(angle: rad, axis: [0, 1, 0])


        // Aplicar dimensiones desde AppModel
        applyLimitrofesSize(box)

        limitrofesBox = box
        box.isEnabled = true
    }

    /// Quita/oculta el cubo
    @MainActor
    private func removeLimitrofesBox() {
        if let box = limitrofesBox {
            box.isEnabled = false
            box.removeFromParent()
        }
        limitrofesBox = nil
    }

    /// Aplica dimensiones desde AppModel (ancho/alto/prof.)
    @MainActor
    private func applyLimitrofesSize(_ box: ModelEntity) {
        // Ajusta el mesh via scale (más barato que regenerar malla cada vez)
        // OJO: asume que el box base es 1x1x1
        let w = appModel.limBoxWidth
        let h = appModel.limBoxHeight
        let d = appModel.limBoxDepth
        box.scale = [w, h, d]
    }


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

            // Coloca el ancla frente al usuario (~1.2 m alto y 1.2 m adelante)
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


    }

    /// Baja el modelo hasta que su base toque y=0 (respecto al ancla).
    private func dropToGround(_ entity: Entity) {
        let b = entity.visualBounds(relativeTo: nil)
        let minY = b.center.y - b.extents.y / 2
        entity.position.y -= minY
    }

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

        // Comprobación previa (evita quedarte esperando en simulador o sin capability)
        if !HandTrackingProvider.isSupported {
            htLog.error(
                "HandTrackingProvider.isSupported == false (¿simulador? ¿falta capability?)"
            )
            return
        }

        htLog.info(
            "startHandTracking(): iniciando Task de ARKitSession + HandTrackingProvider"
        )

        // reinicia panel por si quedó encendido
        panel.isEnabled = false
        showHandPanel = false

        handTask = Task {
            // 1) Intentar levantar la sesión
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

            // 2) Watchdog: si no llegan anchors en 5s, avisa
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

            // 3) Entrar al loop de anchors
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

                // No filtramos por chirality, lo mostramos siempre:
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

                let pinch = d < 0.02   // 7 cm funciona con tus valores (0.064 entra, 0.12 no)


                await MainActor.run {
                        showHandPanel = pinch
                        panel.isEnabled = pinch
                        if pinch {
                            // Coloca el panel 60 cm delante de la cabeza (en el anchor .head)
                            panel.position = [0, 0, -0.6]
                        }
                    }
            }  // for await
            htLog.info(
                "anchorUpdates loop finalizado (handProvider dejó de emitir)"
            )
        }  // Task
    }
    
    private func refreshPanelView() {
        // Sustituimos el rootView para reflejar el estado actual
        panel.components.set(
            ViewAttachmentComponent(
                rootView: HandPanelView(selection: appModel.selectedName, info: placeInfo)
            )
        )
    }

}
