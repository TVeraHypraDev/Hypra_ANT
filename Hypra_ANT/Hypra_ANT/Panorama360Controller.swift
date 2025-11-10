//
//  Panorama360Controller.swift
//  Hypra_ANT
//
//  Created by Tomás David Vera Molano on 3/11/25.
//

import Foundation
import RealityKit
import SwiftUI
import Combine

@MainActor
final class Panorama360Controller: ObservableObject {
    var anchor = AnchorEntity(.world(transform: matrix_identity_float4x4))
    private(set) var entity: Entity? = nil
    private var loadedName: String? = nil

    func ensure(
        selection: String,
        config: ModelConfig,
        bundle: Bundle,
        headAnchor: AnchorEntity
    ) async {
        
        let headWorld = headAnchor.transformMatrix(relativeTo: nil)
        anchor.setTransformMatrix(headWorld, relativeTo: nil)

        
        if let e = entity, loadedName == config.name {
            applyTransform(e, cfg: config)
            e.isEnabled = true
            return
        }

        
        remove()

        do {
            let e = try await Entity(named: config.name, in: bundle)
            e.name = "Panorama360:\(config.name)"
            e.generateCollisionShapes(recursive: false)
            
            anchor.addChild(e)
            applyTransform(e, cfg: config)
            entity = e
            loadedName = config.name
            e.isEnabled = true
        } catch {
            print("Panorama360Controller: no se pudo cargar \(config.name): \(error)")
        }
    }

    func remove() {
        entity?.isEnabled = false
        entity?.removeFromParent()
        entity = nil
        loadedName = nil
    }

    private func applyTransform(_ e: Entity, cfg: ModelConfig) {
        
        e.scale = cfg.scale

        
        let y = e.position.y
        e.position = .init(cfg.positionXZ.x, y + cfg.deltaY, cfg.positionXZ.y)

        
        let rad = cfg.yawDeg * .pi / 180
        e.orientation = simd_quatf(angle: rad, axis: [0,1,0])
    }
}
