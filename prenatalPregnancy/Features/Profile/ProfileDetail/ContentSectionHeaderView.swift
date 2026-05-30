//
//  ContentSectionHeaderView.swift
//  prenatalPregnancy
//
//  Created by GEU on 10/04/26.
//

import UIKit

class ContentSectionHeaderView: UICollectionReusableView {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    private var theme: AppTheme!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        
        // Initialization code
    }
    
    func configure(title: String, theme: AppTheme) {
        self.theme = theme
        
        titleLabel.text = title
        titleLabel.textColor = theme.primaryText
    }
}
