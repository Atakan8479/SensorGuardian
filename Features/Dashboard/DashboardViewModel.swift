// DashboardViewModel drives the dashboard UI, streaming data and deriving state.
// Created by Atakan Özcan on 28.01.2026.

import Foundation

// MARK: - Background worker (executes off the MainActor)
actor InferenceWorker {

    private let modelAdapter: SensorGuardianModelAdapter
    private let explainEngine: ExplainabilityEngine

    private let warnLow: Double
    private let quarantineThr: Double

    init(
        modelAdapter: SensorGuardianModelAdapter,
        explainEngine: ExplainabilityEngine,
        warnLow: Double,
        quarantineThr: Double
    ) {
        self.modelAdapter = modelAdapter
        self.explainEngine = explainEngine
        self.warnLow = warnLow
        self.quarantineThr = quarantineThr
    }

    func evaluate(reading: SensorReading) -> (pRaw: Double, state: SensorGuardianState, reasons: [String]) {
        let pRaw = modelAdapter.predictRawProbability(reading: reading)

        let state: SensorGuardianState
        if pRaw >= quarantineThr {
            state = .quarantine
        } else if pRaw >= warnLow {
            state = .warning
        } else {
            state = .normal
        }

        // Compute explanations only when the state is non-normal
        let reasons: [String]
        if state == .normal {
            reasons = []
        } else {
            reasons = explainEngine.topReasons(reading: reading, state: state, topK: 3)
        }

        return (pRaw, state, reasons)
    }
}

@MainActor
final class DashboardViewModel: ObservableObject {

    // MARK: - UI Bindings

    @Published var sensors: [DashboardSensor] = []
    @Published var isStreaming: Bool = false
    @Published var rowsProcessed: Int = 0
    @Published var totalUniqueSensors: Int = 0

    private var seenIDs = Set<String>()
    private var labelMalCount = 0

    // Cache to locate sensors in O(1) time
    private var sensorIndexByID: [String: Int] = [:]

    // Shared event log store exposed to the UI
    let logStore = EventLogStore()

    // MARK: - Core

    private let simulator = SensorSimulator()
    private let explainEngine: ExplainabilityEngine
    private let worker: InferenceWorker

    // Policy thresholds
    private let warnLow: Double = 0.10
    private let quarantineThr: Double = 0.18

    // Dataset file base name (without extension)
    private let datasetResourceName = "SensorNetGuard_full"

    // Track last known model state to avoid repetitive logging
    private var lastModelState: [String: SensorGuardianState] = [:]

    // Debug: print only the first sample to limit console noise
    private var didPrintFirstSample = false

    // MARK: - Init

    init() {
        // Bundle diagnostics (console only)
        print("=== DashboardViewModel INIT ===")
        print("JSON URL =", Bundle.main.url(forResource: "explain_rules", withExtension: "json") as Any)
        print("CSV  URL =", Bundle.main.url(forResource: "SensorNetGuard_full", withExtension: "csv") as Any)

        let allJson = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
        let allCsv  = Bundle.main.urls(forResourcesWithExtension: "csv", subdirectory: nil) ?? []
        print("Bundle JSON files:", allJson.map { $0.lastPathComponent })
        print("Bundle CSV files:",  allCsv.map  { $0.lastPathComponent })

        // Load explainability rules; fall back to an empty engine if unavailable
        let engine = ExplainabilityEngine.fromBundleJSON(resourceName: "explain_rules")
        self.explainEngine = engine

        // Worker owns ML + XAI so inference stays off the MainActor
        self.worker = InferenceWorker(
            modelAdapter: SensorGuardianModelAdapter(),
            explainEngine: engine,
            warnLow: warnLow,
            quarantineThr: quarantineThr
        )
    }

    // MARK: - Lifecycle

    func onAppear() async {
        // Reserved for future view lifecycle hooks
    }

    // MARK: - Buttons invoked by UI bindings

    func startStreaming() {
        start()
    }

    func stopStreaming() {
        stop()
    }

    // MARK: - Actions

    func quarantine(sensorID: String) {
        guard let i = sensorIndexByID[sensorID] else { return }
        sensors[i].isUserQuarantined = true

        let msg = "User quarantined this sensor."
        logStore.add(kind: .action, sensorID: sensorID, message: msg, pRaw: sensors[i].pRaw)
        print("🧯 [ACTION] \(sensorID) user quarantined")

        // Re-sort when user quarantine status changes
        resortSensorsForUI()
    }

    // MARK: - Streaming

    func start() {
        if isStreaming { return }

        do {
            try simulator.load(resourceName: datasetResourceName)
            print("✅ [SIM] loaded dataset \(datasetResourceName)")
        } catch {
            print("❌ [SIM] load failed:", error.localizedDescription)
            return
        }

        seenIDs.removeAll()
        totalUniqueSensors = 0
        rowsProcessed = 0
        labelMalCount = 0
        didPrintFirstSample = false

        sensors.removeAll(keepingCapacity: true)
        sensorIndexByID.removeAll(keepingCapacity: true)
        lastModelState.removeAll(keepingCapacity: true)

        isStreaming = true
        print("✅ [SIM] started stream")

        simulator.start(tickSeconds: 0.6) { [weak self] reading in
            guard let self else { return }
            Task { [weak self] in
                guard let self else { return }
                await self.processAsync(reading: reading)
            }
        }
    }

