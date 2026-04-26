//
//  NewCategoryViewController.swift
//  Tracker
//

import UIKit

final class NewCategoryViewController: UIViewController {
    var onComplete: ((String) -> Void)?

    private let existingTitlesLowercased: Set<String>

    private let nameField = UITextField()
    private let doneButton = UIButton(type: .system)

    init(existingTitlesLowercased: Set<String>) {
        self.existingTitlesLowercased = existingTitlesLowercased
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
        title = "Новая категория"

        nameField.placeholder = "Введите название категории"
        nameField.font = .systemFont(ofSize: 17)
        nameField.backgroundColor = UIColor(named: "Background [day]")?.withAlphaComponent(0.6) ?? .secondarySystemFill
        nameField.layer.cornerRadius = 16
        nameField.layer.masksToBounds = true
        nameField.autocorrectionType = .no
        nameField.returnKeyType = .done
        nameField.delegate = self
        nameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        nameField.leftViewMode = .always
        nameField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        nameField.rightViewMode = .always
        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)

        configureDoneButton()

        view.addSubview(nameField)
        view.addSubview(doneButton)

        NSLayoutConstraint.activate([
            nameField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            nameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nameField.heightAnchor.constraint(equalToConstant: 75),

            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 60)
        ])

        updateDoneState()
    }

    private func configureDoneButton() {
        var config = UIButton.Configuration.filled()
        config.title = "Готово"
        config.baseForegroundColor = UIColor(named: "White [day]")
        config.cornerStyle = .large
        doneButton.configuration = config
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.addAction(UIAction { [weak self] _ in
            self?.submit()
        }, for: .touchUpInside)
    }

    @objc private func textDidChange() {
        updateDoneState()
    }

    private func updateDoneState() {
        let trimmed = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let enabled = !trimmed.isEmpty
        var config = doneButton.configuration ?? .filled()
        config.baseBackgroundColor = enabled ? UIColor(named: "Black [day]") : UIColor(named: "Gray")
        doneButton.configuration = config
        doneButton.isEnabled = enabled
    }

    private func submit() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else { return }
        if existingTitlesLowercased.contains(name.lowercased()) {
            let alert = UIAlertController(
                title: "Такая категория уже есть",
                message: "Введите другое название.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        view.endEditing(true)
        onComplete?(name)
    }
}

extension NewCategoryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if doneButton.isEnabled {
            submit()
        }
        return true
    }
}
