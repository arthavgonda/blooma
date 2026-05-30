//
//  RoutineFooterCollectionReusableView.swift
//  prenatalPregnancy
//
//  Created by GEU on 02/02/26.
//

import UIKit

class RoutineFooterCollectionReusableView: UICollectionReusableView {
    
    @IBOutlet weak var disclaimerTitleLabel: UILabel!
    @IBOutlet weak var disclaimerBodyLabel: UILabel!
    
    var theme: AppTheme!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configureCell(theme: AppTheme) {
        self.theme = theme
        setupUI()
        disclaimerTitleLabel.text = "Disclaimer"
        disclaimerBodyLabel.text =
            """
            This app offers personalized wellness and fitness guidance during pregnancy based on your inputs such as heart rate activity levels and any health conditions you share.
            It does not replace medical advice diagnosis or treatment. If you experience any discomfort or complications please pause, cool down and consult your healthcare provider.
            """
    }
    
    private func setupUI() {
        
        disclaimerTitleLabel.textColor = theme.primaryText
        disclaimerBodyLabel.textColor = theme.secondaryText
        disclaimerBodyLabel.numberOfLines = 0
        
    }
    
}