    func stop() {
        simulator.stop()
        isStreaming = false
        print("🛑 [SIM] stopped stream")
    }

    // MARK: - Processing (async: inference off-main, UI update on-main)

    private func processAsync(reading: SensorReading) async {
        rowsProcessed += 1

        if reading.isMaliciousLabel == 1 { labelMalCount += 1 }
        if rowsProcessed % 200 == 0 {
            print("🧪 [DBG] labelMalCount(first \(rowsProcessed)) = \(labelMalCount)")
        }

        if !didPrintFirstSample {
            didPrintFirstSample = true
            print("🔎 [DBG] First reading sample:")
            print("sensorID=\(reading.sensorID) label=\(reading.isMaliciousLabel as Any)")
            print("Packet_Rate=\(reading.packetRate)")
            print("Packet_Duplication_Rate=\(reading.packetDuplicationRate)")
            print("Signal_Strength=\(reading.signalStrength)")
            print("SNR=\(reading.snr)")
            print("Battery_Level=\(reading.batteryLevel)")
            print("Number_of_Neighbors=\(reading.numberOfNeighbors)")
            print("Route_Request_Frequency=\(reading.routeRequestFrequency)")
            print("Route_Reply_Frequency=\(reading.routeReplyFrequency)")
            print("Data_Transmission_Frequency=\(reading.dataTransmissionFrequency)")
            print("Data_Reception_Frequency=\(reading.dataReceptionFrequency)")
            print("CPU_Usage=\(reading.cpuUsage)")
            print("Memory_Usage=\(reading.memoryUsage)")
            print("Bandwidth=\(reading.bandwidth)")
        }

        seenIDs.insert(reading.sensorID)
        totalUniqueSensors = seenIDs.count

        // Run inference off the main actor
        let result = await worker.evaluate(reading: reading)

        // Perform minimal work on the main actor: update state and order if needed
        upsertSensor(
            reading: reading,
            state: result.state,
            pRaw: result.pRaw,
            reasons: result.reasons
        )
    }

    // MARK: - Upsert

    private func upsertSensor(reading: SensorReading, state: SensorGuardianState, pRaw: Double, reasons: [String]) {
        if let i = sensorIndexByID[reading.sensorID] {
            let prevState = sensors[i].state
            let prevUserQ = sensors[i].isUserQuarantined

            sensors[i].state = state
            sensors[i].pRaw = pRaw
            sensors[i].lastUpdated = Date()
            sensors[i].reasons = reasons

            logIfStateChanged(sensorID: reading.sensorID, newState: state, pRaw: pRaw, reasons: reasons)

            // Resort only when the state bucket or user quarantine flag changes
            if prevState != state || prevUserQ != sensors[i].isUserQuarantined {
                resortSensorsForUI()
            }
            return
        }

        // Insert a new sensor record
        let s = DashboardSensor(
            sensorID: reading.sensorID,
            pRaw: pRaw,
            state: state,
            lastUpdated: Date(),
            reasons: reasons,
            isUserQuarantined: false
        )

        sensors.append(s)
        sensorIndexByID[reading.sensorID] = sensors.count - 1

        // Place the new sensor correctly with a single sort
        resortSensorsForUI()

        logIfStateChanged(sensorID: reading.sensorID, newState: state, pRaw: pRaw, reasons: reasons)
    }

    // MARK: - Logging

    private func logIfStateChanged(sensorID: String, newState: SensorGuardianState, pRaw: Double, reasons: [String]) {
        let prev = lastModelState[sensorID]
        if prev == nil || prev! != newState {
            lastModelState[sensorID] = newState

            if newState == .normal {
                if prev != nil {
                    logStore.add(
                        kind: .detection,
                        sensorID: sensorID,
                        message: "Recovered to NORMAL.",
                        pRaw: pRaw
                    )
                }
            } else {
                let reasonText = reasons.isEmpty ? "" : " " + reasons.joined(separator: " • ")
                logStore.add(
                    kind: .detection,
                    sensorID: sensorID,
                    message: "Detected \(newState.rawValue) (p=\(String(format: "%.3f", pRaw))).\(reasonText)",
                    pRaw: pRaw
                )
            }

            // Log to console only when the state changes
            print("🚦 [STATE] \(sensorID) -> \(newState.rawValue) p=\(String(format: "%.4f", pRaw))")
        }
    }

    // MARK: - Ordering helpers (no UI side effects)

    private func priority(of state: SensorGuardianState) -> Int {
        switch state {
        case .quarantine: return 0
        case .warning:    return 1
        case .normal:     return 2
        }
    }

    private func resortSensorsForUI() {
        sensors.sort { a, b in
            // 1) User-quarantined sensors always appear first
            if a.isUserQuarantined != b.isUserQuarantined {
                return a.isUserQuarantined && !b.isUserQuarantined
            }

            // 2) Next, order by model-assigned severity
            let pa = priority(of: a.state)
            let pb = priority(of: b.state)
            if pa != pb { return pa < pb }

            // 3) Within the same bucket, show most recent first
            return a.lastUpdated > b.lastUpdated
        }

        // Refresh the index map after sorting updates positions
        sensorIndexByID.removeAll(keepingCapacity: true)
        for (idx, s) in sensors.enumerated() {
            sensorIndexByID[s.sensorID] = idx
        }
    }
}
