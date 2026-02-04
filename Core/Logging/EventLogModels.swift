// EventLogModels define log entry types used throughout SensorGuardian.
// Created by Atakan Özcan on 30.01.2026.

import Foundation

enum EventKind: String {
    case detection = "DETECTION"
    case action = "ACTION"
}

struct EventLogEntry: Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let kind: EventKind
    let sensorID: String
    let message: String
    let pRaw: Double
}
