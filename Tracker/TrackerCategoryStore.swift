//
//  TrackerCategoryStore.swift
//  Tracker
//

import CoreData
import Foundation

final class TrackerCategoryStore {
    private let context: NSManagedObjectContext

    var onChange: (() -> Void)?

    private let categoryFetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData>
    private let trackerFetchedResultsController: NSFetchedResultsController<TrackerCoreData>
    private let fetchedResultsDelegate: TrackerCategoryStoreFRCDelegate

    init(context: NSManagedObjectContext) {
        self.context = context

        let categoryRequest = TrackerCategoryCoreData.fetchRequest()
        categoryRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TrackerCategoryCoreData.title, ascending: true)]
        categoryFetchedResultsController = NSFetchedResultsController(
            fetchRequest: categoryRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        let trackerRequest = TrackerCoreData.fetchRequest()
        trackerRequest.sortDescriptors = [
            NSSortDescriptor(key: "category.title", ascending: true),
            NSSortDescriptor(keyPath: \TrackerCoreData.name, ascending: true)
        ]
        trackerFetchedResultsController = NSFetchedResultsController(
            fetchRequest: trackerRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        fetchedResultsDelegate = TrackerCategoryStoreFRCDelegate()
        categoryFetchedResultsController.delegate = fetchedResultsDelegate
        trackerFetchedResultsController.delegate = fetchedResultsDelegate

        fetchedResultsDelegate.onContentChange = { [weak self] in
            guard let self else { return }
            self.onChange?()
        }

        do {
            try categoryFetchedResultsController.performFetch()
            try trackerFetchedResultsController.performFetch()
        } catch {
            assertionFailure("TrackerCategoryStore: performFetch failed: \(error)")
        }
    }

    func fetchCategoriesWithTrackers() -> [TrackerCategory] {
        guard let objects = categoryFetchedResultsController.fetchedObjects else {
            return []
        }
        return objects.map { category in
            let trackers = (category.trackers as? Set<TrackerCoreData>)?
                .compactMap { TrackerStore.domainTracker(from: $0) }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending } ?? []
            return TrackerCategory(title: category.title ?? "", trackers: trackers)
        }
    }

    func categoryObject(title: String) throws -> TrackerCategoryCoreData {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw TrackerPersistenceError.categoryNotFound(title: title)
        }
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "title == %@", trimmed)
        if let existing = try context.fetch(request).first {
            return existing
        }
        let created = TrackerCategoryCoreData(context: context)
        created.title = trimmed
        return created
    }
}

// MARK: - NSFetchedResultsControllerDelegate

private final class TrackerCategoryStoreFRCDelegate: NSObject, NSFetchedResultsControllerDelegate {
    var onContentChange: (() -> Void)?

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        onContentChange?()
    }
}
