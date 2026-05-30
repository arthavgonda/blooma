//
//  DailyRoutineHeaderCollectionReusableView.swift
//  prenatalPregnancy
//
//  Created by GEU on 02/02/26.
//

import UIKit

class DailyRoutineHeaderCollectionReusableView: UICollectionReusableView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressCountLabel: UILabel!
    @IBOutlet weak var bottomDividerView: UIView!
    
    var theme: AppTheme!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
    }
    
    func configure(title: String, completedItems: Int, totalItems: Int, routineType: RoutineType, theme: AppTheme) {
        
        self.theme = theme
        
        titleLabel.text = title
        progressCountLabel.text = "\(completedItems) / \(totalItems)"
        
        let progress: Float = totalItems == 0 ? 0 : Float(completedItems) / Float(totalItems)
        progressView.setProgress(progress, animated: true)
        
        applyTheme()
        applyAccentColor(for: routineType)
    }
    
    private func setupBaseUI() {
        
        backgroundColor = .clear
        
        progressView.layer.cornerRadius = 2
        progressView.clipsToBounds = true
        progressView.transform = CGAffineTransform(scaleX: 1, y: 2)
    }
    
    private func applyTheme() {
        
        titleLabel.textColor = theme.primaryText
        
        progressView.trackTintColor = theme.glassThin
        
        progressCountLabel.textColor = theme.secondaryText
        progressCountLabel.textAlignment = .right
        
        bottomDividerView.backgroundColor = theme.glassThin
    }
    
    private func applyAccentColor(for routineType: RoutineType) {
        progressView.progressTintColor = routineType.accentColor
    }
    
}
