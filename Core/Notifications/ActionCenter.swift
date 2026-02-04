// ActionCenter manages notification authorization and local alerts for SensorGuardian.
// Created by Atakan Özcan on 28.01.2026.

import Foundation
import UserNotifications

@MainActor
final class ActionCenter {

    func requestNotificationPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        if settings.authorizationStatus == .notDetermined {
            do {
                _ = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                print("✅ Notification permission requested")
            } catch {
                print("❌ Notification permission failed:", error)
            }
        }
    }

    func notifyStateCrossing(sensorID: String, newState: SensorGuardianState, pRaw: Double, reasons: [String]) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "SensorGuardian: \(newState.rawValue)"
        content.body = "\(sensorID) (p=\(String(format: "%.3f", pRaw)))\n" + reasons.prefix(2).joined(separator: " • ")
        content.sound = .default

        let req = UNNotificationRequest(
            identifier: "sg-\(sensorID)-\(newState.rawValue)-\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil // Deliver immediately without scheduling delay
        )

        center.add(req)
    }

    func notifyUserQuarantine(sensorID: String, reasons: [String]) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Quarantined"
        content.body = "\(sensorID)\n" + reasons.prefix(2).joined(separator: " • ")
        content.sound = .default

        let req = UNNotificationRequest(
            identifier: "sg-action-\(sensorID)-\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil
        )
        center.add(req)
    }
}
