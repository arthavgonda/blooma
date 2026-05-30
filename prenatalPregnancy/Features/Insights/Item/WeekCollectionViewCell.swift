//
//  WeekCollectionViewCell.swift
//  healthPrenantalApp
//
//  Created by GEU on 07/02/26.
//

import UIKit

class WeekCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var weekCell: UIView!
    @IBOutlet weak var weekLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        weekLabel.textAlignment = .center
        weekLabel.font = .systemFont(ofSize: 14, weight: .medium)
        contentView.clipsToBounds = false
        contentView.layer.masksToBounds = false
        weekCell.layer.masksToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.cornerRadius = contentView.frame.height / 2
        weekCell.layer.cornerRadius = weekCell.frame.height / 2
    }

    func configure(title: String,isSelected: Bool,themeColor: UIColor,theme: AppTheme) {
        weekLabel.text = title
        contentView.backgroundColor = theme.glassMedium.withAlphaComponent(0.4)
        contentView.layer.borderWidth = 1
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 6
        if isSelected {
            weekCell.backgroundColor = .clear
            contentView.backgroundColor = themeColor.withAlphaComponent(0.18)
            contentView.layer.borderColor = themeColor.withAlphaComponent(0.6).cgColor
            weekLabel.textColor = themeColor
            contentView.layer.shadowOpacity = 0.12
        } else {
            weekCell.backgroundColor = .clear
            contentView.layer.borderColor = theme.glassBorderLight.cgColor
            weekLabel.textColor = .secondaryLabel
            contentView.layer.shadowOpacity = 0.05
        }
    }
}
