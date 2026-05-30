//
//  RoutineItemDetailHeadingCollectionReusableView.swift
//  prenatalPregnancy
//
//  Created by GEU on 04/02/26.
//

import UIKit

class RoutineItemDetailHeadingCollectionReusableView: UICollectionReusableView {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    var theme: AppTheme!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configureCell(withTitle title: String, theme: AppTheme) {
        
        self.theme = theme
        
        titleLabel.text = title
        titleLabel.textColor = theme.primaryText
        titleLabel.numberOfLines = 1
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
    }
    
    private func setupBaseUI() {
        backgroundColor = .clear
    }
    
}
