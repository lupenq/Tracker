//
//  TrackerRecordStore.swift
//  Tracker
//

import CoreData
import Foundation

final class TrackerRecordStore {
    private let context: NSManagedObjectContext

    var onChange: (() -> Void)?

    private let fetchedResultsController: NSFetchedResultsController<TrackerRecordCoreData>
    private let fetchedResultsDelegate: TrackerRecordStoreFRCDelegate

    init(context: NSManagedObjectContext) {
        self.context = context

        let request = TrackerRecordCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TrackerRecordCoreData.date, ascending: true)]
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsDelegate = TrackerRecordStoreFRCDelegate()
        fetchedResultsController.delegate = fetchedResultsDelegate
        fetchedResultsDelegate.onContentChange = { [weak self] in
            self?.onChange?()
        }
        do {
            try fetchedResultsController.performFetch()
        } catch {
            assertionFailure("TrackerRecordStore: performFetch failed: \(error)")
        }
    }

    func fetchAll() -> [TrackerRecord] {
        fetchedResultsController.fetchedObjects?.compactMap(Self.domainRecord(from:)) ?? []
    }

    func setCompleted(
        trackerId: UUID,
        on day: Date,
        completed: Bool,
        calendar: Calendar,
        trackerStore: TrackerStore
    ) throws {
        let dayStart = calendar.startOfDay(for: day)
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return
        }
        if completed {
            let trackerMO = try trackerStore.object(for: trackerId)
            let existing = try fetchRecordObject(trackerId: trackerId, dayStart: dayStart, nextDay: nextDay)
            if existing != nil { return }
            let record = TrackerRecordCoreData(context: context)
            record.id = UUID()
            record.date = dayStart
            record.tracker = trackerMO
        } else {
            if let object = try fetchRecordObject(trackerId: trackerId, dayStart: dayStart, nextDay: nextDay) {
                context.delete(object)
            }
        }
    }

    private func fetchRecordObject(trackerId: UUID, dayStart: Date, nextDay: Date) throws -> TrackerRecordCoreData? {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "tracker.id == %@ AND date >= %@ AND date < %@",
            trackerId as CVarArg,
            dayStart as NSDate,
            nextDay as NSDate
        )
        return try context.fetch(request).first
    }

    private static func domainRecord(from object: TrackerRecordCoreData) -> TrackerRecord? {
        guard let trackerId = object.tracker?.id else { return nil }
        return TrackerRecord(trackerId: trackerId, date: object.date ?? Date.distantPast)
    }
}

private final class TrackerRecordStoreFRCDelegate: NSObject, NSFetchedResultsControllerDelegate {
    var onContentChange: (() -> Void)?

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        onContentChange?()
    }
}
