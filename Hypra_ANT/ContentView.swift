//
//  ContentView.swift
//  Hypra_ANT
//
//  Created by Tomás David Vera Molano on 10/10/25.
//

import SwiftUI
import RealityKit

struct ContentView: View {

    var body: some View {
        VStack {
            ToggleImmersiveSpaceButton()
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
