//
//  ViewController.swift
//  healthPrenantalApp
//
//  Created by GEU on 06/02/26.
//
import UIKit
import HealthKit
import PDFKit

class ProgressViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    var dataController: DataController!
    var selectedPDFWeek: String?
    var theme: AppTheme!
    var selectedSegmentIndex: Int = 0
    var healthItems: [HealthItem] = []
    var insightsData: InsightsResponse?
    var selectedPDFWeeks: [String] = []
    private var progressObserver: NSObjectProtocol?

        override func viewDidLoad() {
            super.viewDidLoad()
            navigationItem.title = "Insights"
            registerCells()
            theme = dataController.theme
            applyAnimatedBackground(theme: theme)
            collectionView.backgroundColor = .clear
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.setCollectionViewLayout(generateLayout(), animated: false)
            observeProgressChanges()
//            dataController.loadDummyProgressDataUntilCurrentDay { [weak self] in
//                DispatchQueue.main.async {
//                    self?.reloadInsightsFromFirestore()
//                }
//            }
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            selectedSegmentIndex = 0
            reloadInsightsFromFirestore()
        }
    
    deinit {
        if let progressObserver {
            NotificationCenter.default.removeObserver(progressObserver)
        }
    }

    @IBAction func didTapShare(_ sender: Any) {
        performSegue(withIdentifier: "showInner", sender: sender)
    }
    func registerCells() {
            collectionView.register(
            UINib(nibName:"SectionHeaderReusableView",bundle:nil),forSupplementaryViewOfKind:UICollectionView.elementKindSectionHeader,withReuseIdentifier: "header"
            )

            collectionView.register(
                UINib(nibName: "HealthCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "health_cell"
            )
        }
    }

    extension ProgressViewController: UICollectionViewDataSource, UICollectionViewDelegate {

        func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            healthItems.count
        }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            performSegue(withIdentifier: "showGraph", sender: indexPath)
        }

        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "showGraph" {
                let vc = segue.destination as! GraphViewController
                if let indexPath = sender as? IndexPath {
                    vc.selectedActivityIndex = indexPath.row
                }
                vc.dataController = dataController
                vc.insightsData = insightsData
            }
            if segue.identifier == "showInner" {
                let nav = segue.destination as! UINavigationController
                let vc = nav.topViewController as! WeekPickerViewController

                vc.dataController = dataController
                vc.delegate = self

                nav.modalPresentationStyle = .pageSheet

                if let sheet = nav.sheetPresentationController {
                    sheet.detents = [
                        .custom { _ in
                            return 320
                        }
                    ]
                    sheet.preferredCornerRadius = 32
                }
            }
        }
        
        func drawBloomaWatermark(pageRect: CGRect) {
            let context = UIGraphicsGetCurrentContext()
            context?.saveGState()

            let watermarkText = "Blooma"

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 64, weight: .bold),
                .foregroundColor: UIColor.systemPink.withAlphaComponent(0.06),
                .paragraphStyle: paragraphStyle
            ]

            context?.translateBy(x: pageRect.midX, y: pageRect.midY)
            context?.rotate(by: -.pi / 6)

            let textRect = CGRect(
                x: -200,
                y: -40,
                width: 400,
                height: 80
            )

            watermarkText.draw(in: textRect, withAttributes: attributes)

            context?.restoreGState()
        }

        func collectionView(_ collectionView: UICollectionView,
                            cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

            let cell = collectionView.dequeueReusableCell( withReuseIdentifier: "health_cell", for: indexPath ) as! HealthCollectionViewCell
            cell.theme = dataController.theme
            cell.configure(item: healthItems[indexPath.row], theme: theme)
            return cell
        }

        func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
            guard kind == UICollectionView.elementKindSectionHeader else {
                return UICollectionReusableView()
            }
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind,withReuseIdentifier: "header",for: indexPath ) as! SectionHeaderReusableView
            header.progressLabel.text = "Current Week Progress"
            return header
        }

        func collectionView(_ collectionView: UICollectionView,willDisplay cell: UICollectionViewCell,forItemAt indexPath: IndexPath) {
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: 0, y: 30)

            UIView.animate(
                withDuration: 0.5,delay: Double(indexPath.item) * 0.05,usingSpringWithDamping: 0.85,initialSpringVelocity: 0.8,options: [],animations: {
                    cell.alpha = 1
                    cell.transform = .identity
                }
            )
        }
    }

    extension ProgressViewController: SectionHeaderReusableViewDelegate {
          func didChangeSegment(index: Int) {
            selectedSegmentIndex = index

            if index == 1 {
                performSegue(withIdentifier: "showVitals", sender: nil)
            }
        }
    }
extension ProgressViewController: WeekPickerViewControllerDelegate {

    func didSelectWeeks(_ weeks: [String]) {
        print("Received Weeks:", weeks)
        selectedPDFWeeks = weeks
        sharePDFForSelectedWeeks()
    }

    func sharePDFForSelectedWeeks() {
        print("Selected PDF Weeks:", selectedPDFWeeks)
         print("Insights Data Exists:", resolvedInsightsData() != nil)

         guard let pdfURL = generateInsightsPDFForSelectedWeeks() else {
             print("Failed to generate PDF")
             return
         }

         print("PDF URL:", pdfURL)

         let activityVC = UIActivityViewController(
             activityItems: [pdfURL],
             applicationActivities: nil
         )

         if let popover = activityVC.popoverPresentationController {
             popover.sourceView = self.view
             popover.sourceRect = CGRect(
                 x: self.view.bounds.midX,
                 y: self.view.bounds.midY,
                 width: 0,
                 height: 0
             )
         }

         present(activityVC, animated: true)
    }
}

extension ProgressViewController {

