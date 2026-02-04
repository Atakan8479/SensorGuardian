// StatTile displays a compact KPI with icon, label, and value.
// Created by Atakan Özcan on 30.01.2026.

import SwiftUI

struct StatTile: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.headline)
                .frame(width: 26, height: 26)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)                 // Keep label on one line
                    .minimumScaleFactor(0.80)     // Allow slight scaling to avoid truncation

                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.80)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)  // Provides comfortable touch target height
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading) // Ensures tiles share equal width
        .background(Color.secondary.opacity(0.08))        // Subtle background for contrast
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
