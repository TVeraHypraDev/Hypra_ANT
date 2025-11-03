import Combine
import Foundation
import RealityKit
import SwiftUI

final class AppModel: ObservableObject {
    
    
    @Published var selectedName: String? = nil
    
    @Published var showLimitrofes: Bool = false
    
    @Published var showMejoras: Bool = false
    
    @Published var showRiesgos: Bool = false
    
    @Published var worldSpaceOpen: Bool = false
    
    @Published var showCatastralidad: Bool = false
    
    @Published var mainWindowOpen = false
    
    @Published var lockWorldSpace = true
    
    // Para evitar reabrir durante un apagado explícito (si lo usas)
    @Published var isShuttingDown = false
}
