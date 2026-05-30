import UIKit

final class FooterInsights: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!

    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var exerciseNameLabel: UILabel!
    @IBOutlet weak var exerciseDateLabel: UILabel!
    @IBOutlet weak var exerciseTimeLabel: UILabel!
    @IBOutlet weak var activityIconImageView: UIImageView!

    @IBOutlet weak var distanceCardView: UIView!
    @IBOutlet weak var timeCardView: UIView!
    @IBOutlet weak var stepsCardView: UIView!

    @IBOutlet weak var distanceTitleLabel: UILabel!
    @IBOutlet weak var timeTitleLabel: UILabel!
    @IBOutlet weak var stepsTitleLabel: UILabel!

    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var stepsLabel: UILabel!

    @IBOutlet weak var distanceUnitLabel: UILabel!
    @IBOutlet weak var timeUnitLabel: UILabel!
    @IBOutlet weak var stepsUnitLabel: UILabel!

    @IBOutlet weak var distanceIconImageView: UIImageView!
    @IBOutlet weak var timeIconImageView: UIImageView!
    @IBOutlet weak var stepsIconImageView: UIImageView!
    
    var theme : AppTheme!
    private struct StatStyle {
        let tintColor: UIColor
        let backgroundColor: UIColor
        let iconName: String
    }
    
    private var statCardViews: [UIView] {
         [distanceCardView, timeCardView, stepsCardView]
     }

     private var statTitleLabels: [UILabel] {
         [distanceTitleLabel, timeTitleLabel, stepsTitleLabel]
     }

     private var statValueLabels: [UILabel] {
         [distanceLabel, timeLabel, stepsLabel]
     }

     private var statUnitLabels: [UILabel] {
         [distanceUnitLabel, timeUnitLabel, stepsUnitLabel]
     }

     private var statIconViews: [UIImageView] {
         [distanceIconImageView, timeIconImageView, stepsIconImageView]
     }

     override func awakeFromNib() {
         super.awakeFromNib()
         clipsToBounds = false
         layer.masksToBounds = false
         setupUI()
     }
    
     override func layoutSubviews() {
         super.layoutSubviews()
         parentView.layer.shadowPath = UIBezierPath(
             roundedRect: parentView.bounds,
             cornerRadius: parentView.layer.cornerRadius
         ).cgPath
     }
    
     override func prepareForReuse() {
         super.prepareForReuse()
         resetContent()
     }
    
     private func setupUI() {
         setupContainerView()
         setupHeaderUI()
         setupStatCardsUI()
         resetContent()
     }
    
     private func setupContainerView() {
         containerView.backgroundColor = .clear
         containerView.layer.cornerRadius = 24
         containerView.layer.masksToBounds = true
         containerView.layer.borderWidth = 1
         containerView.layer.borderColor = UIColor.systemGray5.cgColor
     }
    
    private func statStyle(for title: String, activityColor: String) -> StatStyle {
        switch title.lowercased() {
        case "distance":
            return StatStyle(
                tintColor: UIColor.systemBlue,backgroundColor: UIColor.systemBlue.withAlphaComponent(0.15),iconName: "location"
            )

        case "time", "duration":
            return StatStyle(
                tintColor: UIColor.systemRed,backgroundColor: UIColor.systemRed.withAlphaComponent(0.15),iconName: "clock"
            )

        case "steps":
            return StatStyle(
                tintColor: UIColor.systemGreen,backgroundColor:UIColor.systemGreen.withAlphaComponent(0.15),iconName:"shoeprints.fill"
            )

        case "reps":
            return StatStyle(
                tintColor: UIColor.systemPurple,backgroundColor: UIColor.systemPurple.withAlphaComponent(0.15),iconName: "arrow.triangle.2.circlepath"
            )
            
        case "sets":
            return StatStyle(
                tintColor: UIColor.systemMint, backgroundColor: UIColor.systemMint.withAlphaComponent(0.15), iconName: "chart.bar"
            )

        case "calories":
            return StatStyle(
                tintColor: UIColor.systemOrange,backgroundColor: UIColor.systemOrange.withAlphaComponent(0.15),iconName: "flame"
            )

        case "breaths":
            return StatStyle(
                tintColor: UIColor.systemTeal,backgroundColor: UIColor.systemTeal.withAlphaComponent(0.15),iconName: "wind"
            )

        default:
            let tint = UIColor.appColor(from: activityColor)
            return StatStyle(
                tintColor: tint,
                backgroundColor: tint.withAlphaComponent(0.12),
                iconName: "chart.bar"
            )
        }
    }

     private func setupHeaderUI() {
         exerciseNameLabel.numberOfLines = 1
         exerciseNameLabel.lineBreakMode = .byTruncatingTail
         exerciseDateLabel.font = .systemFont(ofSize: 14, weight: .medium)
         exerciseDateLabel.textColor = .secondaryLabel
         exerciseTimeLabel.font = .systemFont(ofSize: 15, weight: .semibold)
         activityIconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
     }

     private func setupStatCardsUI() {
         statCardViews.forEach {
             $0.layer.cornerRadius = 18
             $0.layer.masksToBounds = true
         }

         statTitleLabels.forEach {
             $0.font = .systemFont(ofSize: 14, weight: .semibold)
             $0.adjustsFontSizeToFitWidth = true
             $0.minimumScaleFactor = 0.8
             $0.numberOfLines = 1
         }

         statValueLabels.forEach {
             $0.font = .systemFont(ofSize: 24, weight: .bold)
         }

         statUnitLabels.forEach {
             $0.font = .systemFont(ofSize: 13, weight: .medium)
             $0.textColor = .secondaryLabel
         }

         statIconViews.forEach {
             $0.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
         }
     }

     private func resetContent() {
         exerciseNameLabel.text = nil
         exerciseDateLabel.text = nil
         exerciseTimeLabel.text = nil
         activityIconImageView.image = UIImage(systemName: "figure.walk")
         activityIconImageView.tintColor = .systemGreen
         exerciseTimeLabel.textColor = .systemBlue
         for index in 0..<statCardViews.count {
             statCardViews[index].isHidden = false
             statCardViews[index].alpha = 1
             statCardViews[index].isUserInteractionEnabled = true
             statCardViews[index].backgroundColor = .systemGray6
             statTitleLabels[index].text = "--"
             statTitleLabels[index].textColor = .label
             statValueLabels[index].text = "--"
             statValueLabels[index].textColor = .label
             statUnitLabels[index].text = ""
             statIconViews[index].image = nil
             statIconViews[index].tintColor = .label
         }
     }

    private func configureUnavailableCard(at index: Int, tintColor: UIColor, title: String = "No data") {
        guard statCardViews.indices.contains(index) else { return }
        statCardViews[index].isHidden = false
        statCardViews[index].alpha = 1
        statCardViews[index].isUserInteractionEnabled = false
        statCardViews[index].backgroundColor = tintColor.withAlphaComponent(0.08)
        statTitleLabels[index].text = title
        statTitleLabels[index].textColor = tintColor.withAlphaComponent(0.78)
        statValueLabels[index].text = "--"
        statValueLabels[index].textColor = tintColor.withAlphaComponent(0.78)
        statUnitLabels[index].text = ""
        statIconViews[index].image = UIImage(systemName: "minus.circle")
        statIconViews[index].tintColor = tintColor.withAlphaComponent(0.78)
    }
    
    func configurePlaceholder(activityName: String, activityIcon: String, activityColor: String) {
        resetContent()
        containerView.layer.cornerRadius = 16
        containerView.layer.borderColor = theme.glassBorderLight.cgColor
        containerView.layer.borderWidth = 1
        parentView.layer.cornerRadius = 16
        parentView.layer.borderWidth = 1
        parentView.layer.shadowOpacity = 0
        parentView.backgroundColor = theme.glassMedium
        parentView.layer.borderColor = theme.glassBorderLight.cgColor
        exerciseNameLabel.text = activityName
        exerciseDateLabel.text = "No Data Found"
        exerciseTimeLabel.text = "--"
        let headerColor = UIColor.appColor(from: activityColor)
        activityIconImageView.image = UIImage(systemName: activityIcon)
        activityIconImageView.tintColor = headerColor
        exerciseTimeLabel.textColor = headerColor
        for index in 0..<statCardViews.count {
            configureUnavailableCard(at: index, tintColor: headerColor)
        }
    }

    func configure(session: InsightSession, activityIcon: String, activityColor: String, dateDisplay: String, theme: AppTheme) {
        self.theme = theme
        resetContent()
        containerView.layer.cornerRadius = 16
        containerView.layer.borderColor = theme.glassBorderLight.cgColor
        containerView.layer.borderWidth = 1
        parentView.layer.cornerRadius = 16
        parentView.layer.borderWidth = 1
        parentView.layer.shadowOpacity = 0
        parentView.backgroundColor = theme.glassMedium
        parentView.layer.borderColor = theme.glassBorderLight.cgColor
        exerciseNameLabel.text = session.sessionTitle
        exerciseDateLabel.text = dateDisplay
        exerciseTimeLabel.text = session.time.isEmpty ? "--" : session.time
        let headerColor = UIColor.appColor(from: activityColor)
        exerciseTimeLabel.textColor = headerColor
        activityIconImageView.image = UIImage(systemName: activityIcon)
        activityIconImageView.tintColor = headerColor
        let visibleStats = Array(session.stats.prefix(3))
        for index in 0..<statCardViews.count {
            guard index < visibleStats.count else {
                configureUnavailableCard(at: index, tintColor: headerColor)
                continue
            }
            let stat = visibleStats[index]
            let style = statStyle(for: stat.title, activityColor: activityColor)
            statCardViews[index].isHidden = false
            statCardViews[index].backgroundColor = style.backgroundColor
            statTitleLabels[index].text = stat.title
            statTitleLabels[index].textColor = style.tintColor
            statValueLabels[index].text = stat.value
            statValueLabels[index].textColor = style.tintColor
            statUnitLabels[index].text = stat.unit
            statIconViews[index].image = UIImage(systemName: style.iconName)
            statIconViews[index].tintColor = style.tintColor
        }
    }
}
 
