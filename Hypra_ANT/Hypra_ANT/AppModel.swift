import Combine
import Foundation
import RealityKit
import SwiftUI

final class AppModel: ObservableObject {
    
    
    @Published var selectedName: String? = nil

    @Published var showLimitrofes: Bool = false
    
    @Published var showMejoras: Bool = false
    
    @Published var worldSpaceOpen: Bool = false
    
    

    // Riesgos
    @Published var showRiesgos: Bool = false
    
    // Catastralidad
    @Published var showCatastralidad: Bool = false
    
    @Published var mainWindowOpen = false
}
