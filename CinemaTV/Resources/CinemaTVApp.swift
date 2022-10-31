//
//  CinemaTVApp.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import SwiftUI

@main
struct CinemaTVApp: App {
//    let persistenceController = PersistenceController.shared
    @StateObject private var dataController = DataController()

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
        }
    }
}
