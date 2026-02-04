// SensorReadingMapper converts CSV rows into strongly typed SensorReading values.
// Created by Atakan Özcan on 28.01.2026.

import Foundation

enum SensorReadingMapper {

    static func map(header: [String], row: [String]) -> SensorReading? {
        guard header.count == row.count else { return nil }

        // Build a case-insensitive lookup from column name to index
        var idx: [String: Int] = [:]
        idx.reserveCapacity(header.count)

        for (i, h) in header.enumerated() {
            idx[h.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()] = i
        }

        func str(_ key: String) -> String? {
            guard let i = idx[key.lowercased()], i < row.count else { return nil }
            let v = row[i].trimmingCharacters(in: .whitespacesAndNewlines)
            return v.isEmpty ? nil : v
        }

        func dbl(_ key: String, default d: Double = 0.0) -> Double {
            guard let s = str(key) else { return d }
            let cleaned = s.replacingOccurrences(of: ",", with: ".")
            return Double(cleaned) ?? d
        }

        func intOpt(_ key: String) -> Int? {
            guard let s = str(key) else { return nil }
            return Int(s)
        }

        // Accept common identifiers used across datasets
        let sensorID =
            str("sensorid")
            ?? str("ip_address")
            ?? str("node_id")
            ?? "unknown"

        return SensorReading(
            sensorID: sensorID,
            packetRate: dbl("packet_rate"),
            packetDuplicationRate: dbl("packet_duplication_rate"),
            signalStrength: dbl("signal_strength"),
            snr: dbl("snr"),
            batteryLevel: dbl("battery_level"),
            numberOfNeighbors: dbl("number_of_neighbors"),
            routeRequestFrequency: dbl("route_request_frequency"),
            routeReplyFrequency: dbl("route_reply_frequency"),
            dataTransmissionFrequency: dbl("data_transmission_frequency"),
            dataReceptionFrequency: dbl("data_reception_frequency"),
            cpuUsage: dbl("cpu_usage"),
            memoryUsage: dbl("memory_usage"),
            bandwidth: dbl("bandwidth"),
            isMaliciousLabel: intOpt("is_malicious")
        )
    }
}
