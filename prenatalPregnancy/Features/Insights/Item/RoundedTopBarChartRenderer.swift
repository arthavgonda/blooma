//
//  RoundedBarChartRenderer.swift
//

import UIKit
@preconcurrency import DGCharts

final class RoundedBarChartRenderer: BarChartRenderer {

    nonisolated(unsafe) var barCornerRadius: CGFloat = 18
    nonisolated(unsafe) var accentGlassColor: UIColor = .systemPink

    nonisolated override init(
        dataProvider: BarChartDataProvider,
        animator: Animator,
        viewPortHandler: ViewPortHandler
    ) {
        super.init(
            dataProvider: dataProvider,
            animator: animator,
            viewPortHandler: viewPortHandler
        )
    }

    nonisolated override func drawDataSet(
        context: CGContext,
        dataSet: BarChartDataSetProtocol,
        index: Int
    ) {

        guard let dataProvider = dataProvider,
              let barData = dataProvider.barData else { return }

        let transformer = dataProvider.getTransformer(
            forAxis: dataSet.axisDependency
        )

        let phaseY = CGFloat(animator.phaseY)

        for i in 0..<dataSet.entryCount {

            guard let entry = dataSet.entryForIndex(i) as? BarChartDataEntry else {
                continue
            }

            let x = CGFloat(entry.x)
            let y = CGFloat(entry.y)

            let width = CGFloat(barData.barWidth)

            var rect = CGRect(
                x: x - width/2,
                y: 0,
                width: width,
                height: y * phaseY
            )

            transformer.rectValueToPixel(&rect)

            if rect.height <= 0 { continue }

            let radius = min(
                barCornerRadius,
                rect.width/2,
                rect.height/2
            )

            let path = UIBezierPath(
                roundedRect: rect,
                cornerRadius: radius
            )

            let originalColor = dataSet.color(atIndex: i)

            // FIXED RGB + ALPHA EXTRACTION
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0

            originalColor.getRed(
                &red,
                green: &green,
                blue: &blue,
                alpha: &alpha
            )

            let isSelected = alpha > 0.5

            context.saveGState()
            path.addClip()

            let gradientColors: [CGColor]

            if isSelected {

                gradientColors = [
                    adjustedColor(from: accentGlassColor.cgColor, by: 0.08, alpha: 0.88),
                    adjustedColor(from: accentGlassColor.cgColor, by: -0.08, alpha: 0.82)
                ]
            } else {

                gradientColors = [
                    adjustedColor(from: accentGlassColor.cgColor, by: 0.40, alpha: 0.22),
                    adjustedColor(from: accentGlassColor.cgColor, by: 0.15, alpha: 0.08)
                ]
            }

            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: gradientColors as CFArray,
                locations: [0,1]
            )!

            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: rect.midX, y: rect.minY),
                end: CGPoint(x: rect.midX, y: rect.maxY),
                options: []
            )

            context.restoreGState()

            context.setStrokeColor(
                CGColor(gray: 1.0, alpha: 0.18)
            )

            context.setLineWidth(0.8)

            context.addPath(path.cgPath)
            context.strokePath()
        }
    }
    
    private nonisolated func adjustedColor(from color: CGColor, by delta: CGFloat, alpha: CGFloat) -> CGColor {
        let converted = color.converted(
            to: CGColorSpaceCreateDeviceRGB(),
            intent: .defaultIntent,
            options: nil
        ) ?? color
        let components = converted.components ?? [0, 0, 0, 1]
        let redBase = components.indices.contains(0) ? components[0] : 0
        let greenBase = components.indices.contains(1) ? components[1] : 0
        let blueBase = components.indices.contains(2) ? components[2] : 0
        let red = min(max(redBase + delta, 0), 1)
        let green = min(max(greenBase + delta, 0), 1)
        let blue = min(max(blueBase + delta, 0), 1)
        
        return CGColor(
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            components: [red, green, blue, alpha]
        ) ?? color
    }
}
