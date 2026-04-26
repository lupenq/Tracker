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
        static let pickerColumns: CGFloat = 6
        static let pickerSpacing: CGFloat = 5
        static let colorPickerVerticalSectionInset: CGFloat = 8
    }

    private let kind: TrackerCreationKind

    private let emojis = TrackerCreationPalette.emojis
    private let colorAssetNames = TrackerCreationPalette.colorAssetNames

    private static let categoryPlaceholder = "Выберите категорию"

    private var categoryTitles: [String]
    private var selectedCategoryTitle: String?

    private var selectedEmojiIndex = 0
    private var selectedColorIndex = 0
    private var selectedWeekdays = Set<Int>()

    private var emojiGridHeightConstraint: NSLayoutConstraint?
    private var colorGridHeightConstraint: NSLayoutConstraint?
    private var didRefreshColorPickerAfterFirstLayout = false

    private let scrollView = UIScrollView()
    private let nameField = UITextField()
    private let scheduleSummaryLabel = UILabel()
    private let categoryDetailLabel = UILabel()

    private let cancelButton = UIButton(type: .system)
    private let createButton = UIButton(type: .system)

    private lazy var emojiCollectionView: UICollectionView = makePickerCollectionView(registerEmoji: true)

    private lazy var colorCollectionView: UICollectionView = makePickerCollectionView(registerEmoji: false)

    init(kind: TrackerCreationKind, existingCategoryTitles: [String]) {
        self.kind = kind
        self.categoryTitles = Self.uniquePreservingOrder(existingCategoryTitles)
        self.selectedCategoryTitle = self.categoryTitles.first
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
        title = kind == .habit ? "Создание привычки" : "Новое нерегулярное событие"

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

        content.addArrangedSubview(makeSectionTitle("Emoji"))
        content.addArrangedSubview(emojiCollectionView)
        let emojiH = emojiCollectionView.heightAnchor.constraint(equalToConstant: 160)
        emojiH.isActive = true
        emojiGridHeightConstraint = emojiH

        content.addArrangedSubview(makeSectionTitle("Цвет"))
        content.addArrangedSubview(colorCollectionView)
        let colorH = colorCollectionView.heightAnchor.constraint(equalToConstant: 160)
        colorH.isActive = true
        colorGridHeightConstraint = colorH
        colorCollectionView.clipsToBounds = false

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

        selectedColorIndex = 0
        updateScheduleSummary()
        updateCreateButtonState()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let contentWidth = scrollView.bounds.width - 32
        guard contentWidth > 0 else { return }
        let emojiHeight = Self.pickerGridHeight(itemCount: emojis.count, contentWidth: contentWidth)
        let colorHeight = Self.colorPickerGridHeight(itemCount: colorAssetNames.count, contentWidth: contentWidth)
        emojiGridHeightConstraint?.constant = emojiHeight
        colorGridHeightConstraint?.constant = colorHeight
        emojiCollectionView.collectionViewLayout.invalidateLayout()
        colorCollectionView.collectionViewLayout.invalidateLayout()

        if !didRefreshColorPickerAfterFirstLayout, colorCollectionView.bounds.width > 0 {
            didRefreshColorPickerAfterFirstLayout = true
            selectedColorIndex = 0
            colorCollectionView.reloadData()
        }
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

    private func makePickerCollectionView(registerEmoji: Bool) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = Layout.pickerSpacing
        layout.minimumLineSpacing = Layout.pickerSpacing
        layout.sectionInset = .zero
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isScrollEnabled = false
        cv.dataSource = self
        cv.delegate = self
        if registerEmoji {
            cv.register(EmojiPickerCollectionViewCell.self, forCellWithReuseIdentifier: EmojiPickerCollectionViewCell.reuseIdentifier)
        } else {
            cv.register(ColorPickerCollectionViewCell.self, forCellWithReuseIdentifier: ColorPickerCollectionViewCell.reuseIdentifier)
        }
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }

    private func makeSectionTitle(_ text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.textColor = UIColor(named: "Black [day]")
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        let screenEdgeInset: CGFloat = 28
        let contentInset: CGFloat = 16
        let labelInsetInContainer = screenEdgeInset - contentInset
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: labelInsetInContainer),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -labelInsetInContainer),
        ])
        return container
    }

    private static func pickerGridItemSide(contentWidth: CGFloat) -> CGFloat {
        let columns = Layout.pickerColumns
        let spacing = Layout.pickerSpacing
        return floor((contentWidth - spacing * (columns - 1)) / columns)
    }

    private static func pickerGridHeight(itemCount: Int, contentWidth: CGFloat) -> CGFloat {
        guard itemCount > 0 else { return 0 }
        let columns = Layout.pickerColumns
        let spacing = Layout.pickerSpacing
        let side = pickerGridItemSide(contentWidth: contentWidth)
        let rows = ceil(CGFloat(itemCount) / columns)
        return rows * side + max(CGFloat(0), rows - 1) * spacing
    }

    private static func colorPickerCellSide(contentWidth: CGFloat) -> CGFloat {
        let columns: CGFloat = Layout.pickerColumns
        let gaps: CGFloat = Layout.pickerColumns - 1
        let spacingMin: CGFloat = 2
        let targetSide: CGFloat = ColorPickerCollectionViewCell.swatchSide + 2 * (3 + 2)
        let spacingIfTarget = (contentWidth - columns * targetSide) / gaps
        if spacingIfTarget >= spacingMin { return targetSide }
        let side = floor((contentWidth - gaps * spacingMin) / columns)
        return max(45, side)
    }

    private static func colorPickerInteritemSpacing(contentWidth: CGFloat) -> CGFloat {
        let columns = Layout.pickerColumns
        let gaps = Layout.pickerColumns - 1
        let side = colorPickerCellSide(contentWidth: contentWidth)
        return max(2, (contentWidth - columns * side) / gaps)
    }

    private static func colorPickerGridHeight(itemCount: Int, contentWidth: CGFloat) -> CGFloat {
        guard itemCount > 0 else { return 0 }
        let columns = Layout.pickerColumns
        let side = colorPickerCellSide(contentWidth: contentWidth)
        let spacing = colorPickerInteritemSpacing(contentWidth: contentWidth)
        let rows = ceil(CGFloat(itemCount) / columns)
        let grid = rows * side + max(CGFloat(0), rows - 1) * spacing
        return grid + 2 * Layout.colorPickerVerticalSectionInset
    }

    private func makeMenuCard() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(named: "Light Gray")?.withAlphaComponent(0.6) ?? .secondarySystemFill
        container.layer.cornerRadius = 16
        container.layer.masksToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false

        updateCategoryDetailLabel()
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

    @objc private func categoryTapped() {
        let list = CategoryListViewController(titles: categoryTitles, selectedTitle: selectedCategoryTitle)
        list.onCategoriesUpdate = { [weak self] titles, selected in
            self?.categoryTitles = titles
            self?.selectedCategoryTitle = selected
            self?.updateCategoryDetailLabel()
            self?.updateCreateButtonState()
        }
        navigationController?.pushViewController(list, animated: true)
    }

    private func updateCategoryDetailLabel() {
        if let title = selectedCategoryTitle {
            categoryDetailLabel.text = title
            categoryDetailLabel.textColor = UIColor(named: "Gray")
        } else {
            categoryDetailLabel.text = Self.categoryPlaceholder
            categoryDetailLabel.textColor = UIColor(named: "Gray")
        }
    }

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
        let categoryOk = selectedCategoryTitle != nil
        let enabled = nameOk && scheduleOk && categoryOk

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

        guard let categoryTitle = selectedCategoryTitle else { return }

        let tracker = Tracker(
            id: UUID(),
            name: name,
            colorAssetName: colorAssetNames[selectedColorIndex],
            emoji: emojis[selectedEmojiIndex],
            schedule: schedule
        )
        onCreate?(tracker, categoryTitle)
        dismissCreation()
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

    private func dismissCreation() {
        dismiss(animated: true)
    }
}

