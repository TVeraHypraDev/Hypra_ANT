//
//  LayersView.swift
//  Hypra_ANT
//
//  Created by Tomás David Vera Molano on 10/11/25.
//

import SwiftUI

struct LayersView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismissWindow) private var dismissWindow

    private var available: [LayerKind] {
        guard let sel = appModel.selectedName,
              let dict = overlayConfigBySelection[sel]?.layers
        else { return [] }
        return Array(dict.keys)
    }

    private let layerOrder: [LayerKind] = [.reservaForestal, .agricola, .capa3]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Capas").font(.title2.bold())

            
            VStack(spacing: 12) {
                
                let items = layerOrder.filter { available.contains($0) }
                ForEach(items) { kind in
                    layerButton(kind)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Text("Solo puede haber una capa activa a la vez.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Button {
                    dismissWindow(id: "layers")
                    appModel.layersWindowOpen = false
                } label: {
                    Label("Cerrar", systemImage: "xmark.circle.fill")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .frame(minWidth: 360, idealWidth: 420)
    }

    @ViewBuilder
    private func layerButton(_ kind: LayerKind) -> some View {
        let enabled = available.contains(kind)
        let selected = appModel.activeLayer == kind

        Button {
            
            appModel.activeLayer = selected ? nil : kind
        } label: {
            HStack {
                Image(systemName: selected ? "checkmark.circle.fill" : "square")
                Text(kind.rawValue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .tint(selected ? .blue : .accentColor)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
    }
}
