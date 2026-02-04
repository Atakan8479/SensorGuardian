// SensorSimulator streams dataset rows at a fixed cadence to mimic live sensors.
// Created by Atakan Özcan on 28.01.2026.

import Foundation

final class SensorSimulator {

    private let loader = CSVLoader()
    private var rows: [SensorReading] = []
    private var idx: Int = 0

    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue.main

    var isRunning: Bool { timer != nil }
    var totalRows: Int { rows.count }

    func load(resourceName: String) throws {
        rows = try loader.load(resourceName: resourceName)
        idx = 0
        print("✅ [SIM] dataset ready | totalRows=\(rows.count)")
    }

    func start(tickSeconds: Double, onTick: @escaping (SensorReading) -> Void) {
        guard timer == nil else { return }
        guard !rows.isEmpty else { return }

        print("▶️ [SIM] streaming started (every \(tickSeconds)s)")

        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now(), repeating: tickSeconds)

        t.setEventHandler { [weak self] in
            guard let self else { return }
            guard !self.rows.isEmpty else { return }

            if self.idx >= self.rows.count { self.idx = 0 }
            let reading = self.rows[self.idx]
            self.idx += 1

            onTick(reading)
        }

        timer = t
        t.resume()
    }

    func stop() {
        timer?.cancel()
        timer = nil
        print("🛑 [SIM] streaming stopped")
    }
}
