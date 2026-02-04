// EventLogRepository persists and retrieves event history via Core Data.
// Created by Atakan Özcan on 28.01.2026.

import Foundation
import CoreData

final class EventLogRepository {

    private let container: NSPersistentContainer

    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
    }

    func add(kind: EventKind, sensorID: String, message: String) {
        let ctx = container.viewContext

        let rec = EventRecord(context: ctx)
        rec.id = UUID()
        rec.timestamp = Date()
        rec.kind = kind.rawValue
        rec.sensorID = sensorID
        rec.message = message

        do {
            try ctx.save()
            print("✅ CoreData saved | kind=\(kind.rawValue) sensorID=\(sensorID) msg=\(message.prefix(60))")
        } catch {
            print("❌ CoreData save failed:", error)
        }
    }

    func fetchLatest(limit: Int = 200) -> [EventLogEntry] {
        let ctx = container.viewContext
        let req = EventRecord.fetchRequest()
        req.fetchLimit = limit
        req.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        do {
            let rows = try ctx.fetch(req)

            return rows.compactMap { r -> EventLogEntry? in
                guard
                    let id = r.id,
                    let ts = r.timestamp,
                    let sensor = r.sensorID,
                    let msg = r.message
                else { return nil }

                let kind = EventKind(rawValue: r.kind ?? "DETECTION") ?? .detection

                // pRaw is no longer persisted; default to 0 when absent in storage
                return EventLogEntry(
                    id: id,
                    timestamp: ts,
                    kind: kind,
                    sensorID: sensor,
                    message: msg,
                    pRaw: 0.0
                )
            }

        } catch {
            print("❌ CoreData fetch failed:", error)
            return []
        }
    }
}
