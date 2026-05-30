import UIKit

class InsightSectionHeaderCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var container: UIView!
    @IBOutlet weak var header: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        header.font = .systemFont(ofSize: 15, weight: .bold)
        header.numberOfLines = 1

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        container.backgroundColor = .clear
    }

    func configure(title: String, theme: AppTheme) {
        header.text = title.uppercased()
        header.textColor = theme.primaryText
    }
}
