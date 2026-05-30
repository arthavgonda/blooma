//
//  WalkGraphViewController.swift
//  weekselector
//
//  Created by GEU on 11/02/26.
//

import UIKit
import PDFKit
import Lottie

class GraphViewController: UIViewController {
    
    @IBOutlet weak var walkinggraph: UICollectionView!
    var activities: [ActivityType] = ActivityType.allCases
    let allWeeks = Array(1...PregnancyDateCalculation.maxGestationalWeek)
    var insightsData: InsightsResponse?
    var selectedActivityIndex: Int = 0
    var selectedWeekIndex: Int = 0
    var selectedDayKey: String?
    var selectedSessionForDetail: InsightSession?
    var selectedDateForDetail: String = ""
    var selectedActivityIconForDetail: String = ""
    var selectedActivityTypeForDetail: String = ""
    var selectedActivityTitleForDetail: String = ""
    var dataController: DataController!
    var theme:AppTheme!
    private var progressObserver: NSObjectProtocol?
    private var weekOptions: [Int] = [1]
    
    var availableWeeks: [Int] {
        weekOptions
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        theme = dataController.theme
        applyAnimatedBackground(theme: theme)
        walkinggraph.backgroundColor = .clear
        walkinggraph.allowsSelection = true
        walkinggraph.allowsMultipleSelection = false
        walkinggraph.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        walkinggraph.clipsToBounds = false
        walkinggraph.layer.masksToBounds = false
        walkinggraph.verticalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        navigationItem.largeTitleDisplayMode = .never
        setupCollectionView()
        observeProgressChanges()
        reloadUI()
//        dataController.loadDummyProgressDataUntilCurrentDay { [weak self] in
//            DispatchQueue.main.async {
//                self?.reloadUI()
//            }
//        }
    }
    
    deinit {
        if let progressObserver {
            NotificationCenter.default.removeObserver(progressObserver)
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detail_cell" {
            if let nav = segue.destination as? UINavigationController,
               let vc = nav.topViewController as? InnerCellViewController {
                configureDetailSheet(for: nav)
                vc.selectedSession = selectedSessionForDetail
                vc.selectedDateText = selectedDateForDetail
                vc.selectedActivityTitle = selectedActivityTitleForDetail
                vc.selectedActivityIcon = selectedActivityIconForDetail
                vc.selectedActivityType = selectedActivityTypeForDetail
                vc.dataController = dataController
                
            } else if let vc = segue.destination as? InnerCellViewController {
                configureDetailSheet(for: vc)
                vc.selectedSession = selectedSessionForDetail
                vc.selectedDateText = selectedDateForDetail
                vc.selectedActivityTitle = selectedActivityTitleForDetail
                vc.selectedActivityIcon = selectedActivityIconForDetail
                vc.selectedActivityType = selectedActivityTypeForDetail
                vc.dataController = dataController
            }
        }
    }
    
    private func configureDetailSheet(for controller: UIViewController) {
        controller.modalPresentationStyle = .pageSheet
        guard let sheet = controller.sheetPresentationController else { return }
        sheet.detents = [
            .custom { context in
                min(780, context.maximumDetentValue * 0.94)
            }
        ]
        sheet.preferredCornerRadius = 32
    }
}

extension GraphViewController {
    
    private func observeProgressChanges() {
        progressObserver = NotificationCenter.default.addObserver(
            forName: DataController.progressDidChangeNotification,
            object: dataController,
            queue: .main
        ) { [weak self] _ in
            self?.reloadUI()
        }
    }
    
