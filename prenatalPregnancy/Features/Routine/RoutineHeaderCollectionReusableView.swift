//
//  RoutineHeaderCollectionReusableView.swift
//  prenatalPregnancy
//
//  Created by GEU on 02/02/26.
//

import UIKit

class RoutineHeaderCollectionReusableView: UICollectionReusableView {
    
    @IBOutlet weak var weekLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var subtitleImageView: UIImageView!
    
    var theme: AppTheme!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure(gestationalWeek: Int, day: Int, trimester: Trimester, theme: AppTheme) {
        self.theme = theme
        setupUI()
        weekLabel.text = "Week \(gestationalWeek) • Day \(day) • \(trimester.displayTitle)"
        subtitleLabel.text = "Recommended Flow for You"
        subtitleImageView.image = UIImage(systemName: "sparkles")!
    }
    
    private func setupUI() {
        self.backgroundColor = .clear
        
        weekLabel.textColor = theme.primaryText
        subtitleLabel.textColor = theme.primaryText
        
        subtitleImageView.tintColor = .systemYellow
    }
    
}
