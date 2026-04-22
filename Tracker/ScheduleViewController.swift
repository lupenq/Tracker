//
//  ScheduleViewController.swift
//  Tracker
//

import UIKit

final class ScheduleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var onDone: ((Set<Int>) -> Void)?

    private var selectedWeekdays: Set<Int>

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let doneButton = UIButton(type: .system)

    private let rowHeight: CGFloat = 75
    private let tableCornerRadius: CGFloat = 16

    init(initialWeekdays: Set<Int>) {
        self.selectedWeekdays = initialWeekdays
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
        title = "Расписание"

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.backgroundColor = UIColor(named: "Background [day]")
        tableView.layer.cornerRadius = tableCornerRadius
        tableView.layer.masksToBounds = true
        tableView.isScrollEnabled = false
        tableView.rowHeight = rowHeight
        tableView.register(ScheduleDayCell.self, forCellReuseIdentifier: ScheduleDayCell.reuseId)

        var config = UIButton.Configuration.filled()
        config.title = "Готово"
        config.baseForegroundColor = UIColor(named: "White [day]")
        config.baseBackgroundColor = UIColor(named: "Black [day]")
        config.cornerStyle = .large
        doneButton.configuration = config
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            doneButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        doneButton.addAction(UIAction { [weak self] _ in
            self?.finish()
        }, for: .touchUpInside)

        view.addSubview(tableView)
        view.addSubview(doneButton)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.heightAnchor.constraint(equalToConstant: rowHeight * CGFloat(WeekDay.orderedMondayFirst.count)),

            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func finish() {
        onDone?(selectedWeekdays)
        navigationController?.popViewController(animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        WeekDay.orderedMondayFirst.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ScheduleDayCell.reuseId, for: indexPath)
        guard let dayCell = cell as? ScheduleDayCell else { return cell }
        let day = WeekDay.orderedMondayFirst[indexPath.row]
        let on = selectedWeekdays.contains(day.calendarWeekday)
        dayCell.configure(title: day.titleRussian, isOn: on) { [weak self] isOn in
            guard let self else { return }
            if isOn {
                self.selectedWeekdays.insert(day.calendarWeekday)
            } else {
                self.selectedWeekdays.remove(day.calendarWeekday)
            }
        }
        return dayCell
    }
}

private final class ScheduleDayCell: UITableViewCell {
    static let reuseId = "ScheduleDayCell"

    private let titleLabel = UILabel()
    private let toggle = UISwitch()
    private var onToggle: ((Bool) -> Void)?
    private var isConfiguring = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.textColor = UIColor(named: "Black [day]")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        toggle.onTintColor = UIColor(named: "Blue")
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.addAction(UIAction { [weak self] _ in
            guard let self, !self.isConfiguring else { return }
            self.onToggle?(self.toggle.isOn)
        }, for: .valueChanged)

        contentView.addSubview(titleLabel)
        contentView.addSubview(toggle)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            toggle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            toggle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, isOn: Bool, onChange: @escaping (Bool) -> Void) {
        titleLabel.text = title
        onToggle = onChange
        isConfiguring = true
        toggle.setOn(isOn, animated: false)
        isConfiguring = false
    }
}
