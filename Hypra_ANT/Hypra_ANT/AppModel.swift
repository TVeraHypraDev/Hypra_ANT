import Foundation
import RealityKit
import SwiftUI
import Combine

final class AppModel: ObservableObject {
    @Published var selectedName: String? = nil
}
