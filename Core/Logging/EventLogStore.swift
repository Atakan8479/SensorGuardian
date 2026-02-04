// EventLogStore keeps an in-memory log of recent events for UI consumption.
// Created by Atakan Özcan on 28.01.2026.

import Foundation

@MainActor
final class EventLogStore: ObservableObject {
    @Published private(set) var entries: [EventLogEntry] = []

    // Suppress duplicate entries with the same kind, sensor, and message for 6 seconds
    private var lastKeyTime: [String: Date] = [:]

    func add(kind: EventKind, sensorID: String, message: String, pRaw: Double) {
        let now = Date()
        let key = "\(kind.rawValue)|\(sensorID)|\(message)"

        if let t = lastKeyTime[key], now.timeIntervalSince(t) < 6 {
            return
        }
        lastKeyTime[key] = now

        let e = EventLogEntry(id: UUID(), timestamp: now, kind: kind, sensorID: sensorID, message: message, pRaw: pRaw)
        entries.insert(e, at: 0)
    }
}
