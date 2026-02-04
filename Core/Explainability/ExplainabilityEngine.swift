// ExplainabilityEngine surfaces human-readable reasons for model decisions.
// Created by Atakan Özcan on 28.01.2026.

import Foundation

struct ExplainabilityEngine {

    struct Rule: Codable {
        let feature: String?
        let direction: String?     // Allowed values: "high" or "low"
        let threshold: Double?     // Optional; rules still load when omitted
        let message: String?       // Optional; a fallback description is generated when absent
        let weight: Double?
    }

    private let rules: [Rule]

    private init(rules: [Rule]) {
        self.rules = rules
    }

    static func fromBundleJSON(resourceName: String) -> ExplainabilityEngine {
        do {
            guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
                print("⚠️ [XAI] \(resourceName).json not found in bundle")
                return .emptyFallback()
            }

            let data = try Data(contentsOf: url)
            print("✅ [XAI] loaded \(resourceName).json bytes=\(data.count) url=\(url)")
            if data.isEmpty { return .emptyFallback() }

            return try ExplainabilityEngine(data: data)
        } catch {
            print("⚠️ [XAI] \(resourceName) load failed:", error)
            return .emptyFallback()
        }
    }

    init(data: Data) throws {
        if let arr = try? JSONDecoder().decode([Rule].self, from: data) {
            self.rules = arr
            return
        }
        struct Wrapped: Codable { let rules: [Rule] }
        let wrapped = try JSONDecoder().decode(Wrapped.self, from: data)
        self.rules = wrapped.rules
    }

    static func emptyFallback() -> ExplainabilityEngine {
        ExplainabilityEngine(rules: [])
    }

    func topReasons(reading: SensorReading, state: SensorGuardianState, topK: Int) -> [String] {
        guard state != .normal else { return [] }
        guard !rules.isEmpty else { return [] }

        var hits: [(String, Double)] = []

        for r in rules {
            guard
                let feature = r.feature,
                let dir = r.direction?.lowercased(),
                let thr = r.threshold
            else { continue }

            guard let v = reading.value(forFeatureName: feature) else { continue }

            let matched: Bool
            if dir == "high" { matched = v >= thr }
            else if dir == "low" { matched = v <= thr }
            else { matched = false }

            if matched {
                let msg = r.message ?? "\(feature) \(dir) (thr=\(thr))"
                hits.append((msg, r.weight ?? 1.0))
            }
        }

        hits.sort { $0.1 > $1.1 }
        return Array(hits.prefix(max(0, topK))).map { $0.0 }
    }
}

private extension SensorReading {
    func value(forFeatureName name: String) -> Double? {
        switch name {
        case "Packet_Rate": return packetRate
        case "Packet_Duplication_Rate": return packetDuplicationRate
        case "Signal_Strength": return signalStrength
        case "SNR": return snr
        case "Battery_Level": return batteryLevel
        case "Number_of_Neighbors": return numberOfNeighbors
        case "Route_Request_Frequency": return routeRequestFrequency
        case "Route_Reply_Frequency": return routeReplyFrequency
        case "Data_Transmission_Frequency": return dataTransmissionFrequency
        case "Data_Reception_Frequency": return dataReceptionFrequency
        case "CPU_Usage": return cpuUsage
        case "Memory_Usage": return memoryUsage
        case "Bandwidth": return bandwidth
        default: return nil
        }
    }
}
