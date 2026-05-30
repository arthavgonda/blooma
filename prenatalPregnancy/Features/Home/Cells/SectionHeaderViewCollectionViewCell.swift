import UIKit

class SectionHeaderViewCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    func configure(title: String, subtitle: String, theme: AppTheme, leadingPadding: CGFloat = 20) {
        titleLabel.text         = title
        subtitleLabel.text      = subtitle
        titleLabel.font         = .systemFont(ofSize: 21, weight: .semibold)
        titleLabel.textColor    = theme.primaryText
        subtitleLabel.font      = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = theme.secondaryText

        applyLeadingPadding(leadingPadding)
    }

    private func applyLeadingPadding(_ padding: CGFloat) {
        // XIB leading constraints live on contentView, not self
        for constraint in contentView.constraints where constraint.firstAttribute == .leading {
            if constraint.firstItem === titleLabel {
                constraint.constant = padding
            } else if constraint.firstItem === subtitleLabel {
                constraint.constant = padding
            }
        }
    }
}
