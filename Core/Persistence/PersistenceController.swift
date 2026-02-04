// PersistenceController configures the Core Data stack for SensorGuardian.
// Created by Atakan Özcan on 28.01.2026.

import CoreData

final class PersistenceController {

    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SensorGuardDB") // Must match the .xcdatamodeld name

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                print("❌ CoreData load failed:", error)
            } else {
                print("✅ CoreData loaded")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
