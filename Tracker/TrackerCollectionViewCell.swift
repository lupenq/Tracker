//
//  TrackerCollectionViewCell.swift
//  Tracker
//
//  Created by Ilia Degtiarev on 13/04/2026.
//

import UIKit

final class TrackerCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "TrackerCollectionViewCell"

    private enum Metrics {
        static let emojiBadgeSize: CGFloat = 24
        static let emojiCornerRadius: CGFloat = emojiBadgeSize / 2
        static let contentInset: CGFloat = 12
        static let emojiFontSize: CGFloat = 12
    }

    var onCompleteTap: (() -> Void)?

    private let cardContainer = UIView()
    private let headerView = UIView()
    private let footerView = UIView()
    private let emojiLabel = UILabel()
    private let emojiBackgroundView = UIView()
    private let nameLabel = UILabel()
    private let countLabel = UILabel()
    private let completeButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onCompleteTap = nil
    }

    func configure(
        tracker: Tracker,
        totalCompletions: Int,
        isCompletedForSelectedDate: Bool,
        isFutureDate: Bool
    ) {
        emojiLabel.text = tracker.emoji
        nameLabel.text = tracker.name

        let color = UIColor(named: tracker.colorAssetName)
        headerView.backgroundColor = color

        countLabel.text = daysCountString(totalCompletions)
        countLabel.textColor = UIColor(named: "Black [day]")

        let symbolName = isCompletedForSelectedDate ? "checkmark" : "plus"
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        completeButton.setImage(UIImage(systemName: symbolName, withConfiguration: config), for: .normal)

        if isCompletedForSelectedDate {
            completeButton.backgroundColor = color?.withAlphaComponent(0.3)
            completeButton.tintColor = UIColor(named: "White [day]")
            completeButton.layer.borderWidth = 0
        } else {
            completeButton.backgroundColor = color
            completeButton.tintColor = UIColor(named: "White [day]")
            completeButton.layer.borderWidth = 0
        }

        completeButton.isEnabled = !isFutureDate
        completeButton.alpha = isFutureDate ? 0.35 : 1
    }

    private func daysCountString(_ count: Int) -> String {
        let word: String
        let c = abs(count)
        let n = c % 100
        let n1 = c % 10
        if n >= 11 && n <= 14 {
            word = "дней"
        } else if n1 == 1 {
            word = "день"
        } else if n1 >= 2 && n1 <= 4 {
            word = "дня"
        } else {
            word = "дней"
        }
        return "\(count) \(word)"
    }

    private func setupViews() {
        cardContainer.translatesAutoresizingMaskIntoConstraints = false

        headerView.layer.cornerRadius = 16
        headerView.layer.masksToBounds = true
        headerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.backgroundColor = UIColor(named: "White [day]")
        footerView.translatesAutoresizingMaskIntoConstraints = false

        emojiLabel.font = .systemFont(ofSize: Metrics.emojiFontSize, weight: .regular)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false

        emojiBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        emojiBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        emojiBackgroundView.layer.cornerRadius = Metrics.emojiCornerRadius
        emojiBackgroundView.layer.masksToBounds = true

        emojiLabel.alpha = 1

        nameLabel.font = .systemFont(ofSize: 12, weight: .medium)
        nameLabel.textColor = UIColor(named: "White [day]")
        nameLabel.numberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        countLabel.font = .systemFont(ofSize: 12, weight: .medium)
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        completeButton.layer.cornerRadius = 17
        completeButton.layer.masksToBounds = true
        completeButton.translatesAutoresizingMaskIntoConstraints = false
        completeButton.addAction(UIAction { [weak self] _ in
            self?.onCompleteTap?()
        }, for: .touchUpInside)

        contentView.addSubview(cardContainer)
        cardContainer.addSubview(headerView)
        cardContainer.addSubview(footerView)
        headerView.addSubview(emojiBackgroundView)
        headerView.addSubview(nameLabel)
        emojiBackgroundView.addSubview(emojiLabel)
        footerView.addSubview(countLabel)
        footerView.addSubview(completeButton)

        NSLayoutConstraint.activate([
            cardContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            headerView.topAnchor.constraint(equalTo: cardContainer.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor),
            headerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 90),

            footerView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            footerView.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor),
            footerView.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor),
            footerView.heightAnchor.constraint(equalToConstant: 58),

            emojiBackgroundView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: Metrics.contentInset),
            emojiBackgroundView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: Metrics.contentInset),
            emojiBackgroundView.widthAnchor.constraint(equalToConstant: Metrics.emojiBadgeSize),
            emojiBackgroundView.heightAnchor.constraint(equalToConstant: Metrics.emojiBadgeSize),

            emojiLabel.topAnchor.constraint(equalTo: emojiBackgroundView.topAnchor),
            emojiLabel.leadingAnchor.constraint(equalTo: emojiBackgroundView.leadingAnchor),
            emojiLabel.trailingAnchor.constraint(equalTo: emojiBackgroundView.trailingAnchor),
            emojiLabel.bottomAnchor.constraint(equalTo: emojiBackgroundView.bottomAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: Metrics.contentInset),
            nameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -Metrics.contentInset),
            nameLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -Metrics.contentInset),

            countLabel.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 12),
            countLabel.centerYAnchor.constraint(equalTo: footerView.centerYAnchor),

            completeButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -12),
            completeButton.centerYAnchor.constraint(equalTo: footerView.centerYAnchor),
            completeButton.widthAnchor.constraint(equalToConstant: 34),
            completeButton.heightAnchor.constraint(equalToConstant: 34)
        ])
    }
}
