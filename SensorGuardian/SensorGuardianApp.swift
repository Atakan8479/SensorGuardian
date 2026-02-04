//
//  SensorGuardianApp.swift
//  SensorGuardian
//
//  Created by Atakan Özcan on 28.01.2026.
//

import SwiftUI

@main
struct SensorGuardianApp: App {

    let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
