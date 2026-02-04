// DashboardView renders the primary dashboard experience.
// Created by Atakan Özcan on 28.01.2026.

import SwiftUI

struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()
    @State private var showLog = false

    private let statCols: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack {
                    Label("SensorGuardian", systemImage: "shield.lefthalf.filled")
                        .font(.title2).bold()

                    Spacer()

                    Button { showLog = true } label: {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.headline)
                            .padding(10)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }

                headerAndStatsCard

                HStack(spacing: 12) {
                    Button("Start CSV Stream") { vm.start() }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.isStreaming)

                    Button("Stop") { vm.stop() }
                        .buttonStyle(.bordered)
                        .disabled(!vm.isStreaming)
                }

                if vm.sensors.isEmpty {
                    ContentUnavailableView(
                        "No sensors yet",
                        systemImage: "antenna.radiowaves.left.and.right",
                        description: Text("Start CSV Stream to see live telemetry.")
                    )
                    .padding(.top, 10)
                } else {
                    DashboardGridView(sensors: vm.sensors) { id in
                        vm.quarantine(sensorID: id)
                    }
                }
            }
            .padding()
        }
        .task { await vm.onAppear() }
        .sheet(isPresented: $showLog) {
            EventLogView(log: vm.logStore)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var headerAndStatsCard: some View {
        let total = vm.totalUniqueSensors
        let quarantined = vm.sensors.filter { $0.isUserQuarantined }.count
        let warning = vm.sensors.filter { $0.state == .warning }.count
        let malicious = vm.sensors.filter { $0.state == .quarantine }.count

        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Live Security Dashboard")
                    .font(.headline)

                Text(vm.isStreaming ? "Streaming ✅ \(total) sensors" : "Ready to stream")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Text("Rows: \(vm.rowsProcessed)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Sensors: \(total)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
            }

            LazyVGrid(columns: statCols, spacing: 10) {
                StatTile(title: "Sensors",
                         value: "\(total)",
                         systemImage: "antenna.radiowaves.left.and.right")

                StatTile(title: "Quarantined",
                         value: "\(quarantined)",
                         systemImage: "lock.shield")

                StatTile(title: "Warning",
                         value: "\(warning)",
                         systemImage: "exclamationmark.triangle")

                StatTile(title: "Malicious",
                         value: "\(malicious)",
                         systemImage: "xmark.shield")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.06))
        )
    }
}
