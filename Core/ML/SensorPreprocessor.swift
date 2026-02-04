// SensorPreprocessor applies the same preprocessing used during model training.
// Created by Atakan Özcan on 28.01.2026.

import Foundation

final class SensorPreprocessor {

    enum Method: String {
        case none, standard
    }

    private(set) var method: Method = .none

    private var scalerMean: [String: Double] = [:]
    private var scalerScale: [String: Double] = [:]
    private var imputerMedian: [String: Double] = [:]
    private var clipP01: [String: Double] = [:]
    private var clipP99: [String: Double] = [:]
    private var featureOrder: [String] = []

    private let DEBUG = true

    init(bundleFile: String = "preprocess_params", ext: String = "json") {
        load(bundleFile: bundleFile, ext: ext)
    }

    // MARK: - Main transform

    func transform(_ xIn: Double, key: String) -> Double {
        // Step 1: Impute invalid numeric values
        var x = xIn
        if x.isNaN || x.isInfinite {
            x = imputerMedian[key] ?? 0.0
        }

        // Step 2: Clip to the p01–p99 range when bounds exist
        if let lo = clipP01[key], let hi = clipP99[key] {
            if x < lo { x = lo }
            if x > hi { x = hi }
        }

        // Step 3: Standardize according to the configured method
        switch method {
        case .none:
            return x
        case .standard:
            let m = scalerMean[key] ?? 0.0
            let s = scalerScale[key] ?? 1.0
            let denom = (abs(s) < 1e-12) ? 1.0 : s
            return (x - m) / denom
        }
    }

    // Optional: expose order for debugging or vectorized outputs
    func orderedKeys() -> [String] { featureOrder }

    // MARK: - Loader (reads preprocess_params.json)

    private func load(bundleFile: String, ext: String) {
        guard let url = Bundle.main.url(forResource: bundleFile, withExtension: ext) else {
            if DEBUG { print("⚠️ [PRE] preprocess_params.json not found -> method=none") }
            return
        }
        guard let data = try? Data(contentsOf: url) else {
            if DEBUG { print("⚠️ [PRE] failed to read preprocess_params.json -> method=none") }
            return
        }
        guard let obj = try? JSONSerialization.jsonObject(with: data, options: []),
              let root = obj as? [String: Any] else {
            if DEBUG { print("⚠️ [PRE] preprocess_params.json is not a dict -> method=none") }
            return
        }

        if DEBUG {
            print("✅ [PRE] Loaded preprocess_params.json")
            print("✅ [PRE] top-level keys =", Array(root.keys).sorted())
        }

        // feature_order
        if let arr = root["feature_order"] as? [String] {
            featureOrder = arr
        }

        // imputer_median
        if let d = root["imputer_median"] as? [String: Any] {
            imputerMedian = toDoubleMap(d)
        }

        // scaler_mean / scaler_scale (StandardScaler)
        if let d = root["scaler_mean"] as? [String: Any] {
            scalerMean = toDoubleMap(d)
        }
        if let d = root["scaler_scale"] as? [String: Any] {
            scalerScale = toDoubleMap(d)
        }

        // clip_bounds: { Feature: { p01:..., p99:... } }
        if let cb = root["clip_bounds"] as? [String: Any] {
            for (feat, v) in cb {
                guard let per = v as? [String: Any] else { continue }
                if let p01 = toDouble(per["p01"]) { clipP01[feat] = p01 }
                if let p99 = toDouble(per["p99"]) { clipP99[feat] = p99 }
            }
        }

        // Determine method: standardize only when scaler parameters are present
        if !scalerMean.isEmpty && !scalerScale.isEmpty {
            method = .standard
        } else {
            method = .none
        }

        if DEBUG {
            print("✅ [PRE] method =", method.rawValue)
            print("✅ [PRE] counts: mean=\(scalerMean.count) scale=\(scalerScale.count) imputer=\(imputerMedian.count) clip=\(clipP01.count)")
            print("✅ [PRE] sample feature_order:", Array(featureOrder.prefix(6)))
        }
    }

    // MARK: - Helpers

    private func toDouble(_ v: Any?) -> Double? {
        if let d = v as? Double { return d }
        if let n = v as? NSNumber { return n.doubleValue }
        if let s = v as? String { return Double(s) }
        return nil
    }

    private func toDoubleMap(_ dict: [String: Any]) -> [String: Double] {
        var out: [String: Double] = [:]
        out.reserveCapacity(dict.count)
        for (k, v) in dict {
            if let d = toDouble(v) { out[k] = d }
        }
        return out
    }
}