          func generateLayout() -> UICollectionViewLayout {
                UICollectionViewCompositionalLayout { _, _ in
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),heightDimension: .fractionalHeight(1)))
                let group = NSCollectionLayoutGroup.vertical(layoutSize:NSCollectionLayoutSize(widthDimension:.fractionalWidth(1),heightDimension: .absolute(160)),subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 8
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize:NSCollectionLayoutSize(widthDimension:.fractionalWidth(1),heightDimension:.absolute(60)),elementKind: UICollectionView.elementKindSectionHeader,alignment: .top)
                section.boundarySupplementaryItems = [header]
                return section
            }
        }
        
        func buildHealthItems(from response: InsightsResponse) -> [HealthItem] {
            let currentWeek = max(1, min(dataController?.userProfile.gestationalWeek ?? 1, PregnancyDateCalculation.maxGestationalWeek))
            let weekKey = "W\(currentWeek)"
            return response.insights.compactMap { insight in
                guard let week = insight.weeks.first(where: { $0.week == weekKey }) else {
                    return nil
                }
                let chartValues = weeklyValues(for: insight, week: week)
                let progress = progressText(for: insight, week: week)
                let subtitle = subtitleText(for: insight, week: week)
                return HealthItem(title: insight.title,progress: progress,subtitle: subtitle,motivation: motivationText(for: insight, week: week),chartValues: chartValues,chartLabels: ["M", "T", "W", "T", "F", "S", "S"])
            }
        }
        
        func motivationText(for insight: Insight, week: InsightWeek) -> String {
            let activityType = insight.activityType.lowercased()
            let (completed, target, type): (Double, Double, HealthActivityType)
            switch activityType {
            case "walking":
                let totalSteps = week.days.reduce(0.0) {
                    $0 + totalStat(named: "Steps", in: $1.sessions)
                }
                completed = totalSteps
                target = 8000
                type = .walking
            case "exercise":
                let totalReps = week.days.reduce(0.0) {
                    $0 + totalStat(named: "Reps", in: $1.sessions)
                }
                completed = totalReps
                target = 80
                type = .exercise
            case "yoga":
                let totalSessions = Double(week.days.reduce(0) {
                    $0 + $1.sessions.count
                })
                completed = totalSessions
                target = 8
                type = .yoga
            default:
                completed = 0
                target = 1
                type = .unknown
            }
            return MotivationText.text(activity: type,completed: completed,target: target)
        }
   
        func defaultPDFWeek() -> String {
            guard let insightsData = insightsData else {
                let gestationalWeek = max(1, min(dataController?.userProfile.gestationalWeek ?? 1, PregnancyDateCalculation.maxGestationalWeek))
                return "W\(gestationalWeek)"
            }
            let gestationalWeek = max(1, min(dataController?.userProfile.gestationalWeek ?? 1, PregnancyDateCalculation.maxGestationalWeek))
            let preferredWeek = "W\(gestationalWeek)"
            let allWeeks = Set(
                insightsData.insights.flatMap { insight in
                    insight.weeks.map { $0.week.uppercased() }
                }
            )
            if allWeeks.contains(preferredWeek.uppercased()) {
                return preferredWeek
            }
            let sortedWeeks = allWeeks.sorted {
                let first = Int($0.replacingOccurrences(of: "W", with: "")) ?? 0
                let second = Int($1.replacingOccurrences(of: "W", with: "")) ?? 0
                return first < second
            }
            return sortedWeeks.last ?? preferredWeek
        }

        func sharePDF(from sender: UIBarButtonItem) {
            guard let pdfURL = generateInsightsPDF() else {
                print("Failed to generate PDF")
                return
            }
            let activityVC = UIActivityViewController(activityItems: [pdfURL],
                applicationActivities: nil
            )
            if let popover = activityVC.popoverPresentationController {
                popover.barButtonItem = sender
            }
            present(activityVC, animated: true)
        }
        
        func latestWeek(for insight: Insight) -> InsightWeek? {
            return insight.weeks.last
        }
        
        func formattedDate(from dateString: String) -> String {
            let inputFormatter = DateFormatter()
            inputFormatter.dateFormat = "yyyy-MM-dd"
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "MMM dd, yyyy"
            guard let date = inputFormatter.date(from: dateString) else {
                return dateString
            }
            return outputFormatter.string(from: date)
        }
        
        func peakHeartRateForWeek(_ week: InsightWeek) -> Int {
            var maxPeakHeartRate = 0

            for day in week.days {
                for session in day.sessions {
                    if let peakHeartRate = session.vitals?.first(where: {
                        $0.title.lowercased() == "peak heart rate"
                    }) {
                        let value = Int(peakHeartRate.value) ?? 0
                        maxPeakHeartRate = max(maxPeakHeartRate, value)
                    }
                }
            }
            return maxPeakHeartRate
        }

        func peakRespiratoryRateForWeek(_ week: InsightWeek) -> Int {
            var maxPeakRespiratoryRate = 0
            for day in week.days {
                for session in day.sessions {
                    if let peakRespiratoryRate = session.vitals?.first(where: {
                        $0.title.lowercased() == "peak respiratory rate"
                    }) {
                        let value = Int(peakRespiratoryRate.value) ?? 0
                        maxPeakRespiratoryRate = max(maxPeakRespiratoryRate, value)
                    }
                }
            }
            return maxPeakRespiratoryRate
        }
        
        func statValue(title: String, from session: InsightSession) -> String {
            return session.stats.first(where: {
                $0.title.lowercased() == title.lowercased()
            })?.value ?? "-"
        }
        
        func vitalValue(title: String, from session: InsightSession) -> String {
            return session.vitals?.first(where: {
                $0.title.lowercased() == title.lowercased()
            })?.value ?? "-"
        }
        
        func generateInsightsPDF() -> URL? {
            guard let insightsData = insightsData else { return nil }
            let fileName = "Insights_Report.pdf"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 portrait
            let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

            do {
                try renderer.writePDF(to: tempURL) { context in
                    var currentPageNumber = 1
                    context.beginPage()
                    drawOverviewPage(in: context,pageRect: pageRect,insightsData: insightsData,pageNumber: currentPageNumber)
                    currentPageNumber += 1
                    for insight in insightsData.insights {
                        guard let week = currentWeek(for: insight) else { continue }
                        context.beginPage()
                        drawActivitySummaryPage(in: context,pageRect: pageRect,insight: insight,week: week,pageNumber: currentPageNumber)
                        currentPageNumber += 1
                        currentPageNumber = drawActivitySessionsPages(in: context,pageRect: pageRect,insight: insight,week: week,startingPageNumber: currentPageNumber)
                    }
                }
                return tempURL
            } catch {
                print("PDF generation failed: \(error)")
                return nil
            }
        }
    func generateInsightsPDFForSelectedWeeks() -> URL? {
        print("generateInsightsPDFForSelectedWeeks called")

        guard let insightsData = resolvedInsightsData() else {
            print("insightsData is nil")
            return nil
        }

        print("Insights count:", insightsData.insights.count)

        let fileName = "Insights_Report.pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        do {
            try renderer.writePDF(to: tempURL) { context in
                var currentPageNumber = 1

                let weeksToGenerate = selectedPDFWeeks.isEmpty ? [defaultPDFWeek()] : selectedPDFWeeks

                for weekKey in weeksToGenerate {
                    selectedPDFWeek = weekKey

                    context.beginPage()
                    drawOverviewPage(
                        in: context,
                        pageRect: pageRect,
                        insightsData: insightsData,
                        pageNumber: currentPageNumber
                    )
                    currentPageNumber += 1

                    for insight in insightsData.insights {
                        guard let week = currentWeek(for: insight) else { continue }

                        context.beginPage()
                        drawActivitySummaryPage(
                            in: context,
                            pageRect: pageRect,
                            insight: insight,
                            week: week,
                            pageNumber: currentPageNumber
                        )
                        currentPageNumber += 1

                        currentPageNumber = drawActivitySessionsPages(
                            in: context,
                            pageRect: pageRect,
                            insight: insight,
                            week: week,
                            startingPageNumber: currentPageNumber
                        )
                    }
                }
            }

            return tempURL
        } catch {
            print("PDF generation failed: \(error)")
            return nil
        }
    }
        
        func drawOverviewPage(in context: UIGraphicsPDFRendererContext,pageRect: CGRect,insightsData: InsightsResponse,pageNumber: Int) {
            let titleFont = UIFont.boldSystemFont(ofSize: 26)
            let subtitleFont = UIFont.systemFont(ofSize: 13)
            let cardTitleFont = UIFont.systemFont(ofSize: 11, weight: .medium)
            let cardValueFont = UIFont.boldSystemFont(ofSize: 20)
            let smallFont = UIFont.systemFont(ofSize: 11)
            let margin: CGFloat = 28
            UIColor.white.setFill()
            UIBezierPath(rect: pageRect).fill()
            drawBloomaWatermark(pageRect: pageRect)
            "Pregnancy Insights Report".draw(at: CGPoint(x: margin, y: 28),
                withAttributes: [
                    .font: titleFont,
                    .foregroundColor: UIColor.black
                ]
            )

            let currentDate = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)
            let selectedWeekText = selectedPDFWeek ?? "Current Week"
            "Weekly overview • \(selectedWeekText) • Generated on \(currentDate)".draw(
                at: CGPoint(x: margin, y: 64),
                withAttributes: [.font: subtitleFont,.foregroundColor: UIColor.darkGray]
            )
            var totalSteps: Double = 0
            var totalReps: Double = 0
            var totalYogaSessions: Int = 0
            var peakHeartRate: Int = 0
            var peakRespRate: Int = 0
            for insight in insightsData.insights {
                guard let week = currentWeek(for: insight) else { continue }
                switch insight.activityType.lowercased() {
                case "walking":
                    totalSteps += week.days.reduce(0) { $0 + totalStat(named: "Steps", in: $1.sessions) }
                case "exercise":
                    totalReps += week.days.reduce(0) { $0 + totalStat(named: "Reps", in: $1.sessions) }
                case "yoga":
                    totalYogaSessions += week.days.reduce(0) { $0 + $1.sessions.count }
                default:
                    break
                }
                peakHeartRate = max(peakHeartRate, peakHeartRateForWeek(week))
                peakRespRate = max(peakRespRate, peakRespiratoryRateForWeek(week))
            }
            let cards: [(String, String, UIColor)] = [
                ("Walking Steps", "\(Int(totalSteps))", .systemGreen),
                ("Exercise Reps", "\(Int(totalReps))", .systemPurple),
                ("Yoga Sessions", "\(totalYogaSessions)", .systemPink),
                ("Peak Heart Rate", "\(peakHeartRate) bpm", .systemRed)
            ]
            let cardY: CGFloat = 110
            let cardHeight: CGFloat = 78
            let cardSpacing: CGFloat = 12
            let cardWidth = (pageRect.width - margin * 2 - cardSpacing * 3) / 4
            for (index, card) in cards.enumerated() {
                let x = margin + CGFloat(index) * (cardWidth + cardSpacing)
                let rect = CGRect(x: x, y: cardY, width: cardWidth, height: cardHeight)
                drawMetricCard(rect: rect,title: card.0,value: card.1,accent: card.2,titleFont: cardTitleFont,valueFont: cardValueFont)
            }

            let leftChartRect = CGRect(x: margin, y: 225, width: pageRect.width - margin * 2, height: 220)
            drawOverviewActivityProgress(rect: leftChartRect,title: "Activity Progress",insightsData: insightsData)
            let rightRect = CGRect(x: margin,y: 475,width: pageRect.width - margin * 2,height: 200)
            drawOverviewVitalsSummary(rect: rightRect,title: "Vitals Summary",insightsData: insightsData)
            "This overview summarizes the current gestational week data across walking, exercise, yoga, and vital peaks."
                .draw(
                    in: CGRect(x: margin, y: 680, width: pageRect.width - margin * 2, height: 35),withAttributes: [
                        .font: smallFont,
                        .foregroundColor: UIColor.darkGray
                    ]
                )
            drawFooter(pageRect: pageRect, page: pageNumber)
        }
        
        func drawOverviewActivityProgress(rect: CGRect,title: String,insightsData: InsightsResponse) {
            let bg = UIBezierPath(roundedRect: rect, cornerRadius: 18)
            UIColor(white: 0.98, alpha: 1).setFill()
            bg.fill()
            title.draw(
                at: CGPoint(x: rect.minX + 14, y: rect.minY + 12),withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 15),
                    .foregroundColor: UIColor.black
                ]
            )
            var walkingSteps: Double = 0
            var exerciseReps: Double = 0
            var yogaSessions: Double = 0
            for insight in insightsData.insights {
                guard let week = currentWeek(for: insight) else { continue }
                switch insight.activityType.lowercased() {
                case "walking":
                    walkingSteps = week.days.reduce(0) { $0 + totalStat(named: "Steps", in: $1.sessions) }
                case "exercise":
                    exerciseReps = week.days.reduce(0) { $0 + totalStat(named: "Reps", in: $1.sessions) }
                case "yoga":
                    yogaSessions = Double(week.days.reduce(0) { $0 + $1.sessions.count })
                default:
                    break
                }
            }
            let items: [(title: String, value: Double, goal: Double, unit: String, color: UIColor)] = [("Walking", walkingSteps, 8000, "steps", .systemGreen),("Exercise", exerciseReps, 300, "reps", .systemPurple),("Yoga", yogaSessions, 28, "sessions", .systemPink)
            ]
            let rowHeight: CGFloat = 52
            let startY = rect.minY + 48
            for (index, item) in items.enumerated() {
                let y = startY + CGFloat(index) * rowHeight
                let progress = item.goal > 0 ? min(item.value / item.goal, 1.0) : 0
                item.title.draw(at: CGPoint(x: rect.minX + 18, y: y),withAttributes: [
                        .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                        .foregroundColor: UIColor.black
                    ]
                )
                let valueText = "\(Int(item.value)) / \(Int(item.goal)) \(item.unit)"
                valueText.draw(
                    at: CGPoint(x: rect.minX + 18, y: y + 18),withAttributes: [
                        .font: UIFont.systemFont(ofSize: 10),
                        .foregroundColor: UIColor.darkGray
                    ]
                )
                let trackX = rect.minX + 170
                let trackY = y + 16
                let trackWidth = rect.width - 250
                let trackHeight: CGFloat = 12
                let trackRect = CGRect(x: trackX, y: trackY, width: trackWidth, height: trackHeight)
                UIColor.systemGray5.setFill()
                UIBezierPath(roundedRect: trackRect, cornerRadius: 6).fill()
                let fillRect = CGRect(x: trackX, y: trackY, width: trackWidth * CGFloat(progress), height: trackHeight)
                item.color.setFill()
                UIBezierPath(roundedRect: fillRect, cornerRadius: 6).fill()
                let percentText = "\(Int(progress * 100))%"
                percentText.draw(
                    at: CGPoint(x: rect.maxX - 52, y: y + 10),withAttributes: [
                        .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                        .foregroundColor: UIColor.darkGray
                    ]
                )
            }
        }
        
        func drawActivitySummaryPage(in context: UIGraphicsPDFRendererContext,pageRect: CGRect,insight: Insight,week: InsightWeek,pageNumber: Int) {
            let margin: CGFloat = 28
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let subtitleFont = UIFont.systemFont(ofSize: 13)
            let accent: UIColor
            switch insight.activityType.lowercased() {
            case "walking":
                accent = .systemGreen
            case "exercise":
                accent = .systemPurple
            case "yoga":
                accent = .systemPink
            default:
                accent = .systemBlue
            }
            UIColor.white.setFill()
            UIBezierPath(rect: pageRect).fill()
            drawBloomaWatermark(pageRect: pageRect)
            insight.title.draw(at: CGPoint(x: margin, y: 28),withAttributes: [.font: titleFont,.foregroundColor: accent]
            )
            "Week: \(week.week) • Summary".draw(at: CGPoint(x: margin, y: 60),
                withAttributes: [
                    .font: subtitleFont,
                    .foregroundColor: UIColor.darkGray
                ]
            )
            let progress = progressText(for: insight, week: week)
            let peakHeart = peakHeartRateForWeek(week)
            let peakResp = peakRespiratoryRateForWeek(week)
            let cards: [(String, String)] = [("Today", progress),("Peak Heart Rate", "\(peakHeart) bpm"),("Peak Respiratory", "\(peakResp) bpm")]
            let cardY: CGFloat = 100
            let cardHeight: CGFloat = 72
            let cardSpacing: CGFloat = 12
            let cardWidth = (pageRect.width - margin * 2 - cardSpacing * 2) / 3
            for (index, card) in cards.enumerated() {
                let x = margin + CGFloat(index) * (cardWidth + cardSpacing)
                let rect = CGRect(x: x, y: cardY, width: cardWidth, height: cardHeight)
                drawSimpleInfoCard(rect: rect, title: card.0, value: card.1, accent: accent)
            }
            let barChartRect = CGRect(x: margin, y: 280, width: pageRect.width - margin * 2, height: 220)
            drawWeeklyBarChart(rect: barChartRect,title: "\(insight.title) Weekly Trend",values: weeklyValues(for: insight, week: week),labels: ["M", "T", "W", "T", "F", "S", "S"],accent: accent,valueSuffix: chartUnitSuffix(for: insight))
            let heartRect = CGRect(x: margin, y: 530, width: pageRect.width - margin * 2, height: 118)
            drawLineChart(rect: heartRect,title: "Heart Rate Trend",values: weeklyHeartRateValues(for: week),labels: ["M", "T", "W", "T", "F", "S", "S"],lineColor: .systemRed,maxReference: 180)
            let respRect = CGRect(x: margin, y: 672, width: pageRect.width - margin * 2, height: 118)
            drawLineChart(rect: respRect,title: "Respiratory Trend",values: weeklyRespiratoryValues(for: week),labels: ["M", "T", "W", "T", "F", "S", "S"],lineColor: .systemBlue,maxReference: 40)
            drawFooter(pageRect: pageRect, page: pageNumber)
        }
        func drawActivitySessionsPage(pageRect: CGRect,insight: Insight,week: InsightWeek,rows: [[String]],pageNumber: Int,sessionPageIndex: Int,totalRows: Int) {
            let margin: CGFloat = 28
            let titleFont = UIFont.boldSystemFont(ofSize: 22)
            let subtitleFont = UIFont.systemFont(ofSize: 13)
            let smallFont = UIFont.systemFont(ofSize: 11)

            let accent: UIColor
            switch insight.activityType.lowercased() {
            case "walking":
                accent = .systemGreen
            case "exercise":
                accent = .systemPurple
            case "yoga":
                accent = .systemPink
            default:
                accent = .systemBlue
            }

            UIColor.white.setFill()
            UIBezierPath(rect: pageRect).fill()
            drawBloomaWatermark(pageRect: pageRect)

            "\(insight.title) Sessions".draw(at: CGPoint(x: margin, y: 28),withAttributes: [.font: titleFont,.foregroundColor: accent]
            )

            "Week: \(week.week) • Session details • Part \(sessionPageIndex)".draw(at: CGPoint(x: margin, y: 60),withAttributes: [.font: subtitleFont,.foregroundColor: UIColor.darkGray])

            let summaryText = "Showing \(rows.count) sessions on this page • Total weekly sessions: \(totalRows)"
            summaryText.draw(at: CGPoint(x: margin, y: 84),withAttributes: [.font: smallFont,.foregroundColor: UIColor.gray])

            drawSessionsTablePage(startY: 118,pageWidth: pageRect.width,rows: rows,accent: accent)
            drawFooter(pageRect: pageRect, page: pageNumber)
        }
        func drawActivitySessionsPages(in context: UIGraphicsPDFRendererContext,pageRect: CGRect,insight: Insight,week: InsightWeek,startingPageNumber: Int) -> Int {
            let allRows = sessionRows(for: week)
            guard !allRows.isEmpty else { return startingPageNumber }
            let rowsPerPage = 18
            var startIndex = 0
            var currentPageNumber = startingPageNumber
            var sessionPageIndex = 1
            while startIndex < allRows.count {
                context.beginPage()
                let endIndex = min(startIndex + rowsPerPage, allRows.count)
                let chunk = Array(allRows[startIndex..<endIndex])
                drawActivitySessionsPage(pageRect: pageRect,insight: insight,week: week,rows: chunk,pageNumber: currentPageNumber,sessionPageIndex: sessionPageIndex,totalRows: allRows.count)
                startIndex = endIndex
                currentPageNumber += 1
                sessionPageIndex += 1
            }
            return currentPageNumber
        }
     
        func drawSessionsTablePage(startY: CGFloat,pageWidth: CGFloat,rows: [[String]],accent: UIColor) {
            let headers = ["Date", "Session", "Time", "Calories", "Heart Rate"]
            let startX: CGFloat = 28
            let usableWidth = pageWidth - (startX * 2)
            let columnWidths: [CGFloat] = [usableWidth * 0.18,usableWidth * 0.30,usableWidth * 0.22,usableWidth * 0.15,usableWidth * 0.15]
            let headerHeight: CGFloat = 34
            let rowHeight: CGFloat = 32
            var x = startX
            var y = startY
            for (index, header) in headers.enumerated() {
                let rect = CGRect(x: x, y: y, width: columnWidths[index], height: headerHeight)
                accent.withAlphaComponent(0.12).setFill()
                UIBezierPath(roundedRect: rect, cornerRadius: 6).fill()
                UIColor.systemGray4.setStroke()
                UIBezierPath(rect: rect).stroke()
                header.draw(in: CGRect(x: x + 10, y: y + 9, width: columnWidths[index] - 16, height: 18),withAttributes: [.font: UIFont.boldSystemFont(ofSize: 11),.foregroundColor: UIColor.black]
                )
                x += columnWidths[index]
            }
            y += headerHeight
            for (rowIndex, row) in rows.enumerated() {
                var x = startX
                for (index, value) in row.enumerated() {
                    let rect = CGRect(x: x, y: y, width: columnWidths[index], height: rowHeight)
                    let fillColor: UIColor = rowIndex % 2 == 0 ? .white : UIColor(white: 0.985, alpha: 1)
                    fillColor.setFill()
                    UIBezierPath(rect: rect).fill()
                    UIColor.systemGray5.setStroke()
                    UIBezierPath(rect: rect).stroke()
                    value.draw(in: CGRect(x: x + 10, y: y + 8, width: columnWidths[index] - 16, height: 16),withAttributes: [.font: UIFont.systemFont(ofSize: 10),.foregroundColor: UIColor.darkGray])
                    x += columnWidths[index]
                }
                y += rowHeight
            }
        }
        
        func sessionRows(for week: InsightWeek) -> [[String]] {
            var rows: [[String]] = []
            for day in week.days {
                for session in day.sessions {
                    let calories = statValue(title: "Calories", from: session)
                    let peakHR = vitalValue(title: "Peak Heart Rate", from: session)
                    rows.append([formattedDate(from: day.dayKey),session.sessionTitle,session.time,"\(calories) kcal","\(peakHR) bpm"])
                }
            }

            return rows
        }
        
        
        
        func weeklyHeartRateValues(for week: InsightWeek) -> [CGFloat] {
            var values = Array(repeating: CGFloat(0), count: 7)
            for day in week.days {
                guard let index = chartIndex(for: day.dayKey) else { continue }
                let value = CGFloat(day.sessions.compactMap {
                    Int(vitalValue(title: "Peak Heart Rate", from: $0))
                }.max() ?? 0)
                values[index] = value
            }
            return values
        }

        func weeklyRespiratoryValues(for week: InsightWeek) -> [CGFloat] {
            var values = Array(repeating: CGFloat(0), count: 7)
            for day in week.days {
                guard let index = chartIndex(for: day.dayKey) else { continue }
                let value = CGFloat(day.sessions.compactMap {
                    Int(vitalValue(title: "Peak Respiratory Rate", from: $0))
                }.max() ?? 0)
                values[index] = value
            }

            return values
        }
        func peakHeartRateDetails(for week: InsightWeek) -> (value: Int, date: String, session: String)? {
            var best: (value: Int, date: String, session: String)?
            for day in week.days {
                for session in day.sessions {
                    guard let vital = session.vitals?.first(where: {
                        $0.title.lowercased() == "peak heart rate"
                    }) else { continue }
                    let value = Int(vital.value) ?? 0
                    if best == nil || value > best!.value {
                        best = (value: value,date: formattedDate(from: day.dayKey),session: session.sessionTitle)
                    }
                }
            }

            return best
        }

        func peakRespiratoryRateDetails(for week: InsightWeek) -> (value: Int, date: String, session: String)? {
            var best: (value: Int, date: String, session: String)?
            for day in week.days {
                for session in day.sessions {
                    guard let vital = session.vitals?.first(where: {
                        $0.title.lowercased() == "peak respiratory rate"
                    }) else { continue }
                    let value = Int(vital.value) ?? 0
                    if best == nil || value > best!.value {
                        best = (
                            value: value,
                            date: formattedDate(from: day.dayKey),
                            session: session.sessionTitle
                        )
                    }
                }
            }

            return best
        }
        
        func drawMetricCard(rect: CGRect,title: String,value: String,accent: UIColor,titleFont: UIFont,valueFont: UIFont) {
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 18)
            UIColor(white: 0.97, alpha: 1).setFill()
            path.fill()
            let accentRect = CGRect(x: rect.minX, y: rect.minY, width: 6, height: rect.height)
            accent.setFill()
            UIBezierPath(roundedRect: accentRect,byRoundingCorners: [.topLeft, .bottomLeft],cornerRadii: CGSize(width: 18, height: 18)).fill()
            title.draw(in: CGRect(x: rect.minX + 14, y: rect.minY + 12, width: rect.width - 20, height: 18),withAttributes: [.font: titleFont,.foregroundColor: UIColor.darkGray])
            value.draw(in: CGRect(x: rect.minX + 14, y: rect.minY + 34, width: rect.width - 20, height: 34),withAttributes: [.font: valueFont,.foregroundColor: accent])
        }
        
        func drawFooter(pageRect: CGRect, page: Int) {
            let footerHeight: CGFloat = 26
            let footerBottomPadding: CGFloat = 14
            let footerY = pageRect.height - footerHeight - footerBottomPadding
            let footerRect = CGRect(x: 28,y: footerY,width: pageRect.width - 56,height: footerHeight)
            let footerPath = UIBezierPath(roundedRect: footerRect, cornerRadius: 12)
            UIColor(white: 0.97, alpha: 1).setFill()
            footerPath.fill()
            UIColor.systemGray5.setStroke()
            footerPath.lineWidth = 0.8
            footerPath.stroke()
            let currentDate = DateFormatter.localizedString(from: Date(),dateStyle: .medium,timeStyle: .none)
            let leftText = "Generated on \(currentDate)"
            let rightText = "Page \(page)"
            leftText.draw(in: CGRect(x: footerRect.minX + 14, y: footerRect.minY + 6, width: 220, height: 14),withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .medium),.foregroundColor: UIColor.darkGray])
            rightText.draw(in: CGRect(x: footerRect.maxX - 70, y: footerRect.minY + 6, width: 60, height: 14),withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold),.foregroundColor: UIColor.gray])
        }
        
        func drawSimpleInfoCard(rect: CGRect, title: String, value: String, accent: UIColor) {
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 16)
            UIColor(white: 0.97, alpha: 1).setFill()
            path.fill()
            UIColor.systemGray5.setStroke()
            path.lineWidth = 1
            path.stroke()
            title.draw(in: CGRect(x: rect.minX + 12, y: rect.minY + 10, width: rect.width - 24, height: 18),withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .medium),.foregroundColor: UIColor.darkGray])

            value.draw(in: CGRect(x: rect.minX + 12, y: rect.minY + 32, width: rect.width - 24, height: 30),withAttributes: [.font: UIFont.boldSystemFont(ofSize: 18),.foregroundColor: accent])
        }
        
        func drawWeeklyBarChart(rect: CGRect,title: String,values: [Double],labels: [String],accent: UIColor,valueSuffix: String) {
            title.draw(at: CGPoint(x: rect.minX, y: rect.minY - 22),withAttributes: [.font: UIFont.boldSystemFont(ofSize: 14),.foregroundColor: UIColor.black])
            let chartInset: CGFloat = 28
            let chartRect = rect.insetBy(dx: chartInset, dy: 18)
            let bg = UIBezierPath(roundedRect: rect, cornerRadius: 16)
            UIColor(white: 0.98, alpha: 1).setFill()
            bg.fill()
            let maxValue = max(values.max() ?? 1, 1)
            let gridLines = 4
            for i in 0...gridLines {
                let ratio = CGFloat(i) / CGFloat(gridLines)
                let y = chartRect.maxY - ratio * chartRect.height
                let linePath = UIBezierPath()
                linePath.move(to: CGPoint(x: chartRect.minX, y: y))
                linePath.addLine(to: CGPoint(x: chartRect.maxX, y: y))
                UIColor.systemGray5.setStroke()
                linePath.lineWidth = 0.8
                linePath.stroke()
                let labelValue = Int((Double(i) / Double(gridLines)) * maxValue)
                "\(labelValue)".draw(at: CGPoint(x: rect.minX + 4, y: y - 7),withAttributes: [.font: UIFont.systemFont(ofSize: 9),.foregroundColor: UIColor.gray]
                )
            }

            let barWidth = chartRect.width / CGFloat(values.count * 2)
            let spacing = barWidth
            let maxIndex = values.firstIndex(of: maxValue) ?? 0
            for (index, value) in values.enumerated() {
                let normalizedHeight = CGFloat(value / maxValue) * chartRect.height
                let x = chartRect.minX + CGFloat(index) * (barWidth + spacing) + spacing / 2
                let y = chartRect.maxY - normalizedHeight
                let barRect = CGRect(x: x, y: y, width: barWidth, height: normalizedHeight)
                let color = index == maxIndex ? accent : accent.withAlphaComponent(0.45)
                color.setFill()
                UIBezierPath(roundedRect: barRect, cornerRadius: 8).fill()
                labels[index].draw(at: CGPoint(x: x + 4, y: chartRect.maxY + 6),withAttributes: [.font: UIFont.systemFont(ofSize: 10),.foregroundColor: UIColor.darkGray])
                if value > 0 {"\(Int(value))\(valueSuffix)".draw(at: CGPoint(x: x - 4, y: y - 16),withAttributes: [.font: UIFont.systemFont(ofSize: 9),.foregroundColor: UIColor.darkGray])
                }
            }
        }
        
        func drawLineChart(rect: CGRect,title: String,values: [CGFloat],labels: [String],lineColor: UIColor,maxReference: CGFloat) {
            let bg = UIBezierPath(roundedRect: rect, cornerRadius: 16)
            UIColor(white: 0.98, alpha: 1).setFill()
            bg.fill()
            title.draw(
                at: CGPoint(x: rect.minX + 18, y: rect.minY + 12),
                withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: UIColor.black
                ]
            )
            let positiveValues = values.filter { $0 > 0 }
            let effectiveMax: CGFloat = {
                guard let peak = positiveValues.max() else { return maxReference }
                return max(maxReference, ceil((peak * 1.1) / 10) * 10)
            }()
            let chartRect = CGRect(
                x: rect.minX + 34,
                y: rect.minY + 36,
                width: rect.width - 52,
                height: rect.height - 60
            )
            for i in 0...4 {
                let ratio = CGFloat(i) / 4.0
                let y = chartRect.maxY - ratio * chartRect.height
                let path = UIBezierPath()
                path.move(to: CGPoint(x: chartRect.minX, y: y))
                path.addLine(to: CGPoint(x: chartRect.maxX, y: y))
                UIColor.systemGray5.setStroke()
                path.lineWidth = 0.8
                path.stroke()
                let labelValue = Int(ratio * effectiveMax)
                "\(labelValue)".draw(at: CGPoint(x: rect.minX + 3, y: y - 7),withAttributes: [.font: UIFont.systemFont(ofSize: 9),.foregroundColor: UIColor.gray])
            }
            guard !values.isEmpty else { return }
            let stepX = values.count > 1 ? chartRect.width / CGFloat(values.count - 1) : 0
            let line = UIBezierPath()
            var peakIndex: Int?
            var peakValue: CGFloat = 0
            var hasActiveSegment = false
            for (index, value) in values.enumerated() {
                if value > peakValue {
                    peakValue = value
                    peakIndex = index
                }
                guard value > 0 else {
                    hasActiveSegment = false
                    continue
                }
                let x = chartRect.minX + CGFloat(index) * stepX
                let y = chartRect.maxY - (value / effectiveMax) * chartRect.height
                let point = CGPoint(x: x, y: y)
                if !hasActiveSegment {
                    line.move(to: point)
                    hasActiveSegment = true
                } else {
                    line.addLine(to: point)
                }
            }
            lineColor.setStroke()
            line.lineWidth = 2.5
            line.stroke()
            for (index, value) in values.enumerated() {
                let x = chartRect.minX + CGFloat(index) * stepX
                labels[index].draw(at: CGPoint(x: x - 4, y: chartRect.maxY + 6),withAttributes: [.font: UIFont.systemFont(ofSize: 10),.foregroundColor: UIColor.darkGray])
                guard value > 0 else { continue }
                let y = chartRect.maxY - (value / effectiveMax) * chartRect.height
                let point = CGPoint(x: x, y: y)
                let isPeakPoint = index == peakIndex
                let radius: CGFloat = isPeakPoint ? 5 : 3
                let fillColor = isPeakPoint ? lineColor : lineColor.withAlphaComponent(0.7)
                fillColor.setFill()
                UIBezierPath(arcCenter: point,radius: radius,startAngle: 0,endAngle: .pi * 2,clockwise: true).fill()
            }

            if peakValue > 0, let peakIndex {
                let peakText = "Peak \(Int(peakValue))"
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9, weight: .medium),
                    .foregroundColor: UIColor.black
                ]
                let peakPoint = CGPoint(
                    x: chartRect.minX + CGFloat(peakIndex) * stepX,
                    y: chartRect.maxY - (peakValue / effectiveMax) * chartRect.height
                )
                let peakTextSize = peakText.size(withAttributes: attributes)
                var labelX = peakPoint.x + 8
                if labelX + peakTextSize.width > chartRect.maxX {
                    labelX = peakPoint.x - peakTextSize.width - 8
                }
                labelX = max(chartRect.minX, min(labelX, chartRect.maxX - peakTextSize.width))
                var labelY = peakPoint.y - peakTextSize.height - 6
                if labelY < chartRect.minY + 2 {
                    labelY = min(chartRect.maxY - peakTextSize.height, peakPoint.y + 8)
                }
                peakText.draw(
                    at: CGPoint(x: labelX, y: labelY),
                    withAttributes: attributes
                )
            }
        }
        
        func drawOverviewBarComparison(rect: CGRect,title: String,insightsData: InsightsResponse
        ) {
            var walkingSteps: Double = 0
            var exerciseReps: Double = 0
            var yogaSessions: Double = 0
            for insight in insightsData.insights {
                guard let week = currentWeek(for: insight) else { continue }
                switch insight.activityType.lowercased() {
                case "walking":
                    walkingSteps = week.days.reduce(0) {
                        $0 + totalStat(named: "Steps", in: $1.sessions)
                    }

                case "exercise":
                    exerciseReps = week.days.reduce(0) {
                        $0 + totalStat(named: "Reps", in: $1.sessions)
                    }

                case "yoga":
                    yogaSessions = Double(week.days.reduce(0) {
                        $0 + $1.sessions.count
                    })

                default:
                    break
                }
            }

            let walkingGoal: Double = 8000
            let exerciseGoal: Double = 300
            let yogaGoal: Double = 28
            let normalizedValues: [Double] = [
                min(walkingSteps / walkingGoal, 1.0),
                min(exerciseReps / exerciseGoal, 1.0),
                min(yogaSessions / yogaGoal, 1.0)
            ]

            let rawValues: [String] = ["\(Int(walkingSteps))","\(Int(exerciseReps))","\(Int(yogaSessions))"]
            let labels = ["Walking", "Exercise", "Yoga"]
            let colors: [UIColor] = [.systemGreen, .systemPurple, .systemPink]
            let bg = UIBezierPath(roundedRect: rect, cornerRadius: 18)
            UIColor(white: 0.98, alpha: 1).setFill()
            bg.fill()

            title.draw(at: CGPoint(x: rect.minX + 14, y: rect.minY + 12),withAttributes: [.font: UIFont.boldSystemFont(ofSize: 15),.foregroundColor: UIColor.black])

            let chartRect = CGRect(x: rect.minX + 20,y: rect.minY + 50,width: rect.width - 40,height: rect.height - 80)

            let barWidth: CGFloat = 56
            let gap: CGFloat = 52

            for i in 0..<normalizedValues.count {
                let x = chartRect.minX + CGFloat(i) * (barWidth + gap)
                let height = CGFloat(normalizedValues[i]) * chartRect.height
                let y = chartRect.maxY - height

                colors[i].setFill()
                UIBezierPath(roundedRect: CGRect(x: x, y: y, width: barWidth, height: height),cornerRadius: 10).fill()

                labels[i].draw(at: CGPoint(x: x - 4, y: chartRect.maxY + 8),withAttributes: [.font: UIFont.systemFont(ofSize: 11),.foregroundColor: UIColor.darkGray])

                rawValues[i].draw(at: CGPoint(x: x - 2, y: y - 18),withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .medium),.foregroundColor: UIColor.darkGray])
            }
        }
        
        func drawOverviewVitalsSummary(rect: CGRect,title: String,insightsData: InsightsResponse) {
            let bg = UIBezierPath(roundedRect: rect, cornerRadius: 18)
            UIColor(white: 0.98, alpha: 1).setFill()
            bg.fill()

            title.draw(at: CGPoint(x: rect.minX + 14, y: rect.minY + 12),withAttributes: [.font: UIFont.boldSystemFont(ofSize: 15),.foregroundColor: UIColor.black])

            var bestHeart: (value: Int, date: String, session: String)?
            var bestResp: (value: Int, date: String, session: String)?

            for insight in insightsData.insights {
                guard let week = currentWeek(for: insight) else { continue }

                if let heart = peakHeartRateDetails(for: week) {
                    if bestHeart == nil || heart.value > bestHeart!.value {
                        bestHeart = heart
                    }
                }

                if let resp = peakRespiratoryRateDetails(for: week) {
                    if bestResp == nil || resp.value > bestResp!.value {
                        bestResp = resp
                    }
                }
            }

            if let bestHeart = bestHeart {
                "Highest Heart Rate: \(bestHeart.value) bpm".draw(at: CGPoint(x: rect.minX + 18, y: rect.minY + 52),withAttributes: [.font: UIFont.systemFont(ofSize: 13, weight: .medium),.foregroundColor: UIColor.systemRed])

            "Occurred on \(bestHeart.date) during \(bestHeart.session)".draw(in: CGRect(x: rect.minX + 18,y: rect.minY + 78,width: rect.width - 36,height: 20),withAttributes: [.font: UIFont.systemFont(ofSize: 11),.foregroundColor: UIColor.darkGray]
                )
            }

            if let bestResp = bestResp {
                "Highest Respiratory Rate: \(bestResp.value) bpm".draw(
                    at: CGPoint(x: rect.minX + 18, y: rect.minY + 112),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 13, weight: .medium),
                        .foregroundColor: UIColor.systemBlue
                    ]
                )

                "Occurred on \(bestResp.date) during \(bestResp.session)".draw(
                    in: CGRect(
                        x: rect.minX + 18,
                        y: rect.minY + 138,
                        width: rect.width - 36,
                        height: 20
                    ),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 11),
                        .foregroundColor: UIColor.darkGray
                    ]
                )
            }

            let info = """
            This summary highlights the strongest cardiovascular and respiratory peaks recorded in the current week across all activity types.
            """

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            paragraphStyle.firstLineHeadIndent = 0
            paragraphStyle.headIndent = 0
            paragraphStyle.lineBreakMode = .byWordWrapping

            info.draw(
                in: CGRect(
                    x: rect.minX + 18,
                    y: rect.minY + 168,
                    width: rect.width - 36,
                    height: 42
                ),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.darkGray,
                    .paragraphStyle: paragraphStyle
                ]
            )
        }
        func drawSessionsTable(
            startY: CGFloat,
            pageWidth: CGFloat,
            week: InsightWeek,
            accent: UIColor
        ) {
            let headers = ["Date", "Session", "Time", "Calories", "Heart Rate"]
            let columnWidths: [CGFloat] = [120, 210, 170, 110, 120]
            let startX: CGFloat = 28

            var x = startX
            for (index, header) in headers.enumerated() {
                let rect = CGRect(x: x, y: startY, width: columnWidths[index], height: 30)
                accent.withAlphaComponent(0.12).setFill()
                UIBezierPath(rect: rect).fill()

                UIColor.systemGray4.setStroke()
                UIBezierPath(rect: rect).stroke()

                header.draw(
                    in: CGRect(x: x + 8, y: startY + 8, width: columnWidths[index] - 12, height: 18),
                    withAttributes: [
                        .font: UIFont.boldSystemFont(ofSize: 11),
                        .foregroundColor: UIColor.black
                    ]
                )

                x += columnWidths[index]
            }

            var y = startY + 30

            for day in week.days {
                for session in day.sessions {
                    let calories = statValue(title: "Calories", from: session)
                    let peakHR = vitalValue(title: "Peak Heart Rate", from: session)

                    let values = [
                        formattedDate(from: day.dayKey),
                        session.sessionTitle,
                        session.time,
                        "\(calories) kcal",
                        "\(peakHR) bpm"
                    ]

                    var x = startX
                    for (index, value) in values.enumerated() {
                        let rect = CGRect(x: x, y: y, width: columnWidths[index], height: 28)
                        UIColor.white.setFill()
                        UIBezierPath(rect: rect).fill()

                        UIColor.systemGray5.setStroke()
                        UIBezierPath(rect: rect).stroke()

                        value.draw(
                            in: CGRect(x: x + 6, y: y + 7, width: columnWidths[index] - 10, height: 16),
                            withAttributes: [
                                .font: UIFont.systemFont(ofSize: 10),
                                .foregroundColor: UIColor.darkGray
                            ]
                        )

                        x += columnWidths[index]
                    }

                    y += 28

                    if y > 545 { break }
                }
                if y > 545 { break }
            }
        }
        func currentWeek(for insight: Insight) -> InsightWeek? {
            let weekKey: String

            if let selectedPDFWeek = selectedPDFWeek {
                weekKey = selectedPDFWeek
            } else {
                let gestationalWeek = max(1, min(dataController?.userProfile.gestationalWeek ?? 1, PregnancyDateCalculation.maxGestationalWeek))
                weekKey = "W\(gestationalWeek)"
            }

            return insight.weeks.first(where: {
                $0.week.caseInsensitiveCompare(weekKey) == .orderedSame
            })
        }

        func resolvedInsightsData() -> InsightsResponse? {
            if let insightsData {
                return insightsData
            }

            if let bundled = dataController.loadInsightsResponse() {
                insightsData = bundled
                return bundled
            }

            let fallbackWeeks = selectedPDFWeeks.isEmpty
                ? [max(1, min(dataController?.userProfile.gestationalWeek ?? 1, PregnancyDateCalculation.maxGestationalWeek))]
                : selectedPDFWeeks.compactMap { Int($0.replacingOccurrences(of: "W", with: "")) }

            let live = makeLiveInsightsResponse(for: fallbackWeeks)
            insightsData = live
            return live
        }

        func makeLiveInsightsResponse(for weeks: [Int]) -> InsightsResponse {
            let sanitizedWeeks = Array(Set(weeks.map { max(1, min($0, PregnancyDateCalculation.maxGestationalWeek)) })).sorted()

            let insights = ActivityType.allCases.map { activity -> Insight in
                let insightWeeks = sanitizedWeeks.compactMap { weekNumber -> InsightWeek? in
                    guard let snapshot = dataController.activityWeekProgressSnapshot(
                        for: activity,
                        gestationalWeek: weekNumber
                    ) else {
                        return InsightWeek(week: "W\(weekNumber)", days: [])
                    }

                    return InsightWeek(week: "W\(weekNumber)", days: snapshot.days)
                }

                return Insight(
                    activityType: activity.rawValue,
                    title: activity.title,
                    weeks: insightWeeks
                )
            }

            return InsightsResponse(insights: insights)
        }

        func chartUnitSuffix(for insight: Insight) -> String {
            switch insight.activityType.lowercased() {
            case "walking":
                return ""
            case "exercise":
                return ""
            case "yoga":
                return ""
            default:
                return ""
            }
        }
        
        func selectedDay(from week: InsightWeek) -> InsightDay? {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let todayKey = formatter.string(from: Date())
            if let today = week.days.first(where: { $0.dayKey == todayKey }) {
                return today
            }
            return week.days.first
        }
        
        func weeklyValues(for insight: Insight, week: InsightWeek) -> [Double] {
            var values = Array(repeating: 0.0, count: 7)
            for day in week.days {
                guard let index = chartIndex(for: day.dayKey) else { continue }
                values[index] = totalMetricForDay(day, activityType: insight.activityType)
            }
            return values
        }
        
        func totalMetricForDay(_ day: InsightDay, activityType: String) -> Double {
            switch activityType.lowercased() {
            case "walking":
                return totalStat(named: "Steps", in: day.sessions)
            case "exercise":
                return totalStat(named: "Reps", in: day.sessions)
            case "yoga":
                return Double(day.sessions.count)
            default:
                return 0
            }
        }
        
        func progressText(for insight: Insight, week: InsightWeek) -> String {
            guard let day = selectedDay(from: week) else { return "0" }
            switch insight.activityType.lowercased() {
            case "walking":
                let steps = totalStat(named: "Steps", in: day.sessions)
                return "\(Int(steps)) Steps"
            case "exercise":
                let reps = totalStat(named: "Reps", in: day.sessions)
                return "\(Int(reps)) Reps"
            case "yoga":
                let totalYogaSessions = day.sessions.count
                return "\(totalYogaSessions) Sessions"
            default:
                return "0"
            }
        }
        
        func subtitleText(for insight: Insight, week: InsightWeek) -> String {
            guard let day = selectedDay(from: week) else { return "Let’s get started 💪" }
            switch insight.activityType.lowercased() {
            case "walking":
                let steps = totalStat(named: "Steps", in: day.sessions)
                return MotivationText.text(activity: .walking, completed: steps, target: 8000)
            case "exercise":
                let reps = totalStat(named: "Reps", in: day.sessions)
                return MotivationText.text(activity: .exercise, completed: reps, target: 40)
            case "yoga":
                let sessions = Double(day.sessions.count)
                return MotivationText.text(activity: .yoga, completed: sessions, target: 2)
            default:
                return MotivationText.text(activity: .unknown, completed: 0, target: 1)
            }
        }

        func totalStat(named statTitle: String, in sessions: [InsightSession]) -> Double {
            sessions.reduce(0.0) { partial, session in
                guard let stat = session.stats.first(where: { $0.title.lowercased() == statTitle.lowercased() }) else {
                    return partial
                }
                let rawValue = Double(stat.value) ?? 0
                let unit = stat.unit.lowercased()
                let finalValue: Double
                switch unit {
                case "k":
                    finalValue = rawValue * 1000
                default:
                    finalValue = rawValue
                }
                return partial + finalValue
            }
        }
        
        func chartIndex(for dayKey: String) -> Int? {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let date = formatter.date(from: dayKey) else { return nil }
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: date)
            switch weekday {
            case 2: return 0
            case 3: return 1
            case 4: return 2
            case 5: return 3
            case 6: return 4
            case 7: return 5
            case 1: return 6
            default: return nil
            }
        }
        func formatted(_ value: Double) -> String {
            if value == floor(value) {
                return "\(Int(value))"
            }
            return String(format: "%.1f", value)
        }
    }


extension ProgressViewController {
    func observeProgressChanges() {
        progressObserver = NotificationCenter.default.addObserver(
            forName: DataController.progressDidChangeNotification,
            object: dataController,
            queue: .main
        ) { [weak self] _ in
            self?.reloadInsightsFromFirestore()
        }
    }
    
    func reloadInsightsFromFirestore() {
        insightsData = dataController.loadInsightsResponse()
        healthItems = dataController.insightHealthItemsForCurrentWeek()
        collectionView.reloadData()
    }
}

extension ProgressViewController {
    func loadInsightsData() {
        reloadInsightsFromFirestore()
    }
}
