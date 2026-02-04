// SensorGuardianModelAdapter wraps the Core ML model and handles preprocessing.
// Created by Atakan Özcan on 28.01.2026.

import Foundation
import CoreML

final class SensorGuardianModelAdapter {

    private let DEBUG_ML = true

    private let model: SensorGuardian_fp16

    private let requiredInputs: [String]
    private let inputSpecs: [String: (type: MLFeatureType, shape: [Int], dataType: MLMultiArrayDataType?)]

    private let preprocessor = SensorPreprocessor(bundleFile: "preprocess_params", ext: "json")

    private let outputKey = "maliciousProbabilityRaw"

    enum OutputInterpretation {
        case auto          // Interpret raw [0,1] as probability; otherwise apply sigmoid
        case neverSigmoid
        case alwaysSigmoid
    }

    // Default behavior uses auto interpretation
    private let outputMode: OutputInterpretation = .auto

    init() {
        do {
            let cfg = MLModelConfiguration()
            self.model = try SensorGuardian_fp16(configuration: cfg)
            print("✅ [ML] Model loaded: SensorGuardian_fp16(configuration:)")
        } catch {
            fatalError("❌ [ML] Model load failed: \(error)")
        }

        let inDesc = model.model.modelDescription.inputDescriptionsByName
        self.requiredInputs = inDesc.keys.sorted()

        var tmp: [String: (type: MLFeatureType, shape: [Int], dataType: MLMultiArrayDataType?)] = [:]
        for (name, desc) in inDesc {
            if desc.type == .multiArray, let c = desc.multiArrayConstraint {
                let shape = c.shape.map { Int(truncating: $0) }
                tmp[name] = (type: desc.type, shape: shape, dataType: c.dataType)
            } else {
                tmp[name] = (type: desc.type, shape: [], dataType: nil)
            }
        }
        self.inputSpecs = tmp

        if DEBUG_ML {
            print("✅ [ML] Required inputs:", requiredInputs)
            for k in requiredInputs {
                if let spec = inputSpecs[k] {
                    if spec.type == .multiArray {
                        print("   - \(k) type=\(spec.type.rawValue) shape=\(spec.shape) dtype=\(spec.dataType?.rawValue ?? -1)")
                    } else {
                        print("   - \(k) type=\(spec.type.rawValue)")
                    }
                }
            }
            print("### ModelAdapter ACTIVE ###")
        }

        if DEBUG_ML {
            selfTest()
        }
    }

    // Maintain legacy API used by DashboardViewModel
    func predictRawProbability(reading: SensorReading) -> Double {
        predictProbability(reading: reading)
    }

    func predictProbability(reading: SensorReading) -> Double {
        do {
            let rawValues: [String: Double] = [
                "Bandwidth": reading.bandwidth,
                "Battery_Level": reading.batteryLevel,
                "CPU_Usage": reading.cpuUsage,
                "Data_Reception_Frequency": reading.dataReceptionFrequency,
                "Data_Transmission_Frequency": reading.dataTransmissionFrequency,
                "Memory_Usage": reading.memoryUsage,
                "Number_of_Neighbors": reading.numberOfNeighbors,
                "Packet_Duplication_Rate": reading.packetDuplicationRate,
                "Packet_Rate": reading.packetRate,
                "Route_Reply_Frequency": reading.routeReplyFrequency,
                "Route_Request_Frequency": reading.routeRequestFrequency,
                "SNR": reading.snr,
                "Signal_Strength": reading.signalStrength
            ]

            var dict: [String: MLFeatureValue] = [:]
            dict.reserveCapacity(requiredInputs.count)

            if DEBUG_ML {
                print("🔧 [ML] Input snapshot (raw → transformed):")
                for key in requiredInputs {
                    let r = rawValues[key] ?? 0.0
                    let t = preprocessor.transform(r, key: key)
                    print(String(format: "   - %@: %.6f → %.6f", key, r, t))
                }
            }

            for key in requiredInputs {
                let r = rawValues[key] ?? 0.0
                let v = preprocessor.transform(r, key: key)

                guard let spec = inputSpecs[key] else {
                    dict[key] = MLFeatureValue(double: v)
                    continue
                }

                switch spec.type {
                case .multiArray:
                    let shape = (spec.shape.isEmpty ? [1] : spec.shape)
                    let dt = spec.dataType ?? .float16
                    let arr = try MLMultiArray(shape: shape as [NSNumber], dataType: dt)
                    if arr.count > 0 {
                        // Use NSNumber(Double) to avoid Float rounding before casting
                        arr[0] = NSNumber(value: v)
                    }
                    dict[key] = MLFeatureValue(multiArray: arr)

                case .double:
                    dict[key] = MLFeatureValue(double: v)

                case .int64:
                    dict[key] = MLFeatureValue(int64: Int64(v))

                default:
                    dict[key] = MLFeatureValue(double: v)
                }
            }

            let provider = try MLDictionaryFeatureProvider(dictionary: dict)
            let out = try model.model.prediction(from: provider)

            if DEBUG_ML {
                print("✅ [ML] output features:", out.featureNames.sorted())
            }

            let rawOut = extractDouble(out, key: outputKey)

            if DEBUG_ML {
                print(String(format: "✅ [ML] %@ = %.12f", outputKey, rawOut))
            }

            let p = interpret(rawOut)

            if DEBUG_ML {
                print(String(format: "✅ [ML] interpreted probability = %.12f", p))
            }

            return clamp01(p)

        } catch {
            print("❌ [ML] prediction failed:", error.localizedDescription)
            return 0.0
        }
    }

