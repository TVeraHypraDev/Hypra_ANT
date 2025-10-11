import RealityKit
import RealityKitContent
import SwiftUI

// Ajustes opcionales por modelo
struct ModelTuning {
    var uniformScale: Float? = nil
    var position: SIMD3<Float>? = nil
    var rotationEuler: SIMD3<Float>? = nil  // (pitch, yaw, roll) en radianes
}

private let tunings: [String: ModelTuning] = [
    "Parque": .init(uniformScale: 0.2, position: [0, 0, 0]),
    "Edificio": .init(uniformScale: 0.7, position: [0, 0, 0]),
    "Iglesia": .init(uniformScale: 0.01, position: [0, 0, 0]),
    "Parqueadero": .init(uniformScale: 0.15, position: [0, 0, 0]),
]

struct ImmersiveView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var anchor = AnchorEntity(
        .world(transform: matrix_identity_float4x4)
    )
    @State private var needsGestureInstall = false
    @State private var currentEntity: Entity? = nil
    @State private var isLoading = false

    var body: some View {
        RealityView { content in
            content.add(anchor)
        }
        .task(id: appModel.selectedName) {
            if let name = appModel.selectedName {
                await loadOrReplaceModel(name: name)
            }
        }.overlay(alignment: .trailing) {
            if let name = appModel.selectedName {
                Text("Modelo: \(name) — Usa tus manos para mover/rotar/escalar")
                    .font(.headline).padding(10).background(
                        .thinMaterial,
                        in: Capsule()
                    ).padding()
            } else {
                Text("Selecciona un terreno en la ventana").font(.headline)
                    .padding(10).background(.thinMaterial, in: Capsule())
                    .padding()
            }
        }.overlay {
            if isLoading {
                ProgressView("Cargando modelo…").padding().background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 16)
                )
            }
        }

    }

    @MainActor
    private func loadOrReplaceModel(name: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let entity = try await Entity(
                named: name,
                in: realityKitContentBundle
            )
            entity.name = name
            
            entity.components.set(InputTargetComponent(allowedInputTypes: [.indirect, .direct]))
            entity.generateCollisionShapes(recursive: true)
            entity.components.set(ManipulationComponent())

            anchor.children.removeAll()
            anchor.addChild(entity)
            currentEntity = entity

            // Coloca el ancla frente al usuario (~1.2 m alto y 1.2 m adelante)
            anchor.position = [-1.0, 0.8, -1.0]

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

        } catch {
            print("Error cargando \(name): \(error)")
        }
    }

    /// Baja el modelo hasta que su base toque y=0 (respecto al ancla).
    private func dropToGround(_ entity: Entity) {
        let b = entity.visualBounds(relativeTo: nil)
        let minY = b.center.y - b.extents.y / 2
        entity.position.y -= minY
    }
}
