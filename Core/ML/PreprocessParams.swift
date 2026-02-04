// PreprocessParams loads preprocessing metadata produced during model training.
// Created by Atakan Özcan on 28.01.2026.

import Foundation

struct PreprocessParams: Decodable {
    let feature_order: [String]
    let imputer_median: [String: Double]
    let scaler_mean: [String: Double]
    let scaler_scale: [String: Double]
    let clip_bounds: [String: Clip]

    struct Clip: Decodable {
        let p01: Double
        let p99: Double
    }

    static func load(resourceName: String) throws -> PreprocessParams {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            throw NSError(domain: "PreprocessParams", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing \(resourceName).json in bundle"])
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(PreprocessParams.self, from: data)
    }

    func clip(_ feature: String, _ x: Double) -> Double {
        guard let b = clip_bounds[feature] else { return x }
        return min(max(x, b.p01), b.p99)
    }

    func impute(_ feature: String, _ x: Double?) -> Double {
        if let v = x { return v }
        return imputer_median[feature] ?? 0.0
    }

    func scale(_ feature: String, _ x: Double) -> Double {
        let mu = scaler_mean[feature] ?? 0.0
        let sd = scaler_scale[feature] ?? 1.0
        if sd == 0 { return 0.0 }
        return (x - mu) / sd
    }
}
