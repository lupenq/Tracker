//
//  AppDelegate.swift
//  Tracker
//
//  Created by Ilia Degtiarev on 12/04/2026.
//

import CoreData
import UIKit

final class PersistentContainer {
    private let storeContainer: NSPersistentContainer

    init(modelName: String = "TrackerStore") {
        storeContainer = NSPersistentContainer(name: modelName)
        storeContainer.loadPersistentStores { _, error in
            if let error {
                fatalError("Core Data: не удалось загрузить хранилище: \(error)")
            }
        }
        storeContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    var viewContext: NSManagedObjectContext {
        storeContainer.viewContext
    }

    func saveContext() {
        let context = storeContainer.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Core Data: ошибка сохранения \(nsError), \(nsError.userInfo)")
        }
    }

    func createStoreContext() -> TrackerDataStores {
        let ctx = viewContext
        return TrackerDataStores(
            categoryStore: TrackerCategoryStore(context: ctx),
            trackerStore: TrackerStore(context: ctx),
            recordStore: TrackerRecordStore(context: ctx)
        )
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    let persistentContainer = PersistentContainer()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        persistentContainer.saveContext()
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
