// DashboardGridView lays out sensor cards in a responsive grid.
// Created by Atakan Özcan on 28.01.2026.

import SwiftUI

struct DashboardGridView: View {
    let sensors: [DashboardSensor]
    let onQuarantine: (String) -> Void

    private let cols = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: cols, spacing: 12) {
                ForEach(sensors) { s in
                    SensorCardView(sensor: s, onQuarantine: onQuarantine)
                }
            }
            .padding(.top, 8)
        }
    }
}
