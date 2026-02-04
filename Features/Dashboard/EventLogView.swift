// EventLogView lists recent detection and action events.
// Created by Atakan Özcan on 28.01.2026.

import SwiftUI

struct EventLogView: View {
    @ObservedObject var log: EventLogStore

    var body: some View {
        NavigationView {
            List {
                ForEach(log.entries) { e in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(e.kind.rawValue)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(e.kind == .detection ? .orange : .blue)
                            Spacer()
                            Text(time(e.timestamp))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(e.sensorID).font(.headline)
                        Text(e.message).font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Event Log")
        }
    }

    private func time(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: d)
    }
}
