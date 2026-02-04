// SensorCardView presents a single sensor’s status and actions.
// Created by Atakan Özcan on 28.01.2026.

import SwiftUI

struct SensorCardView: View {
    let sensor: DashboardSensor
    let onQuarantine: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sensor.sensorID)
                        .font(.headline)
                        .lineLimit(1)

                    Text("Confidence: \(formatPct(sensor.pRaw))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                statusChip
            }

            HStack {
                Text("Last updated")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(timeAgo(sensor.lastUpdated))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if sensor.state != .normal {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(sensor.reasons.prefix(2), id: \.self) { r in
                        Text("• \(r)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 2)
            }

            if sensor.state != .normal && !sensor.isUserQuarantined {
                Button {
                    onQuarantine(sensor.sensorID)
                } label: {
                    Text("Quarantine")
                        .font(.subheadline).bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .lineLimit(1)
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.08))
        )
    }

    private var statusChip: some View {
        HStack(spacing: 6) {
            Circle().frame(width: 8, height: 8)
            Text(statusTitle(sensor.state))
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(chipBackground(sensor.state))
        .clipShape(Capsule())
    }

    private func statusTitle(_ s: SensorGuardianState) -> String {
        switch s {
        case .normal: return "Normal"
        case .warning: return "Warning"
        case .quarantine: return "Malicious"
        }
    }

    private func chipBackground(_ s: SensorGuardianState) -> some ShapeStyle {
        switch s {
        case .normal: return AnyShapeStyle(Color.green.opacity(0.18))
        case .warning: return AnyShapeStyle(Color.orange.opacity(0.18))
        case .quarantine: return AnyShapeStyle(Color.red.opacity(0.18))
        }
    }

    private func formatPct(_ p: Double) -> String {
        let clamped = max(0.0, min(1.0, p))
        return String(format: "%.1f%%", clamped * 100.0)
    }

    private func timeAgo(_ date: Date) -> String {
        let s = Int(Date().timeIntervalSince(date))
        if s < 5 { return "just now" }
        if s < 60 { return "\(s)s ago" }
        return "\(s/60)m ago"
    }
}
