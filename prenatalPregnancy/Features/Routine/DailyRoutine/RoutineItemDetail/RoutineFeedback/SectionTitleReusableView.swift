//
//  SectionTitleReusableView.swift
//  prenatalPregnancy
//
//  Created by GEU on 09/04/26.
//

import UIKit

class SectionTitleReusableView: UICollectionReusableView {
    
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure(title: String, theme: AppTheme) {
        titleLabel.text = title
        titleLabel.textColor = theme.primaryText
    }
    
}
