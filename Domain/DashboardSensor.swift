// DashboardSensor holds UI-facing state for a single sensor.
// Created by Atakan Özcan on 28.01.2026.

import Foundation

struct DashboardSensor: Identifiable {
    let id = UUID()

    let sensorID: String
    var pRaw: Double
    var state: SensorGuardianState
    var lastUpdated: Date

    // Explanations from the model or rule engine
    var reasons: [String]

    // Indicates whether the user manually quarantined this sensor
    var isUserQuarantined: Bool
}
