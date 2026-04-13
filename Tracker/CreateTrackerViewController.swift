//
//  CreateTrackerViewController.swift
//  Tracker
//
//  Created by Ilia Degtiarev on 13/04/2026.
//

import UIKit

final class CreateTrackerViewController: UIViewController {
    var onCreate: ((Tracker, String) -> Void)?

    private enum Layout {
        static let menuRowHeight: CGFloat = 75
    }

    private let kind: TrackerCreationKind

    private let defaultEmoji = "🙂"
    private let defaultColorAssetName = "Blue"

    private let defaultCategoryTitle = "Домашний уют"

    private var selectedWeekdays = Set<Int>()

    private let scrollView = UIScrollView()
    private let nameField = UITextField()
    private let scheduleSummaryLabel = UILabel()
    private let categoryDetailLabel = UILabel()

    private let cancelButton = UIButton(type: .system)
    private let createButton = UIButton(type: .system)

    init(kind: TrackerCreationKind) {
        self.kind = kind
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        title = kind == .habit ? "Новая привычка" : "Новое нерегулярное событие"

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 24
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)

        configureNameField()
        content.addArrangedSubview(nameField)

        let menuCard = makeMenuCard()
        content.addArrangedSubview(menuCard)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            content.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),

            nameField.heightAnchor.constraint(equalToConstant: Layout.menuRowHeight)
        ])

        let footer = UIStackView()
        footer.axis = .horizontal
        footer.spacing = 8
        footer.distribution = .fillEqually
        footer.translatesAutoresizingMaskIntoConstraints = false

        configureCancelButton()
        configureCreateButton()
        footer.addArrangedSubview(cancelButton)
        footer.addArrangedSubview(createButton)

        view.addSubview(footer)

        NSLayoutConstraint.activate([
            scrollView.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -8),

            footer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            footer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            footer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            createButton.heightAnchor.constraint(equalToConstant: 60)
        ])

        nameField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)

        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardFrameChanged(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )

        updateScheduleSummary()
        updateCreateButtonState()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureNameField() {
        nameField.placeholder = "Введите название трекера"
        nameField.font = .systemFont(ofSize: 17)
        nameField.backgroundColor = UIColor(named: "Background [day]")?.withAlphaComponent(0.6) ?? .secondarySystemFill
        nameField.layer.cornerRadius = 16
        nameField.layer.masksToBounds = true
        nameField.autocorrectionType = .no
        nameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        nameField.leftViewMode = .always
        nameField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        nameField.rightViewMode = .always
    }

    private func makeMenuCard() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(named: "Light Gray")?.withAlphaComponent(0.6) ?? .secondarySystemFill
        container.layer.cornerRadius = 16
        container.layer.masksToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false

        categoryDetailLabel.text = defaultCategoryTitle
        let categoryRow = makeChevronRow(title: "Категория", detailLabel: categoryDetailLabel)
        categoryRow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(categoryTapped)))

        container.addSubview(categoryRow)
        var constraints: [NSLayoutConstraint] = [
            categoryRow.topAnchor.constraint(equalTo: container.topAnchor),
            categoryRow.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            categoryRow.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            categoryRow.heightAnchor.constraint(equalToConstant: Layout.menuRowHeight)
        ]

        if kind == .habit {
            let separator = UIView()
            separator.backgroundColor = UIColor.separator
            separator.translatesAutoresizingMaskIntoConstraints = false

            let scheduleRow = UIView()
            scheduleRow.translatesAutoresizingMaskIntoConstraints = false
            scheduleRow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(scheduleTapped)))

            let scheduleTitle = UILabel()
            scheduleTitle.text = "Расписание"
            scheduleTitle.font = .systemFont(ofSize: 17)
            scheduleTitle.textColor = UIColor(named: "Black [day]")
            scheduleTitle.translatesAutoresizingMaskIntoConstraints = false

            scheduleSummaryLabel.font = .systemFont(ofSize: 13)
            scheduleSummaryLabel.textColor = UIColor(named: "Gray")
            scheduleSummaryLabel.textAlignment = .left
            scheduleSummaryLabel.numberOfLines = 2
            scheduleSummaryLabel.translatesAutoresizingMaskIntoConstraints = false

            let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
            chevron.tintColor = UIColor(named: "Gray")
            chevron.translatesAutoresizingMaskIntoConstraints = false

            let scheduleLeftColumn = UIStackView(arrangedSubviews: [scheduleTitle, scheduleSummaryLabel])
            scheduleLeftColumn.axis = .vertical
            scheduleLeftColumn.spacing = 2
            scheduleLeftColumn.alignment = .leading
            scheduleLeftColumn.translatesAutoresizingMaskIntoConstraints = false

            scheduleRow.addSubview(scheduleLeftColumn)
            scheduleRow.addSubview(chevron)

            container.addSubview(separator)
            container.addSubview(scheduleRow)

            constraints += [
                separator.topAnchor.constraint(equalTo: categoryRow.bottomAnchor),
                separator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                separator.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),

                scheduleRow.topAnchor.constraint(equalTo: separator.bottomAnchor),
                scheduleRow.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                scheduleRow.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                scheduleRow.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                scheduleRow.heightAnchor.constraint(equalToConstant: Layout.menuRowHeight),

                scheduleLeftColumn.leadingAnchor.constraint(equalTo: scheduleRow.leadingAnchor, constant: 16),
                scheduleLeftColumn.centerYAnchor.constraint(equalTo: scheduleRow.centerYAnchor),
                scheduleLeftColumn.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -8),

                chevron.trailingAnchor.constraint(equalTo: scheduleRow.trailingAnchor, constant: -16),
                chevron.centerYAnchor.constraint(equalTo: scheduleRow.centerYAnchor)
            ]
        } else {
            constraints += [
                categoryRow.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ]
        }

        NSLayoutConstraint.activate(constraints)
        return container
    }

    private func makeChevronRow(title: String, detailLabel: UILabel) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.textColor = UIColor(named: "Black [day]")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        detailLabel.font = .systemFont(ofSize: 13)
        detailLabel.textColor = UIColor(named: "Gray")
        detailLabel.translatesAutoresizingMaskIntoConstraints = false

        let leftColumn = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        leftColumn.axis = .vertical
        leftColumn.spacing = 2
        leftColumn.alignment = .leading
        leftColumn.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = UIColor(named: "Gray")
        chevron.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(leftColumn)
        row.addSubview(chevron)

        NSLayoutConstraint.activate([
            leftColumn.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            leftColumn.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            leftColumn.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -8),

            chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        return row
    }

    @objc private func categoryTapped() {}

    @objc private func scheduleTapped() {
        guard kind == .habit else { return }
        let scheduleVC = ScheduleViewController(initialWeekdays: selectedWeekdays)
        scheduleVC.onDone = { [weak self] days in
            self?.selectedWeekdays = days
            self?.updateScheduleSummary()
            self?.updateCreateButtonState()
        }
        navigationController?.pushViewController(scheduleVC, animated: true)
    }

    private func updateScheduleSummary() {
        guard kind == .habit else { return }
        if selectedWeekdays.isEmpty {
            scheduleSummaryLabel.text = ""
            return
        }
        let ordered = WeekDay.orderedMondayFirst.filter { selectedWeekdays.contains($0.calendarWeekday) }
        let short: [String] = ordered.map { day in
            switch day {
            case .monday: return "Пн"
            case .tuesday: return "Вт"
            case .wednesday: return "Ср"
            case .thursday: return "Чт"
            case .friday: return "Пт"
            case .saturday: return "Сб"
            case .sunday: return "Вс"
            }
        }

        if ordered.count == 7 {
            scheduleSummaryLabel.text = "Каждый день"
        } else {
            scheduleSummaryLabel.text = short.joined(separator: ", ")
        }
    }

    private func configureCancelButton() {
        var config = UIButton.Configuration.plain()
        config.title = "Отменить"
        config.baseForegroundColor = UIColor(named: "Red")
        config.background.backgroundColor = .clear
        config.background.strokeColor = UIColor(named: "Red")
        config.background.strokeWidth = 1
        config.cornerStyle = .large
        cancelButton.configuration = config
        cancelButton.addAction(UIAction { [weak self] _ in
            self?.dismissCreation()
        }, for: .touchUpInside)
    }

    private func configureCreateButton() {
        var config = UIButton.Configuration.filled()
        config.title = "Создать"
        config.baseForegroundColor = UIColor(named: "White [day]")
        config.cornerStyle = .large
        createButton.configuration = config
        createButton.addAction(UIAction { [weak self] _ in
            self?.save()
        }, for: .touchUpInside)
    }

    @objc private func textDidChange() {
        updateCreateButtonState()
    }

    @objc private func endEditing() {
        view.endEditing(true)
    }

    @objc private func keyboardFrameChanged(_ notification: Notification) {
        guard
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        let converted = view.convert(frame, from: nil)
        let inset = max(0, view.bounds.maxY - converted.minY - view.safeAreaInsets.bottom)
        UIView.animate(withDuration: duration) {
            self.additionalSafeAreaInsets.bottom = inset
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        UIView.animate(withDuration: duration) {
            self.additionalSafeAreaInsets.bottom = 0
        }
    }

    private func updateCreateButtonState() {
        let nameOk = !(nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let scheduleOk = kind == .irregularEvent || !selectedWeekdays.isEmpty
        let enabled = nameOk && scheduleOk

        var config = createButton.configuration ?? .filled()
        config.baseBackgroundColor = enabled ? UIColor(named: "Black [day]") : UIColor(named: "Gray")
        createButton.configuration = config
        createButton.isEnabled = enabled
    }

    private func save() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else { return }

        let schedule: TrackerSchedule
        switch kind {
        case .habit:
            guard !selectedWeekdays.isEmpty else { return }
            schedule = .habit(weekdays: selectedWeekdays)
        case .irregularEvent:
            schedule = .irregularEvent
        }

        let tracker = Tracker(
            id: UUID(),
            name: name,
            colorAssetName: defaultColorAssetName,
            emoji: defaultEmoji,
            schedule: schedule
        )
        onCreate?(tracker, defaultCategoryTitle)
        dismissCreation()
    }

    private func dismissCreation() {
        dismiss(animated: true)
    }
}
