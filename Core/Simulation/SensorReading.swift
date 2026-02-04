// SensorReading represents a single row from the simulated dataset.
// Created by Atakan Özcan on 28.01.2026.

import Foundation

struct SensorReading: Equatable {
    let sensorID: String

    let packetRate: Double
    let packetDuplicationRate: Double
    let signalStrength: Double
    let snr: Double
    let batteryLevel: Double
    let numberOfNeighbors: Double
    let routeRequestFrequency: Double
    let routeReplyFrequency: Double
    let dataTransmissionFrequency: Double
    let dataReceptionFrequency: Double
    let cpuUsage: Double
    let memoryUsage: Double
    let bandwidth: Double

    // Optional ground-truth label from the dataset
    let isMaliciousLabel: Int?
}
