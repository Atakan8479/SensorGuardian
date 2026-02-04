// CSVLoader reads bundled CSV datasets into SensorReading models.
// Created by Atakan Özcan on 28.01.2026.

import Foundation

final class CSVLoader {

    enum CSVError: Error {
        case missingResource
        case invalidData
        case empty
    }

    func load(resourceName: String) throws -> [SensorReading] {
        print("### CSVLoader v2 ACTIVE (uses SensorReadingMapper) ###")

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "csv") else {
            print("❌ [CSV] Bundle url not found for \(resourceName).csv")
            throw CSVError.missingResource
        }

        let data = try Data(contentsOf: url)
        guard !data.isEmpty else { throw CSVError.empty }

        guard let text = String(data: data, encoding: .utf8) else {
            throw CSVError.invalidData
        }

        var lines = text.split(whereSeparator: \.isNewline).map(String.init)
        guard lines.count >= 2 else { throw CSVError.empty }

        let header = lines.removeFirst()
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

        print("📦 [CSV] loaded \(url.lastPathComponent) | rows=\(lines.count) bad=0")
        print("📦 [CSV] header=\(header)")

        var out: [SensorReading] = []
        out.reserveCapacity(lines.count)

        var bad = 0

        for line in lines {
            let cols = line.split(separator: ",", omittingEmptySubsequences: false).map { String($0) }
            if cols.count != header.count {
                bad += 1
                continue
            }

            if let reading = SensorReadingMapper.map(header: header, row: cols) {
                out.append(reading)
            } else {
                bad += 1
            }
        }

        print("📦 [CSV] parsed rows=\(out.count) bad=\(bad)")
        print("📦 [CSV] sample sensorIDs:", out.prefix(5).map { $0.sensorID })

        return out
    }
}
