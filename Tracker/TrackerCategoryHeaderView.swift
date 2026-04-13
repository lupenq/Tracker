//
//  TrackerCategoryHeaderView.swift
//  Tracker
//
//  Created by Ilia Degtiarev on 13/04/2026.
//

import UIKit

final class TrackerCategoryHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "TrackerCategoryHeaderView"

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .systemFont(ofSize: 19, weight: .bold)
        titleLabel.textColor = UIColor(named: "Black [day]")
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String) {
        titleLabel.text = title
    }
}