// MARK: - Emoji / color pickers

extension CreateTrackerViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === emojiCollectionView {
            return emojis.count
        }
        return colorAssetNames.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === emojiCollectionView {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EmojiPickerCollectionViewCell.reuseIdentifier,
                for: indexPath
            ) as! EmojiPickerCollectionViewCell
            let side = Self.pickerGridItemSide(contentWidth: max(1, collectionView.bounds.width))
            let fontSize = max(32, side * 0.42)
            cell.configure(emoji: emojis[indexPath.item], fontSize: fontSize, isSelected: indexPath.item == selectedEmojiIndex)
            return cell
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ColorPickerCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as! ColorPickerCollectionViewCell
        cell.configure(colorAssetName: colorAssetNames[indexPath.item], isSelected: indexPath.item == selectedColorIndex)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = max(1, collectionView.bounds.width)
        if collectionView === colorCollectionView {
            let side = Self.colorPickerCellSide(contentWidth: width)
            return CGSize(width: side, height: side)
        }
        let side = Self.pickerGridItemSide(contentWidth: width)
        return CGSize(width: side, height: side)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView === colorCollectionView {
            return Self.colorPickerInteritemSpacing(contentWidth: max(1, collectionView.bounds.width))
        }
        return Layout.pickerSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView === colorCollectionView {
            return Self.colorPickerInteritemSpacing(contentWidth: max(1, collectionView.bounds.width))
        }
        return Layout.pickerSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView === colorCollectionView {
            let v = Layout.colorPickerVerticalSectionInset
            return UIEdgeInsets(top: v, left: 0, bottom: v, right: 0)
        }
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === emojiCollectionView {
            let previous = selectedEmojiIndex
            selectedEmojiIndex = indexPath.item
            if previous != indexPath.item {
                collectionView.reloadItems(at: [IndexPath(item: previous, section: 0), indexPath])
            }
        } else {
            let previous = selectedColorIndex
            selectedColorIndex = indexPath.item
            if previous != indexPath.item {
                collectionView.reloadData()
            }
        }
    }
}