    func setupCollectionView() {
        walkinggraph.delegate = self
        walkinggraph.dataSource = self

        walkinggraph.register(UINib(nibName: "WeekCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "week_cell")

        walkinggraph.register(UINib(nibName: "GraphCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "graph_cell")

        walkinggraph.register(UINib(nibName: "FooterInsights", bundle: nil), forCellWithReuseIdentifier: "footer_insights")
        walkinggraph.register(EmptyActivitySessionsCell.self, forCellWithReuseIdentifier: EmptyActivitySessionsCell.reuseIdentifier)

        walkinggraph.register(UINib(nibName: "ActivitySessionHeaderView", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "ActivitySessionHeaderView")
        
        walkinggraph.setCollectionViewLayout(generateLayout(), animated: false)
    }
}

extension GraphViewController {
    
    func reloadUI() {
        guard activities.indices.contains(selectedActivityIndex) else { return }

        let activity = activities[selectedActivityIndex]
        title = activity.title

        let currentWeek = max(1, min(dataController?.userProfile.gestationalWeek ?? 1, PregnancyDateCalculation.maxGestationalWeek))
        weekOptions = dataController?.availableInsightWeeks() ?? [1]

        if selectedWeekIndex == 0 || !availableWeeks.contains(selectedWeekIndex) {
            selectedWeekIndex = availableWeeks.contains(currentWeek) ? currentWeek : (availableWeeks.last ?? currentWeek)
        }

        let orderedDays = selectedInsightDaysOrdered()
        if selectedDayKey == nil || !orderedDays.contains(where: { $0.dayKey == selectedDayKey }) {
            selectedDayKey = defaultDayKeyForSelectedWeek()
        }
        walkinggraph.collectionViewLayout.invalidateLayout()
        walkinggraph.reloadData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let index = self.availableWeeks.firstIndex(of: self.selectedWeekIndex) {
                let indexPath = IndexPath(item: index, section: 0)
                self.walkinggraph.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            }
        }
    }
    func themeColor() -> UIColor {
        guard activities.indices.contains(selectedActivityIndex) else {
            return .systemGreen
        }

        return activities[selectedActivityIndex].selectedColor
    }

    func selectedInsight() -> Insight? {
        guard activities.indices.contains(selectedActivityIndex) else { return nil }

        let selectedActivity = activities[selectedActivityIndex]

        return insightsData?.insights.first(where: {
            $0.title.lowercased() == selectedActivity.title.lowercased() ||
            $0.activityType.lowercased() == selectedActivity.rawValue.lowercased()
        })
    }

    func selectedInsightWeek() -> InsightWeek? {
        guard let insight = selectedInsight() else { return nil }
        let selectedWeek = "W\(selectedWeekIndex)"

        return insight.weeks.first(where: {
            $0.week.lowercased() == selectedWeek.lowercased()
        })
    }

    func selectedInsightDaysOrdered() -> [InsightDay] {
        if let liveSnapshot = dataController.activityWeekProgressSnapshot(
            for: activities[selectedActivityIndex],
            gestationalWeek: selectedWeekIndex
        ) {
            return liveSnapshot.days
        }
        return selectedInsightWeek()?.days ?? []
    }

    func selectedInsightDay() -> InsightDay? {
        let days = selectedInsightDaysOrdered()

        if let selectedDayKey,
           let selectedDay = days.first(where: { $0.dayKey == selectedDayKey }) {
            return selectedDay
        }

        return days.last
    }
    
  
    func currentGraphSummary() -> InsightGraphSummary? {
        if let liveSummary = dataController.activityWeekProgressSnapshot(
            for: activities[selectedActivityIndex],
            gestationalWeek: selectedWeekIndex
        )?.graphSummary {
            return liveSummary
        }
        
        guard let week = selectedInsightWeek(), activities.indices.contains(selectedActivityIndex) else { return nil }
        let activity = activities[selectedActivityIndex]
        let labels = week.days.map(\.dayLabel)
        var values = Array(repeating: 0.0, count: 7)
        for day in week.days {
            guard let index = week.days.firstIndex(where: { $0.dayKey == day.dayKey }) else { continue }
            values[index] = metricValue(for: day, activityType: activity.rawValue)
        }
        let total = values.reduce(0, +)
        let nonZeroDays = max(values.filter { $0 > 0 }.count, 1)
        let average = total / Double(nonZeroDays)
        let metricTitle: String
        let displayValue: String
        switch activity.rawValue.lowercased() {
        case "walking":
            metricTitle = "Average Steps"
            displayValue = "\(Int(average * 1000)) steps"
        case "exercise":
            metricTitle = "Average Active Minutes"
            displayValue = "\(Int(average.rounded())) min"
        case "yoga":
            metricTitle = "Average Duration"
            displayValue = "\(Int(average)) min"
        default:
            metricTitle = "Average"
            displayValue = "\(Int(average))"
        }
        return InsightGraphSummary(
            title: activity.title,metricTitle: metricTitle,displayValue: displayValue,dayLabels: labels, dayValues: values
        )
    }

    func metricValue(for day: InsightDay, activityType: String) -> Double {
        switch activityType.lowercased() {
        case "walking":
            return totalStat(named: "Steps", in: day.sessions)
        case "exercise":
            return totalStat(named: "Duration", in: day.sessions)
        case "yoga":
            return totalStat(named: "Duration", in: day.sessions)
        default:
            return 0
        }
    }

    func totalStat(named title: String, in sessions: [InsightSession]) -> Double {
        sessions.reduce(0.0) { partial, session in
            let value = session.stats.first(where: { $0.title.lowercased() == title.lowercased() })?.value ?? "0"
            return partial + (Double(value) ?? 0)
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
    
    func selectedSessions() -> [InsightSession] {
        (selectedInsightDay()?.sessions ?? []).filter {
            $0.status != .skipped && !$0.stats.isEmpty
        }
    }

    func defaultDayKeyForSelectedWeek() -> String? {
        let orderedDays = selectedInsightDaysOrdered()
        guard !orderedDays.isEmpty else { return nil }

        if let latestSessionDay = orderedDays.last(where: { day in
            day.sessions.contains { $0.status != .skipped && !$0.stats.isEmpty }
        }) {
            return latestSessionDay.dayKey
        }

        let currentWeek = max(1, min(dataController?.userProfile.gestationalWeek ?? 1, PregnancyDateCalculation.maxGestationalWeek))
        let todayFormatter = DateFormatter()
        todayFormatter.dateFormat = "yyyy-MM-dd"
        todayFormatter.timeZone = TimeZone(identifier: "Asia/Kolkata")
        let todayKey = todayFormatter.string(from: Date())

        if selectedWeekIndex == currentWeek,
           let today = orderedDays.first(where: { $0.dayKey == todayKey }) {
            return today.dayKey
        }

        return orderedDays.first?.dayKey
    }

    func hasActivityDataForSelectedWeek() -> Bool {
        selectedInsightDaysOrdered().contains { day in
            day.sessions.contains {
                $0.status != .skipped && !$0.stats.isEmpty
            }
        }
    }
    
    private var todayDayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")
        return formatter.string(from: Date())
    }
    
    private func shouldShowCurrentDayMotivation() -> Bool {
        let currentWeek = max(1, min(dataController?.userProfile.gestationalWeek ?? 1, PregnancyDateCalculation.maxGestationalWeek))
        return selectedWeekIndex == currentWeek && (selectedDayKey == nil || selectedDayKey == todayDayKey)
    }
    
    private func emptyStateContent() -> (animationName: String, title: String, message: String) {
        if shouldShowCurrentDayMotivation() {
            return (
                animationName: "Yoga Se Hi hoga",
                title: "Let's Begin",
                message: "A gentle session today is a beautiful start."
            )
        }
        
        return (
            animationName: "FreeEmpty",
            title: "No Data Found",
            message: ""
        )
    }

    func selectedChartIndex() -> Int? {
        guard let selectedDayKey else { return nil }
        return selectedInsightDaysOrdered().firstIndex { $0.dayKey == selectedDayKey }
    }

    func updateSelectedActivity(index: Int) {
        guard activities.indices.contains(index) else { return }
        selectedActivityIndex = index
        selectedDayKey = nil
        reloadUI()
        walkinggraph.reloadData()
    }

    func updateSelectedDayFromChart(barIndex: Int) {
        let orderedDays = selectedInsightDaysOrdered()
        guard orderedDays.indices.contains(barIndex) else { return }
        selectedDayKey = orderedDays[barIndex].dayKey
        walkinggraph.reloadSections(IndexSet(integer: 2))
    }
 }

extension GraphViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard !activities.isEmpty else { return 0 }
        switch section {
        case 0:
            return availableWeeks.count
        case 1:
            return 1
        case 2:
            return hasActivityDataForSelectedWeek() ? selectedSessions().count : 0
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let activity = activities[selectedActivityIndex]
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "week_cell",for: indexPath) as! WeekCollectionViewCell
            guard availableWeeks.indices.contains(indexPath.item) else { return cell }
            let weekNumber = availableWeeks[indexPath.item]
            cell.configure(title: "W\(weekNumber)",isSelected: weekNumber == selectedWeekIndex,themeColor:themeColor(),theme:theme)
            return cell
            
        case 1:
            guard hasActivityDataForSelectedWeek() else {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: EmptyActivitySessionsCell.reuseIdentifier,
                    for: indexPath
                ) as! EmptyActivitySessionsCell
                let emptyState = emptyStateContent()
                cell.configure(
                    animationName: emptyState.animationName,
                    title: emptyState.title,
                    message: emptyState.message
                )
                return cell
            }

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "graph_cell",for: indexPath) as! GraphCollectionViewCell
            cell.layer.cornerRadius = 24
            cell.layer.masksToBounds = true
            cell.backgroundColor = .secondarySystemBackground
            cell.onBarSelected = { [weak self] barIndex in self?.updateSelectedDayFromChart(barIndex: barIndex)
            }
            if let summary = currentGraphSummary() {
                cell.configure(with: summary,activity: activity,color: themeColor(),theme: theme,selectedBarIndex: selectedChartIndex()
                )
            } else {
                cell.showNoData(activity: activity)
            }
            return cell
        case 2:
            let sessions = selectedSessions()
            let cell = collectionView.dequeueReusableCell( withReuseIdentifier: "footer_insights", for: indexPath)as! FooterInsights
            if sessions.indices.contains(indexPath.item),
                      let day = selectedInsightDay() {
                let session = sessions[indexPath.item]
                
                cell.configure(session:session,activityIcon:activity.icon,activityColor:activity.rawValue,dateDisplay:day.dayKey,theme: theme)
            }
            return cell
            
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,viewForSupplementaryElementOfKind kind: String,at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,withReuseIdentifier: "ActivitySessionHeaderView",for: indexPath) as! ActivitySessionHeaderView
        if indexPath.section == 2, hasActivityDataForSelectedWeek() { header.configure(title: "Your Activity Sessions")
        }
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 15)
        
