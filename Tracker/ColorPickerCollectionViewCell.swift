//
//  ColorPickerCollectionViewCell.swift
//  Tracker
//

import UIKit

final class ColorPickerCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "ColorPickerCollectionViewCell"

    static let swatchSide: CGFloat = 40
    private static let selectionGap: CGFloat = 3
    private static let selectionBorderWidth: CGFloat = 3
    private static let swatchCornerRadius: CGFloat = 8

    private let fillView = UIView()
    private let selectionRing = CAShapeLayer()

    private var isSwatchSelected = false
    private var fillColor: UIColor?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = false
        fillView.translatesAutoresizingMaskIntoConstraints = false
        fillView.layer.masksToBounds = true
        fillView.layer.cornerRadius = Self.swatchCornerRadius
        contentView.addSubview(fillView)
        selectionRing.fillColor = UIColor.clear.cgColor
        selectionRing.lineCap = .round
        selectionRing.lineJoin = .round
        selectionRing.actions = [
            "path": NSNull(),
            "strokeColor": NSNull(),
            "lineWidth": NSNull(),
            "hidden": NSNull(),
        ]
        contentView.layer.insertSublayer(selectionRing, below: fillView.layer)
        NSLayoutConstraint.activate([
            fillView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            fillView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            fillView.widthAnchor.constraint(equalToConstant: Self.swatchSide),
            fillView.heightAnchor.constraint(equalToConstant: Self.swatchSide),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(colorAssetName: String, isSelected: Bool) {
        let fill = UIColor(named: colorAssetName)
        fillColor = fill
        fillView.backgroundColor = fill
        isSwatchSelected = isSelected
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        selectionRing.isHidden = !isSelected
        selectionRing.strokeColor = fill?.withAlphaComponent(0.5).cgColor
        selectionRing.lineWidth = Self.selectionBorderWidth
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()
        layoutIfNeeded()
        updateSelectionRingPathWithoutTransaction()
        CATransaction.commit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        updateSelectionRingPathWithoutTransaction()
        CATransaction.commit()
    }

    private func updateSelectionRingPathWithoutTransaction() {
        selectionRing.frame = contentView.bounds
        guard isSwatchSelected, fillColor != nil else {
            selectionRing.path = nil
            return
        }
        let swatchFrame = fillView.convert(fillView.bounds, to: contentView)
        guard swatchFrame.width > 0 else {
            selectionRing.path = nil
            return
        }
        let expand = Self.selectionGap + Self.selectionBorderWidth / 2
        let strokeBounds = swatchFrame.insetBy(dx: -expand, dy: -expand)
        let radiusScale = strokeBounds.width / Self.swatchSide
        let corner = Self.swatchCornerRadius * radiusScale
        let path = UIBezierPath(roundedRect: strokeBounds, cornerRadius: min(corner, strokeBounds.width / 2))
        selectionRing.path = path.cgPath
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isSwatchSelected = false
        fillColor = nil
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        selectionRing.path = nil
        selectionRing.isHidden = true
        CATransaction.commit()
        fillView.backgroundColor = nil
    }
}
