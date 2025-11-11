import Combine
import Foundation
import RealityKit
import SwiftUI

enum LayerKind: String, CaseIterable, Identifiable {
    case reservaForestal = "Reserva forestal"
    case agricola        = "Agrícola"
    case capa3           = "Capa 3"

    var id: String { rawValue }
}

final class AppModel: ObservableObject {
    
    
    @Published var selectedName: String? = nil
    
    @Published var showLimitrofes: Bool = false
    
    @Published var showMejoras: Bool = false
    
    @Published var showRiesgos: Bool = false
    
    @Published var showPanorama360: Bool = false
    
    @Published var worldSpaceOpen: Bool = false
    
    @Published var showCatastralidad: Bool = false
    
    @Published var mainWindowOpen = false
    
    @Published var lockWorldSpace = true
    
    @Published var isShuttingDown = false
    
    @Published var layersWindowOpen = false
        @Published var activeLayer: LayerKind? = nil
}
