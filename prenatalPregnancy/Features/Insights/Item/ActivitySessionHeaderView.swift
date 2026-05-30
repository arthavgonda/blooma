//
//  ActivitySessionHeaderView.swift
//  Pre1234
//
//  Created by GEU on 20/03/26.
//

import UIKit

class ActivitySessionHeaderView: UICollectionReusableView {
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
           super.awakeFromNib()
           setupUI()
       }
       
       private func setupUI() {
           backgroundColor = .clear
           titleLabel.textColor = .label
           titleLabel.text = "Your Activity Sessions"
       }
       
       func configure(title: String) {
           titleLabel.text = title
       }
   }
