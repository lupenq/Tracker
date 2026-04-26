//
//  CategoryListViewController.swift
//  Tracker
//

import UIKit

final class CategoryListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var onCategoriesUpdate: (([String], String?) -> Void)?

    private static var categoryCellBackgroundColor: UIColor {
        UIColor(named: "Light Gray")?.withAlphaComponent(0.6) ?? .secondarySystemFill
    }

    private var titles: [String]
    private var selectedTitle: String?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let addButton = UIButton(type: .system)

    init(titles: [String], selectedTitle: String?) {
        self.titles = Self.uniquePreservingOrder(titles)
        self.selectedTitle = selectedTitle
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "White [day]")
        navigationItem.largeTitleDisplayMode = .never
        title = "Категория"

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.backgroundColor = UIColor(named: "White [day]")
        tableView.rowHeight = 75
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        var config = UIButton.Configuration.filled()
        config.title = "Добавить категорию"
        config.baseForegroundColor = UIColor(named: "White [day]")
        config.baseBackgroundColor = UIColor(named: "Black [day]")
        config.cornerStyle = .large
        addButton.configuration = config
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addAction(UIAction { [weak self] _ in
            self?.openNewCategory()
        }, for: .touchUpInside)

        view.addSubview(tableView)
        view.addSubview(addButton)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -16),

            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 60)
        ])

        refreshEmptyBackground()
    }

    private func refreshEmptyBackground() {
        if titles.isEmpty {
            tableView.backgroundView = makeEmptyStateView()
            tableView.isScrollEnabled = false
        } else {
            tableView.backgroundView = nil
            tableView.isScrollEnabled = true
        }
    }

    private func makeEmptyStateView() -> UIView {
        let imageView = UIImageView(image: UIImage(named: "Sparkle"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = "Привычки и события можно\nобъединить по смыслу"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(named: "Black [day]")

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
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -24)
        ])
        return container
    }

    private func openNewCategory() {
        let existingLower = Set(titles.map { $0.lowercased() })
        let newVC = NewCategoryViewController(existingTitlesLowercased: existingLower)
        newVC.onComplete = { [weak self] name in
            self?.appendAndSelect(name)
        }
        navigationController?.pushViewController(newVC, animated: true)
    }

    private func appendAndSelect(_ raw: String) {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        if titles.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) {
            return
        }
        titles.append(name)
        selectedTitle = name
        tableView.reloadData()
        refreshEmptyBackground()
        onCategoriesUpdate?(titles, selectedTitle)
        popBackToCreateTracker()
    }

    private func selectTitle(at index: Int) {
        guard titles.indices.contains(index) else { return }
        selectedTitle = titles[index]
        tableView.reloadData()
        onCategoriesUpdate?(titles, selectedTitle)
        popBackToCreateTracker()
    }

    private func popBackToCreateTracker() {
        guard let nav = navigationController else { return }
        if let create = nav.viewControllers.first(where: { $0 is CreateTrackerViewController }) {
            nav.popToViewController(create, animated: true)
        } else {
            nav.popViewController(animated: true)
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        titles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = UIListContentConfiguration.cell()
        content.text = titles[indexPath.row]
        content.textProperties.font = .systemFont(ofSize: 17)
        content.textProperties.color = UIColor(named: "Black [day]") ?? .label
        cell.contentConfiguration = content

        var bg = UIBackgroundConfiguration.listGroupedCell()
        bg.backgroundColor = Self.categoryCellBackgroundColor
        cell.backgroundConfiguration = bg

        let title = titles[indexPath.row]
        if let selected = selectedTitle, selected.caseInsensitiveCompare(title) == .orderedSame {
            cell.accessoryType = .checkmark
            cell.tintColor = .systemBlue
        } else {
            cell.accessoryType = .none
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectTitle(at: indexPath.row)
    }

    private static func uniquePreservingOrder(_ titles: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for t in titles {
            let key = t.lowercased()
            if seen.contains(key) { continue }
            seen.insert(key)
            result.append(t)
        }
        return result
    }
}
