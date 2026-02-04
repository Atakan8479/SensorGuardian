// SensorGuardianState enumerates the possible health states for a sensor.
// Created by Atakan Özcan on 28.01.2026.

import Foundation

enum SensorGuardianState: String, Equatable {
    case normal = "NORMAL"
    case warning = "WARNING"
    case quarantine = "QUARANTINE"
}