    // MARK: - Self Test (detect constant model)

    private func selfTest() {
        do {
            print("🧪 [ML] selfTest() start")

            let out1 = try runWithRandomInputs(seed: 1)
            let out2 = try runWithRandomInputs(seed: 2)

            print(String(format: "🧪 [ML] selfTest rawOut #1 = %.12f", out1))
            print(String(format: "🧪 [ML] selfTest rawOut #2 = %.12f", out2))

            if out1 == 0.0 && out2 == 0.0 {
                print("🚨 [ML] selfTest: output is 0 for different random inputs -> model may be constant / bad export / wrong file")
            } else if abs(out1 - out2) < 1e-12 {
                print("⚠️ [ML] selfTest: output does not change -> model may be constant")
            } else {
                print("✅ [ML] selfTest: model output changes with input (good)")
            }

        } catch {
            print("❌ [ML] selfTest failed:", error.localizedDescription)
        }
    }

    private func runWithRandomInputs(seed: Int) throws -> Double {
        var rng = SeededRNG(seed: UInt64(seed))

        var dict: [String: MLFeatureValue] = [:]
        dict.reserveCapacity(requiredInputs.count)

        for key in requiredInputs {
            let r = rng.nextDouble() * 2.0 - 1.0  // Range [-1, 1] to exercise preprocessing
            let v = preprocessor.transform(r, key: key)

            if let spec = inputSpecs[key], spec.type == .multiArray {
                let shape = (spec.shape.isEmpty ? [1] : spec.shape)
                let dt = spec.dataType ?? .float16
                let arr = try MLMultiArray(shape: shape as [NSNumber], dataType: dt)
                if arr.count > 0 { arr[0] = NSNumber(value: v) }
                dict[key] = MLFeatureValue(multiArray: arr)
            } else {
                dict[key] = MLFeatureValue(double: v)
            }
        }

        let provider = try MLDictionaryFeatureProvider(dictionary: dict)
        let out = try model.model.prediction(from: provider)
        return extractDouble(out, key: outputKey)
    }

    // MARK: - Helpers

    private func extractDouble(_ out: MLFeatureProvider, key: String) -> Double {
        guard let fv = out.featureValue(for: key) else { return 0.0 }
        if fv.type == .double { return fv.doubleValue }
        if fv.type == .multiArray, let a = fv.multiArrayValue, a.count > 0 { return a[0].doubleValue }
        return 0.0
    }

    private func interpret(_ rawOut: Double) -> Double {
        switch outputMode {
        case .neverSigmoid:
            return rawOut
        case .alwaysSigmoid:
            return sigmoid(rawOut)
        case .auto:
            if rawOut >= 0.0 && rawOut <= 1.0 { return rawOut }
            return sigmoid(rawOut)
        }
    }

    private func sigmoid(_ x: Double) -> Double {
        if x.isNaN || x.isInfinite { return 0.0 }
        if x >= 0 {
            let z = exp(-x)
            return 1.0 / (1.0 + z)
        } else {
            let z = exp(x)
            return z / (1.0 + z)
        }
    }

    private func clamp01(_ x: Double) -> Double {
        if x.isNaN || x.isInfinite { return 0.0 }
        if x < 0 { return 0.0 }
        if x > 1 { return 1.0 }
        return x
    }
}

// Small deterministic RNG (no external dependencies or global state)
private struct SeededRNG {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 1 : seed }

    mutating func nextUInt64() -> UInt64 {
        // xorshift64*
        var x = state
        x ^= x >> 12
        x ^= x << 25
        x ^= x >> 27
        state = x
        return x &* 2685821657736338717
    }

    mutating func nextDouble() -> Double {
        let u = nextUInt64() >> 11
        return Double(u) / Double(1 << 53)
    }
}
