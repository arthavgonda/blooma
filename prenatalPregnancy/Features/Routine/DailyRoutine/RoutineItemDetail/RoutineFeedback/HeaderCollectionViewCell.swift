//
//  HeaderCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 09/04/26.
//

import UIKit

class HeaderCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(title: String, subtitle: String, theme: AppTheme) {
        titleLabel.text = title
        subtitleLabel.text = subtitle

        titleLabel.textColor = theme.primaryText
        subtitleLabel.textColor = theme.secondaryText
    }
}
