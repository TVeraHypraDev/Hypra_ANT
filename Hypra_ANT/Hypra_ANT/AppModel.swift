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

    // (futuros: catastralidad / riesgos)
    @Published var showCatastralidad: Bool = false
    @Published var showRiesgos: Bool = false
}
