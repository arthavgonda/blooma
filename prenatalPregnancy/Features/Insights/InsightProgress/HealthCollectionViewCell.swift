//
//  HealthCollectionViewCell.swift
//  healthPrenantalApp
//
//  Created by GEU on 06/02/26.
//

import UIKit
import DGCharts

class HealthCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var walkingImage: UIImageView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var barChartView: BarChartView!
    @IBOutlet weak var chevronImage: UIImageView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var motivationLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    var theme: AppTheme!

        override func awakeFromNib() {
            super.awakeFromNib()
            setupUI()
            setupChartAppearance()
        }
    override func prepareForReuse() {
            super.prepareForReuse()
            barChartView.data = nil
            barChartView.highlightValue(nil)
            walkingImage.image = nil
        }

    private func setupUI() {
            contentView.layer.cornerRadius = 24
            contentView.clipsToBounds = true
            chevronImage.image = UIImage(systemName: "chevron.right")
            cardView.layer.cornerRadius = 24
        }
    private func setupChartAppearance() {
            barChartView.noDataText = ""
            barChartView.leftAxis.enabled = false
            barChartView.rightAxis.enabled = false
            barChartView.legend.enabled = false
            barChartView.chartDescription.enabled = false
            barChartView.doubleTapToZoomEnabled = false
            barChartView.pinchZoomEnabled = false
            barChartView.scaleXEnabled = false
            barChartView.scaleYEnabled = false
            barChartView.dragEnabled = false
            barChartView.highlightPerTapEnabled = false
            barChartView.highlightPerDragEnabled = false
            barChartView.drawValueAboveBarEnabled = false
            barChartView.drawBarShadowEnabled = false
            barChartView.drawGridBackgroundEnabled = false
            barChartView.isUserInteractionEnabled = false
            barChartView.backgroundColor = .clear
            barChartView.extraTopOffset = 4
            barChartView.extraBottomOffset = 0
            barChartView.extraLeftOffset = 0
            barChartView.extraRightOffset = 0
            barChartView.minOffset = 0
            let xAxis = barChartView.xAxis
            xAxis.labelPosition = .bottom
            xAxis.granularity = 1
            xAxis.drawGridLinesEnabled = false
            xAxis.drawAxisLineEnabled = false
            xAxis.labelTextColor = .secondaryLabel
            xAxis.labelFont = .systemFont(ofSize: 10, weight: .medium)
            xAxis.centerAxisLabelsEnabled = false
            applyRoundedRenderer()
        }
    private func applyRoundedRenderer() {
            let renderer = RoundedBarChartRenderer(
                dataProvider: barChartView,
                animator: barChartView.chartAnimator,
                viewPortHandler: barChartView.viewPortHandler
            )
            renderer.barCornerRadius = 10
            barChartView.renderer = renderer
        }

    func configure(item: HealthItem, theme: AppTheme) {
            self.theme = theme
            cardView.layer.cornerRadius = 16
            cardView.layer.borderWidth = 1
            cardView.layer.shadowOpacity = 0
            cardView.backgroundColor = theme.glassMedium
            cardView.layer.borderColor = theme.glassBorderLight.cgColor
            chevronImage.tintColor = theme.secondaryText
            titleLabel.text = item.title
            setStyledProgress(item.progress)
            let activityType = item.activityType()
            let color = colorForActivity(activityType)
            let iconName = iconForActivity(activityType)
            walkingImage.image = UIImage(systemName: iconName)
            walkingImage.contentMode = .scaleAspectFit
            walkingImage.tintColor = color
            setupChart(
                values: item.chartValues,
                labels: item.chartLabels,
                color: color
            )
            motivationLabel.text = item.motivation
        }
    
    private func setupChart(
        values: [Double],
        labels: [String],
        color: UIColor
    ) {

        applyRoundedRenderer()

        if let renderer = barChartView.renderer as? RoundedBarChartRenderer {
            renderer.accentGlassColor = color
        }

        let completeLabels = labels
        var completeValues = values

        if completeValues.count < completeLabels.count {
            completeValues += Array(
                repeating: 0,
                count: completeLabels.count - completeValues.count
            )
        }

        let entries = completeValues.enumerated().map {
            BarChartDataEntry(
                x: Double($0.offset),
                y: $0.element
            )
        }

        let dataSet = BarChartDataSet(entries: entries)

        dataSet.drawValuesEnabled = false
        dataSet.highlightEnabled = false
        dataSet.drawIconsEnabled = false

        let selectedIndex =
            completeValues.lastIndex(where: { $0 > 0 }) ?? 0

        dataSet.colors = completeValues.enumerated().map { index, value in

            if value == 0 {
                return .clear
            }

            if index == selectedIndex {
                return color.withAlphaComponent(1.0)
            }

            return color.withAlphaComponent(0.20)
        }

        let data = BarChartData(dataSet: dataSet)

        data.barWidth = 0.30

        barChartView.data = data

        barChartView.xAxis.axisMinimum = -0.5
        barChartView.xAxis.axisMaximum = Double(completeLabels.count) - 0.5
        barChartView.xAxis.granularity = 1
        barChartView.xAxis.labelCount = completeLabels.count

        barChartView.xAxis.valueFormatter =
            IndexAxisValueFormatter(values: completeLabels)

        if let maxValue = completeValues.max(), maxValue > 0 {

            barChartView.leftAxis.axisMinimum = 0
            barChartView.leftAxis.axisMaximum = maxValue * 1.25

        } else {

            barChartView.leftAxis.axisMinimum = 0
            barChartView.leftAxis.axisMaximum = 10
        }

        barChartView.notifyDataSetChanged()

        animateChartSmoothly()
    }
    
    private func animateChartSmoothly() {
            barChartView.layer.removeAllAnimations()

            barChartView.animate(
                xAxisDuration: 0.55,
                yAxisDuration: 0.75,
                easingOption: .easeInOutQuart
            )
            let transition = CATransition()
            transition.duration = 0.45
            transition.type = .fade
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            barChartView.layer.add(transition, forKey: "softChartFade")
        }
    private func mapToHealthActivityType(_ activityType: String) -> HealthActivityType {
        switch activityType.lowercased() {
        case "walking":
            return .walking
        case "exercise":
            return .exercise
        case "yoga":
            return .yoga
        default:
            return .walking
        }
      }
    private func iconForActivity(_ activityType: String) -> String {
            switch activityType {
            case "walking":
                return "figure.walk"
            case "exercise":
                return "dumbbell.fill"
            case "yoga":
                return "figure.yoga"
            default:
                return "figure.walk"
            }
        }
    private func colorForActivity(_ activityType: String) -> UIColor {
            switch activityType {
            case "walking":
                return RoutineType.walking.accentColor
            case "exercise":
                return RoutineType.exercise.accentColor
            case "yoga":
                return RoutineType.yoga.accentColor
            default:
                return .systemBlue
            }
        }
    private func setStyledProgress(_ text: String) {
        let attributed = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: text.count)
        attributed.addAttributes([
            .foregroundColor: UIColor.systemGray,
            .font: UIFont.systemFont(ofSize: 14, weight: .medium)
        ], range: fullRange)

        let numberPattern = #"^\d+(\.\d+)?"#
        if let regex = try? NSRegularExpression(pattern: numberPattern),
           let match = regex.firstMatch(in: text, range: fullRange) {
            attributed.addAttributes([
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
            ], range: match.range)
        }
        progressLabel.attributedText = attributed
    }
}
