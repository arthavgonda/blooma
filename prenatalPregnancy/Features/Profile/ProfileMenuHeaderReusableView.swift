//
//  SectionHeaderReusableView.swift
//  prenatalPregnancy
//
//  Created by GEU on 24/03/26.
//

import UIKit

class ProfileMenuHeaderReusableView: UICollectionReusableView {
    
    @IBOutlet weak var titleLabel: UILabel!
    var theme: AppTheme!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    private func setupUI() {
        
        titleLabel.textColor = theme.secondaryText
        titleLabel.textAlignment = .left
    }
    
    func configure(title: String, theme: AppTheme) {
        self.theme = theme
        setupUI()
        titleLabel.text = title.uppercased()
    }
    
}
