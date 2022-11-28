//
//  CoreDataManager.swift
//  CinemaTV
//
//  Created by Danilo Requena on 06/11/22.
//

import CoreData
import CloudKit
import Foundation
import SwiftUI

final class CoreDataManager {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var movies: FetchedResults<MoviesToWatch>
    @Environment(\.managedObjectContext) var mocWatched
    @FetchRequest(sortDescriptors: []) var moviesWatched: FetchedResults<MoviesWatched>
    
    //1
    static let sharedManager = CoreDataManager()
    //2.
    private init() {} // Prevent clients from creating another instance.
    
    //3
    lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentCloudKitContainer(name: "MovieModel")
        
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    //4
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try moc.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
