//
//  EmojiPickerCollectionViewCell.swift
//  Tracker
//

import UIKit

final class EmojiPickerCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "EmojiPickerCollectionViewCell"

    private let emojiLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.textAlignment = .center
        emojiLabel.adjustsFontSizeToFitWidth = true
        emojiLabel.minimumScaleFactor = 0.4
        emojiLabel.baselineAdjustment = .alignCenters
        contentView.addSubview(emojiLabel)
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            emojiLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 2),
            emojiLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -2),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(emoji: String, fontSize: CGFloat, isSelected: Bool) {
        emojiLabel.text = emoji
        emojiLabel.font = .systemFont(ofSize: fontSize, weight: .regular)
        let backgroundColor = UIColor(named: "Light Gray")
        contentView.backgroundColor = isSelected ? backgroundColor : .clear
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.backgroundColor = .clear
    }
}