        UIView.animate(
            withDuration: 0.1,delay: Double(indexPath.item) * 0.01,usingSpringWithDamping: 0.9,initialSpringVelocity:0.5,options: [.curveEaseOut],animations: {
               cell.alpha = 1
               cell.transform = .identity
            }
        )
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            guard availableWeeks.indices.contains(indexPath.item) else { return }
            selectedWeekIndex = availableWeeks[indexPath.item]
            selectedDayKey = defaultDayKeyForSelectedWeek()
            collectionView.reloadData()
            collectionView.scrollToItem(at: indexPath,at: .centeredHorizontally,animated: true)
            return
        }
        if indexPath.section == 2 {
            let sessions = selectedSessions()
            guard sessions.indices.contains(indexPath.item),
            let day = selectedInsightDay(),
            sessions[indexPath.item].status != .skipped else { return }
            let activity = activities[selectedActivityIndex]
            selectedSessionForDetail = sessions[indexPath.item]
            selectedDateForDetail = day.dayKey
            selectedActivityTitleForDetail = selectedSessionForDetail?.sessionTitle ?? activity.title
            selectedActivityIconForDetail = activity.icon
            selectedActivityTypeForDetail = activity.rawValue
            performSegue(withIdentifier: "detail_cell", sender: self)
        }
    }
}

