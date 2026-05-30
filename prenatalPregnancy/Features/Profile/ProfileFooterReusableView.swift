//
//  ProfileFooterReusableView.swift
//  prenatalPregnancy
//
//  Created by GEU on 10/04/26.
//

import UIKit

class ProfileFooterReusableView: UICollectionReusableView {
    
    @IBOutlet weak var appNameLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupUI()
        
        // Initialization code
    }
    
    private func setupUI() {
        
        backgroundColor = .clear
        
        appNameLabel.numberOfLines = 1
        versionLabel.numberOfLines = 1
    }
    
    func configure(theme: AppTheme) {
        
        appNameLabel.text = "Blooma"
        appNameLabel.textColor = theme.secondaryText
        
        versionLabel.textColor = theme.tertiaryText
        versionLabel.text = getAppVersion()
    }
    
    private func getAppVersion() -> String {
        
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        return "Version \(version) (\(build))"
    }
}
