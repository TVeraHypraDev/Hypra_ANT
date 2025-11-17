import Combine
import Foundation
import RealityKit
import SwiftUI

enum LayerKind: String, CaseIterable, Identifiable {
    /* Los tipos de capas son :
     X Zonas Etnicas
     X Política
     Uso de Suelo: X Agricultura, X Ganadería
     X Uso de subsuelo
     X Ambiental
     X Agua
     X Reserva Forestal
     */
    
    case reservaForestal = "Reserva Forestal"
    case agricola        = "Agrícola"
    case ganaderia           = "Ganadería"
    case zonasEtnicas = "Zonas Étnicas"
    case politica        = "Política"
    case usoSubsuelo          = "Uso del Subsuelo"
    case ambiental = "Ambiental"
    case agua        = "Agua"

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
