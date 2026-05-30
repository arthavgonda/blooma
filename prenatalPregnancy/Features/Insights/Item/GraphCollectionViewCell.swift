//
//  WalkGraphCollectionViewCell.swift
//  weekselector
//
//  Created by GEU on 11/02/26.
//

import UIKit
import DGCharts

class GraphCollectionViewCell: UICollectionViewCell,ChartViewDelegate {
    
    @IBOutlet weak var dataView: UIView!
    @IBOutlet weak var walkImage:UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var value: UILabel!
    @IBOutlet weak var barChartView: BarChartView!
    var  theme : AppTheme!
    var onBarSelected: ((Int) -> Void)?
    private var currentEntryCount: Int = 0
    private var selectedBarIndex: Int = 0
    private var currentBaseColor: UIColor = .systemGreen
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupChartStyle()
        barChartView.delegate = self
    }
    
    private func setupChartStyle() {
        barChartView.noDataText = "No data available"
        barChartView.drawValueAboveBarEnabled = false
        barChartView.legend.enabled = false
        barChartView.rightAxis.enabled = false
        barChartView.doubleTapToZoomEnabled = false
        barChartView.pinchZoomEnabled = false
        barChartView.scaleXEnabled = false
        barChartView.scaleYEnabled = false
        barChartView.highlightPerTapEnabled = true
        barChartView.highlightPerDragEnabled = false
        barChartView.chartDescription.enabled = false
        barChartView.drawGridBackgroundEnabled = false
        barChartView.drawBarShadowEnabled = false
        barChartView.extraTopOffset = 28
        barChartView.extraBottomOffset = 8
        barChartView.extraLeftOffset = 4
        barChartView.extraRightOffset = 4
        barChartView.delegate = self
        let xAxis = barChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        xAxis.granularity = 1
        xAxis.centerAxisLabelsEnabled = false
        let leftAxis = barChartView.leftAxis
        leftAxis.drawGridLinesEnabled = false
        leftAxis.drawAxisLineEnabled = false
        leftAxis.axisMinimum = 0
        let renderer = RoundedBarChartRenderer(dataProvider: barChartView,animator: barChartView.chartAnimator,viewPortHandler: barChartView.viewPortHandler)
        renderer.barCornerRadius = 18
        barChartView.renderer = renderer
    }
    
    func showNoData(activity: ActivityType) {
        titleLabel.text = activity.title
        walkImage.image = UIImage(systemName: activity.icon)
        walkImage.tintColor = activity.normalColor
        subtitleLabel.text = "No Data Found"
        value.text = "--"
        currentEntryCount = 7
        selectedBarIndex = 0
        currentBaseColor = activity.normalColor
        let labels = ["M", "T", "W", "T", "F", "S", "S"]
        let entries = (0..<7).map { BarChartDataEntry(x: Double($0), y: 0) }
        let set = BarChartDataSet(entries: entries)
        set.colors = Array(repeating: activity.normalColor.withAlphaComponent(0.10), count: 7)
        set.drawValuesEnabled = false
        set.highlightEnabled = false
        let chartData = BarChartData(dataSet: set)
        chartData.barWidth = 0.32
        barChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        barChartView.xAxis.axisMinimum = -0.5
        barChartView.xAxis.axisMaximum = 6.5
        barChartView.leftAxis.axisMaximum = 1
        barChartView.data = chartData
        barChartView.fitBars = false
        barChartView.notifyDataSetChanged()
    }
    
    func configure(
        with data: InsightGraphSummary,
        activity: ActivityType,
        color: UIColor,
        theme: AppTheme,
        selectedBarIndex preferredSelectedBarIndex: Int? = nil
    ) {

        self.theme = theme

        contentView.backgroundColor = .clear
        backgroundColor = .clear

        dataView.subviews.forEach {
            if $0 is UIVisualEffectView {
                $0.removeFromSuperview()
            }
        }

        dataView.layer.cornerRadius = 28
        dataView.clipsToBounds = true

        dataView.backgroundColor = UIColor.white.withAlphaComponent(0.18)

        dataView.layer.borderWidth = 1.2
        dataView.layer.borderColor = UIColor.white.withAlphaComponent(0.55).cgColor

        let blur = UIBlurEffect(style: .systemThinMaterialLight)
        let blurView = UIVisualEffectView(effect: blur)

        blurView.frame = dataView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.layer.cornerRadius = 28
        blurView.clipsToBounds = true

        dataView.insertSubview(blurView, at: 0)

        titleLabel.text = activity.title
        walkImage.image = UIImage(systemName: activity.icon)
        walkImage.tintColor = color
        currentBaseColor = color
        subtitleLabel.text = data.metricTitle
        value.text = data.displayValue

        let labels = data.dayLabels
        let values = data.dayValues

        let entries = values.enumerated().map {
            BarChartDataEntry(x: Double($0.offset), y: $0.element)
        }

        selectedBarIndex = preferredSelectedBarIndex ?? values.lastIndex(where: { $0 > 0 }) ?? 0

        let set = BarChartDataSet(entries: entries)

        set.colors = makeColors(
            baseColor: color,
            selectedIndex: selectedBarIndex,
            values: values
        )

        set.drawValuesEnabled = false
        set.highlightEnabled = true
        set.highlightColor = .clear

        let chartData = BarChartData(dataSet: set)

        chartData.barWidth = 0.60

        barChartView.backgroundColor = .clear
        barChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        barChartView.xAxis.axisMinimum = -0.5
        barChartView.xAxis.axisMaximum = 6.5
        let maxValue = max(values.max() ?? 0, 1)
        barChartView.leftAxis.axisMaximum = maxValue * 1.25
        barChartView.data = chartData
        
        barChartView.drawBarShadowEnabled = false
        barChartView.drawValueAboveBarEnabled = false
        barChartView.highlightFullBarEnabled = false
        
        set.barShadowColor = .clear
        
        if let renderer = barChartView.renderer as? RoundedBarChartRenderer {
            renderer.accentGlassColor = color
        }

        barChartView.notifyDataSetChanged()
    }
    
    private func makeColors(
        baseColor: UIColor,
        selectedIndex: Int,
        values: [Double]
    ) -> [UIColor] {

        var colors: [UIColor] = []

        for i in 0..<values.count {

            if values[i] <= 0 {

                colors.append(.clear)

            } else if i == selectedIndex {

                colors.append(
                    baseColor.withAlphaComponent(1.0)
                )

            } else {

                colors.append(
                    baseColor.withAlphaComponent(0.20)
                )
            }
        }

        return colors
    }
    
    private func makeColors(baseColor: UIColor, selectedIndex: Int, count: Int) -> [UIColor] {
        var colors: [UIColor] = []
        for index in 0..<count {
            if index == selectedIndex {
                colors.append(baseColor)
            } else {
                colors.append(baseColor.withAlphaComponent(0.22))
            }
        }
        
        return colors
    }
    
    private func animateBarSelection(to selectedIndex: Int) {
        guard
            let data = barChartView.data,
            let dataSet = data.dataSets.first as? BarChartDataSet
        else { return }
        let values = dataSet.entries.map { $0.y }
        guard values.indices.contains(selectedIndex), values[selectedIndex] > 0 else { return }
        selectedBarIndex = selectedIndex
        UIView.transition(with: barChartView,duration: 0.35,options: .transitionCrossDissolve,animations: {dataSet.colors = self.makeColors(baseColor: self.currentBaseColor,selectedIndex: selectedIndex,values: values
            )
            self.barChartView.notifyDataSetChanged()
        })
        barChartView.highlightValue(x: Double(selectedIndex), dataSetIndex: 0, callDelegate: false)
        barChartView.animate(yAxisDuration: 0.25, easingOption: .easeInOutSine)
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let tappedIndex = Int(entry.x)
        guard
            let dataSet = barChartView.data?.dataSets.first as? BarChartDataSet,
            dataSet.entries.indices.contains(tappedIndex),
            dataSet.entries[tappedIndex].y > 0,
            tappedIndex != selectedBarIndex
        else { return }
        animateBarSelection(to: tappedIndex)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.onBarSelected?(tappedIndex)
        }
        
    }
    
    private func chartValueNothingSelected(_ chartView: ChartViewBase) -> Int? {
        return nil
    }
    
}
