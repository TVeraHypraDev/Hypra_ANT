import Combine
import Foundation
import RealityKit
import SwiftUI

final class AppModel: ObservableObject {
    @Published var selectedName: String? = nil

    @Published var showLimitrofes: Bool = false
    // Dimensiones del cubo (puedes cambiarlas en código)
    @Published var limBoxWidth: Float = 4.5
    @Published var limBoxHeight: Float = 0.4
    @Published var limBoxDepth: Float = 5.0

    // Riesgos
    @Published var showRiesgos: Bool = false
    @Published var riskSphereRadius: Float = 0.6
    
    // Catastralidad
    @Published var showCatastralidad: Bool = false
    @Published var catBoxWidth:  Float = 0.5
    @Published var catBoxHeight: Float = 0.5
    @Published var catBoxDepth:  Float = 5.0

}
