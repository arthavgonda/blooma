//
//  GridStaCell.swift
//  prenatalPregnancy
//
//  Created by Amandeep on 26/03/26.
//

import UIKit

class GridStatCell: UICollectionViewCell {
    @IBOutlet weak var stepsCovered: UILabel!
    @IBOutlet weak var calorieUnit: UILabel!
    @IBOutlet weak var calorieCount: UILabel!
    @IBOutlet weak var caloriesText: UILabel!
    @IBOutlet weak var caloriesImageView: UIImageView!
    @IBOutlet weak var stepsUnitLabel: UILabel!
    @IBOutlet weak var stepsTitle: UILabel!
    @IBOutlet weak var stepsImageView: UIImageView!
    @IBOutlet weak var distanceUnitLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var distanceCoveredLabel: UILabel!
    @IBOutlet weak var distanceImageView: UIImageView!
    @IBOutlet weak var minutesImageView: UIImageView!
    @IBOutlet weak var minutesTextLabel: UILabel!
    @IBOutlet weak var minutesLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    @IBOutlet weak var calories: UIView!
    @IBOutlet weak var stepsCard: UIView!
    @IBOutlet weak var distanceCard: UIView!
    @IBOutlet weak var durationCard: UIView!
    @IBOutlet weak var containerView: UIView!

    var theme: AppTheme!

      override func awakeFromNib() {
          super.awakeFromNib()
          backgroundColor = .clear
          contentView.backgroundColor = .clear
          setupUI()
      }

      override func prepareForReuse() {
          super.prepareForReuse()
          clearAllMetricCards()
      }

      private func setupUI() {
         
          styleOverviewLabel()
          styleBaseTypography()
          styleBaseIcons()
      }

      private func styleOverviewLabel() {
          overviewLabel.text = "OVERVIEW"
          overviewLabel.textColor = theme?.primaryText ?? .darkGray
          overviewLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
      }

      private func styleBaseTypography() {
          [durationLabel, distanceLabel, stepsTitle, caloriesText].forEach {
              $0?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
          }

          [minutesLabel, distanceCoveredLabel, stepsCovered, calorieCount].forEach {
              $0?.font = UIFont.systemFont(ofSize: 28, weight: .bold)
          }

          [minutesTextLabel, distanceUnitLabel, stepsUnitLabel, calorieUnit].forEach {
              $0?.font = UIFont.systemFont(ofSize: 11, weight: .medium)
          }
      }

      private func styleBaseIcons() {[minutesImageView, distanceImageView, stepsImageView, caloriesImageView].forEach { $0?.contentMode = .scaleAspectFit
          }
      }

      private func styleCard(_ card: UIView?, color: UIColor) {
          card?.backgroundColor = color
          card?.layer.cornerRadius = 24
          card?.layer.masksToBounds = true
      }

      private func populateCard(metric: InnerCellViewController.DetailMetricItem,iconView: UIImageView?,titleLabel: UILabel?,valueLabel: UILabel?,unitLabel: UILabel?,cardView: UIView?
      ) {
          styleCard(cardView, color: metric.cardColor)
          cardView?.isHidden = false
          cardView?.alpha = 1
          cardView?.isUserInteractionEnabled = true
          iconView?.image = UIImage(systemName: metric.iconName)
          iconView?.tintColor = metric.tintColor
          titleLabel?.text = metric.title
          titleLabel?.textColor = metric.tintColor
          valueLabel?.text = metric.value
          valueLabel?.textColor = metric.tintColor
          unitLabel?.text = metric.unit
          unitLabel?.textColor = metric.tintColor.withAlphaComponent(0.72)
      }
    
     private func clearCard(iconView: UIImageView?,titleLabel: UILabel?,valueLabel: UILabel?,unitLabel: UILabel?,cardView:UIView?) {
        cardView?.isHidden = false
        cardView?.backgroundColor = .clear
        cardView?.alpha = 0
        cardView?.isUserInteractionEnabled = false

        iconView?.image = nil
        titleLabel?.text = nil
        valueLabel?.text = nil
        unitLabel?.text = nil
    }

    private var metricCardSlots: [(iconView: UIImageView?, titleLabel: UILabel?, valueLabel: UILabel?, unitLabel: UILabel?, cardView: UIView?)] {
        [
            (minutesImageView, durationLabel, minutesLabel, minutesTextLabel, durationCard),
            (distanceImageView, distanceLabel, distanceCoveredLabel, distanceUnitLabel, distanceCard),
            (stepsImageView, stepsTitle, stepsCovered, stepsUnitLabel, stepsCard),
            (caloriesImageView, caloriesText, calorieCount, calorieUnit, calories)
        ]
    }

    private func clearAllMetricCards() {
        metricCardSlots.forEach {
            clearCard(
                iconView: $0.iconView,
                titleLabel: $0.titleLabel,
                valueLabel: $0.valueLabel,
                unitLabel: $0.unitLabel,
                cardView: $0.cardView
            )
        }
    }

    func configure(metrics: [InnerCellViewController.DetailMetricItem], theme : AppTheme) {
        self.theme = theme
        containerView.backgroundColor = theme.glassMedium
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowOpacity = 0
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = theme.glassBorderLight.cgColor

        [durationCard, distanceCard, stepsCard, calories].forEach {
            $0?.isHidden = false
            $0?.alpha = 1
            $0?.isUserInteractionEnabled = true
        }

        clearAllMetricCards()

        let maxVisibleMetrics = 4
        for (index, metric) in metrics.prefix(maxVisibleMetrics).enumerated() {
            let slot = metricCardSlots[index]
            populateCard(
                metric: metric,
                iconView: slot.iconView,
                titleLabel: slot.titleLabel,
                valueLabel: slot.valueLabel,
                unitLabel: slot.unitLabel,
                cardView: slot.cardView
            )
        }
    }
  }
