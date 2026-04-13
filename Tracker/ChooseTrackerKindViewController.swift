//
//  ChooseTrackerKindViewController.swift
//  Tracker
//
//  Created by Ilia Degtiarev on 13/04/2026.
//

import UIKit

final class ChooseTrackerKindViewController: UIViewController {
    var onKindSelected: ((TrackerCreationKind) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "White [day]")
        title = "Создание трекера"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak self] _ in
                self?.dismiss(animated: true)
            }
        )

        let habitButton = makeChoiceButton(title: "Привычка")
        habitButton.addAction(UIAction { [weak self] _ in
            self?.onKindSelected?(.habit)
        }, for: .touchUpInside)

        let irregularButton = makeChoiceButton(title: "Нерегулярное событие")
        irregularButton.addAction(UIAction { [weak self] _ in
            self?.onKindSelected?(.irregularEvent)
        }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [habitButton, irregularButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func makeChoiceButton(title: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseForegroundColor = UIColor(named: "White [day]")
        config.baseBackgroundColor = UIColor(named: "Black [day]")
        config.cornerStyle = .large

        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 60)
        ])
        return button
    }
}
