//
//  SectionHeaderReusableView.swift
//  healthPrenantalApp
//
//  Created by GEU on 06/02/26.
//

import UIKit

protocol SectionHeaderReusableViewDelegate: AnyObject {
    func didChangeSegment(index: Int)
}

class SectionHeaderReusableView: UICollectionReusableView {

    @IBOutlet weak var progressLabel: UILabel!

    weak var delegate: SectionHeaderReusableViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        progressLabel.text = "Current Week Progress"
        progressLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        progressLabel.textColor = .black
        progressLabel.numberOfLines = 1
    }

}