final class EmptyActivitySessionsCell: UICollectionViewCell {
    static let reuseIdentifier = "empty_activity_sessions_cell"

    private let animationView = LottieAnimationView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        animationView.stop()
    }

    func configure(animationName: String, title: String, message: String) {
        animationView.animation = LottieAnimation.named(animationName)
        animationView.loopMode = .loop
        animationView.play()
        titleLabel.text = title
        messageLabel.text = message
        messageLabel.isHidden = message.isEmpty
    }

    private func setupUI() {
        contentView.backgroundColor = .clear

        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFit
        animationView.backgroundBehavior = .pauseAndRestore

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center

        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = .systemFont(ofSize: 14, weight: .regular)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        contentView.addSubview(animationView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 42),
            animationView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            animationView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.82),
            animationView.heightAnchor.constraint(equalToConstant: 300),

            titleLabel.topAnchor.constraint(equalTo: animationView.bottomAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            messageLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }
}

extension GraphViewController {
        func generateLayout() -> UICollectionViewLayout {
            UICollectionViewCompositionalLayout { sectionIndex, _ in
            switch sectionIndex {
            case 0:
                let itemSize = NSCollectionLayoutSize( widthDimension: .absolute(52),heightDimension: .absolute(52))
                
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension:.estimated(52),heightDimension:.absolute(52))
                
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.interGroupSpacing = 14
                section.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
                return section
                
            case 1:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: .fractionalHeight(1.0))
                
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let height: CGFloat = self.hasActivityDataForSelectedWeek() ? 340 : 520
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: .absolute(height))
                
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize,subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                let horizontalInset: CGFloat = self.hasActivityDataForSelectedWeek() ? 16 : 0
                section.contentInsets = NSDirectionalEdgeInsets(top: 16,leading: horizontalInset,bottom: 12,trailing: horizontalInset)
                return section
                
            default:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: .estimated(220))
                
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: .estimated(250))
                
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize,subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 16
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 24, trailing: 16)
                
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: .absolute(36))
                
                if self.hasActivityDataForSelectedWeek() {
                    let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize:headerSize,elementKind:UICollectionView.elementKindSectionHeader,alignment: .top )
                    header.pinToVisibleBounds = false
                    section.boundarySupplementaryItems = [header]
                }
                return section
            }
        }
    }
}
