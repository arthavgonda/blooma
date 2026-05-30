//
//  SectionFooterViewCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 24/04/26.
//

import UIKit

class SectionFooterViewCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var pageControl: UIPageControl!
        
        func configure(pages: Int, current: Int, theme: AppTheme) {
            pageControl.numberOfPages                  = pages
            pageControl.currentPage                    = current
            pageControl.currentPageIndicatorTintColor  = theme.accentPrimary
            pageControl.pageIndicatorTintColor         = theme.accentPrimary.withAlphaComponent(0.3)
            pageControl.transform                      = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }
}
