//
//  TrackerStore.swift
//  Tracker
//

import CoreData
import Foundation

final class TrackerStore {
    private let context: NSManagedObjectContext

    var onChange: (() -> Void)?

    private let fetchedResultsController: NSFetchedResultsController<TrackerCoreData>
    private let fetchedResultsDelegate: TrackerStoreFRCDelegate

    init(context: NSManagedObjectContext) {
        self.context = context

        let request = TrackerCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TrackerCoreData.name, ascending: true)]
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsDelegate = TrackerStoreFRCDelegate()
        fetchedResultsController.delegate = fetchedResultsDelegate
        fetchedResultsDelegate.onContentChange = { [weak self] in
            self?.onChange?()
        }
        do {
            try fetchedResultsController.performFetch()
        } catch {
            assertionFailure("TrackerStore: performFetch failed: \(error)")
        }
    }

    static func domainTracker(from object: TrackerCoreData) -> Tracker? {
        guard let id = object.id else { return nil }
        let name = object.name ?? ""
        let color = object.colorAssetName ?? ""
        let emoji = object.emoji ?? ""
        let schedule: TrackerSchedule
        if object.isIrregularEvent {
            schedule = .irregularEvent
        } else {
            let mask = Int(object.habitWeekdayMask)
            schedule = .habit(weekdays: Self.weekdays(fromHabitMask: mask))
        }
        return Tracker(id: id, name: name, colorAssetName: color, emoji: emoji, schedule: schedule)
    }

    func insert(_ tracker: Tracker, categoryTitle: String, categoryStore: TrackerCategoryStore) throws {
        let category = try categoryStore.categoryObject(title: categoryTitle)
        let entity = TrackerCoreData(context: context)
        entity.id = tracker.id
        entity.name = tracker.name
        entity.colorAssetName = tracker.colorAssetName
        entity.emoji = tracker.emoji
        switch tracker.schedule {
        case .irregularEvent:
            entity.isIrregularEvent = true
            entity.habitWeekdayMask = 0
        case .habit(let weekdays):
            entity.isIrregularEvent = false
            entity.habitWeekdayMask = Int32(Self.habitMask(from: weekdays))
        }
        entity.category = category
    }

    func object(for id: UUID) throws -> TrackerCoreData {
        if let fromFRC = fetchedResultsController.fetchedObjects?.first(where: { $0.id == id }) {
            return fromFRC
        }
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        guard let object = try context.fetch(request).first else {
            throw TrackerPersistenceError.trackerNotFound(id: id)
        }
        return object
    }

    private static func habitMask(from weekdays: Set<Int>) -> Int {
        var mask = 0
        for weekday in weekdays where (1 ... 7).contains(weekday) {
            mask |= 1 << (weekday - 1)
        }
        return mask
    }

    private static func weekdays(fromHabitMask mask: Int) -> Set<Int> {
        var result = Set<Int>()
        for weekday in 1 ... 7 where (mask & (1 << (weekday - 1))) != 0 {
            result.insert(weekday)
        }
        return result
    }
}

private final class TrackerStoreFRCDelegate: NSObject, NSFetchedResultsControllerDelegate {
    var onContentChange: (() -> Void)?

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        onContentChange?()
    }
}
