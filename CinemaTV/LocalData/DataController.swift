//
//  DataController.swift
//  CinemaTV
//
//  Created by Danilo Requena on 17/10/22.
//

import CoreData
import CloudKit
import Foundation

struct DataController {
    static let shared = DataController()
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentCloudKitContainer(name: "MovieModel")
        container.loadPersistentStores { description, error in
            if let error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
