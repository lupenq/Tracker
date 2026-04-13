//
//  TrackerViewController.swift
//  Tracker
//
//  Created by Ilia Degtiarev on 12/04/2026.
//

import UIKit

class TrackerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchResultsUpdating {
    private let collectionView: UICollectionView
    private let searchController = UISearchController(searchResultsController: nil)

    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.locale = Locale(identifier: "ru_RU")
        datePicker.addAction(
            UIAction { [weak self] _ in
                self?.datePickerValueChanged()
            },
            for: .valueChanged
        )
        return datePicker
    }()

    var categories: [TrackerCategory] = []
    var completedTrackers: [TrackerRecord] = []

    var currentDate: Date = .init()

    private var completedTrackerIdsForSelectedDate = Set<UUID>()

    private let calendar = Calendar.current

    private lazy var emptyStateView: UIView = makeEmptyStateView()

    private var lastCollectionViewWidth: CGFloat = 0

    private var searchQuery: String {
        searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var selectedDateStartOfDay: Date {
        calendar.startOfDay(for: currentDate)
    }

    private var visibleCategorySections: [(title: String, trackers: [Tracker])] {
        let query = searchQuery
        var sections: [(String, [Tracker])] = []
        for category in categories {
            let scheduled = category.trackers.filter { isTrackerVisibleOnSelectedDate($0) }
            let filtered: [Tracker]
            if query.isEmpty {
                filtered = scheduled
            } else {
                filtered = scheduled.filter { $0.name.localizedCaseInsensitiveContains(query) }
            }
            if !filtered.isEmpty {
                sections.append((category.title, filtered))
            }
        }
        return sections
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 9
        layout.minimumLineSpacing = 9
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 16, right: 16)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 9
        layout.minimumLineSpacing = 9
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 16, right: 16)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "White [day]")

        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "Трекеры"
        let addTrackerButton = UIBarButtonItem(
            systemItem: .add,
            primaryAction: UIAction { [weak self] _ in
                self?.addTracker()
            }
        )
        addTrackerButton.tintColor = UIColor(named: "Black [day]")
        navigationItem.leftBarButtonItem = addTrackerButton
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Поиск"

        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(TrackerCollectionViewCell.self, forCellWithReuseIdentifier: TrackerCollectionViewCell.reuseIdentifier)
        collectionView.register(
            TrackerCategoryHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: TrackerCategoryHeaderView.reuseIdentifier
        )
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        datePicker.date = currentDate
        refreshCompletedIdsForSelectedDate()
        updateUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let w = collectionView.bounds.width
        if w != lastCollectionViewWidth, w > 0 {
            lastCollectionViewWidth = w
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    private func datePickerValueChanged() {
        currentDate = datePicker.date
        refreshCompletedIdsForSelectedDate()
        updateUI()
    }

    private func refreshCompletedIdsForSelectedDate() {
        let day = selectedDateStartOfDay
        completedTrackerIdsForSelectedDate = Set(
            completedTrackers
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .map(\.trackerId)
        )
    }

    func updateSearchResults(for searchController: UISearchController) {
        updateUI()
    }

    private func isTrackerVisibleOnSelectedDate(_ tracker: Tracker) -> Bool {
        switch tracker.schedule {
        case .habit(let weekdays):
            let weekday = calendar.component(.weekday, from: currentDate)
            return weekdays.contains(weekday)
        case .irregularEvent:
            return true
        }
    }

    private func isFutureSelectedDate() -> Bool {
        let today = calendar.startOfDay(for: Date())
        return selectedDateStartOfDay > today
    }

    private func totalCompletions(for trackerId: UUID) -> Int {
        completedTrackers.filter { $0.trackerId == trackerId }.count
    }

    private func isCompletedForSelectedDate(_ tracker: Tracker) -> Bool {
        completedTrackerIdsForSelectedDate.contains(tracker.id)
    }

    private func toggleCompletion(for tracker: Tracker) {
        guard !isFutureSelectedDate() else { return }
        let day = selectedDateStartOfDay
        if completedTrackerIdsForSelectedDate.contains(tracker.id) {
            completedTrackers.removeAll {
                $0.trackerId == tracker.id && calendar.isDate($0.date, inSameDayAs: day)
            }
            completedTrackerIdsForSelectedDate.remove(tracker.id)
        } else {
            completedTrackers.append(TrackerRecord(trackerId: tracker.id, date: day))
            completedTrackerIdsForSelectedDate.insert(tracker.id)
        }
        updateUI()
    }

    private func makeEmptyStateView() -> UIView {
        let image = UIImage(named: "Sparkle")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(named: "Black [day]")
        label.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [imageView, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16)
        ])
        return container
    }

    private func updateUI() {
        let isEmpty = visibleCategorySections.isEmpty
        collectionView.backgroundView = isEmpty ? emptyStateView : nil
        collectionView.reloadData()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        visibleCategorySections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        visibleCategorySections[section].trackers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? TrackerCollectionViewCell else {
            return UICollectionViewCell()
        }
        let tracker = visibleCategorySections[indexPath.section].trackers[indexPath.item]
        cell.configure(
            tracker: tracker,
            totalCompletions: totalCompletions(for: tracker.id),
            isCompletedForSelectedDate: isCompletedForSelectedDate(tracker),
            isFutureDate: isFutureSelectedDate()
        )
        cell.onCompleteTap = { [weak self] in
            self?.toggleCompletion(for: tracker)
        }
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(
                  ofKind: kind,
                  withReuseIdentifier: TrackerCategoryHeaderView.reuseIdentifier,
                  for: indexPath
              ) as? TrackerCategoryHeaderView
        else {
            return UICollectionReusableView()
        }
        header.configure(title: visibleCategorySections[indexPath.section].title)
        return header
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: 44)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSize(width: 100, height: 148)
        }
        let inset = layout.sectionInset.left + layout.sectionInset.right
        let spacing = layout.minimumInteritemSpacing
        let width = (collectionView.bounds.width - inset - spacing) / 2
        let floored = floor(width)
        return CGSize(width: max(floored, 0), height: 148)
    }

    private func addTracker() {
        let choose = ChooseTrackerKindViewController()
        let nav = UINavigationController(rootViewController: choose)

        choose.onKindSelected = { [weak choose] kind in
            let create = CreateTrackerViewController(kind: kind)
            create.onCreate = { [weak self] tracker, categoryTitle in
                self?.appendTracker(tracker, categoryTitle: categoryTitle)
            }
            choose?.navigationController?.pushViewController(create, animated: true)
        }

        present(nav, animated: true)
    }

    private func appendTracker(_ tracker: Tracker, categoryTitle: String) {
        if let index = categories.firstIndex(where: { $0.title == categoryTitle }) {
            let category = categories[index]
            categories[index] = TrackerCategory(title: category.title, trackers: category.trackers + [tracker])
        } else {
            categories.append(TrackerCategory(title: categoryTitle, trackers: [tracker]))
        }
        updateUI()
    }
}
