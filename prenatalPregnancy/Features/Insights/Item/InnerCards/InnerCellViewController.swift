//
//  InnerCellViewController.swift
//  prenatalPregnancy
//
//  Created by Amandeep on 26/03/26.
//

import UIKit

class InnerCellViewController:UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    private var distanceTint: UIColor { UIColor.systemBlue }
    private var distanceBG: UIColor { UIColor.systemBlue.withAlphaComponent(0.16) }
    private var timeTint: UIColor { UIColor.systemRed }
    private var timeBG: UIColor { UIColor.systemRed.withAlphaComponent(0.14) }
    private var stepsTint: UIColor { UIColor.systemGreen }
    private var stepsBG: UIColor { UIColor.systemGreen.withAlphaComponent(0.14) }
    private var caloriesTint: UIColor { UIColor.systemOrange }
    private var caloriesBG: UIColor { UIColor.systemOrange.withAlphaComponent(0.16) }
    private var repsTint: UIColor { activityAccentColor }
    private var repsBG: UIColor { activityAccentColor.withAlphaComponent(0.16) }
    private var breathsTint: UIColor { activityAccentColor }
    private var breathsBG: UIColor { activityAccentColor.withAlphaComponent(0.16) }
    private var avgHeartTint: UIColor { UIColor.systemPink }
    private var avgHeartBG: UIColor { UIColor.systemPink.withAlphaComponent(0.14) }
    
    
    var selectedSession: InsightSession?
        var selectedDateText: String = ""
        var selectedActivityTitle: String = ""
        var selectedActivityIcon: String = "figure.walk"
        var selectedActivityType: String = "walking"
        var dataController: DataController!
        var theme: AppTheme!

        enum SectionType: Int, CaseIterable {
            case header
            case grid
            case healthVitals
        }

        struct DetailMetricItem {
            let title: String
            let value: String
            let unit: String
            let iconName: String
            let tintColor: UIColor
            let cardColor: UIColor
        }
    
       struct DetailMetricItemStyle {
            let tintColor: UIColor
            let backgroundColor: UIColor
            let iconName: String
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            theme = dataController?.theme
            applyAnimatedBackground(theme: theme)
            collectionView.backgroundColor = .clear
            selectedSession = dataController?.enrichedInsightSession(
                from: selectedSession,
                activityType: selectedActivityType,
                dateText: selectedDateText
            )
            self.title = selectedSession?.sessionTitle ?? "Session Details"
            self.navigationItem.title = selectedSession?.sessionTitle ?? "Session Details"
            setupCollectionView()
            
        }

        private var resolvedActivityType: String {
            selectedActivityType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
   
        private var activityAccentColor: UIColor {
            switch resolvedActivityType {
            case "walking":
                return RoutineType.walking.accentColor
            case "exercise":
                return RoutineType.exercise.accentColor
            case "yoga":
                return RoutineType.yoga.accentColor
            default:
                return theme.accentPrimary
            }
        }

        private func statValue(for title: String, fallback: String = "--") -> String {
            selectedSession?.stats.first(where: { $0.title.lowercased() == title.lowercased() })?.value ?? fallback
        }

        private func statUnit(for title: String, fallback: String = "") -> String {
            selectedSession?.stats.first(where: { $0.title.lowercased() == title.lowercased() })?.unit ?? fallback
        }

        private func vitalValue(for title: String, fallback: String) -> String {
            selectedSession?.vitals?.first(where: { $0.title.lowercased() == title.lowercased() })?.value ?? fallback
        }

        private func vitalUnit(for title: String, fallback: String) -> String {
            selectedSession?.vitals?.first(where: { $0.title.lowercased() == title.lowercased() })?.unit ?? fallback
        }
    
        private func innerStatStyle(for title: String, activityColor: String) -> DetailMetricItemStyle {
         switch title.lowercased() {
         case "distance":
              return DetailMetricItemStyle(tintColor: UIColor.systemBlue,backgroundColor:  UIColor.systemBlue.withAlphaComponent(0.15),iconName: "location")
         case "time", "duration":
              return DetailMetricItemStyle(tintColor: UIColor.systemRed,backgroundColor: UIColor.systemRed.withAlphaComponent(0.15),iconName: "clock")
         case "steps":
             return DetailMetricItemStyle(tintColor: UIColor.systemGreen,backgroundColor: UIColor.systemGreen.withAlphaComponent(0.15),iconName: "shoeprints.fill")
         case "reps":
              let tint = UIColor.systemPurple
              return DetailMetricItemStyle(tintColor: tint,backgroundColor: tint.withAlphaComponent(0.15),iconName:"arrow.triangle.2.circlepath")
         case "sets":
              let tint = UIColor.systemMint
              return DetailMetricItemStyle(tintColor: tint,backgroundColor: tint.withAlphaComponent(0.15),iconName: "chart.bar")
         case "breaths":
             let tint = UIColor.systemTeal
             return DetailMetricItemStyle(
                tintColor: tint,
                backgroundColor: tint.withAlphaComponent(0.15),
                iconName: "wind")
        case "calories":
            return DetailMetricItemStyle(tintColor: UIColor.systemOrange,backgroundColor: UIColor.systemOrange.withAlphaComponent(0.15),iconName: "flame")
        default:
            let tint = UIColor.appColor(from: activityColor)
            return DetailMetricItemStyle(tintColor: tint,backgroundColor: tint.withAlphaComponent(0.12),iconName: "chart.bar")
        }
    }
    
        private var overviewMetrics: [DetailMetricItem] {
        guard let session = selectedSession else { return [] }
        let activityColor = selectedActivityType
        return session.stats.map { stat in
            let style = innerStatStyle(for: stat.title, activityColor: activityColor)
            return DetailMetricItem(title: stat.title,value: stat.value,unit: stat.unit,iconName: style.iconName,tintColor: style.tintColor,cardColor: style.backgroundColor)
        }
    }

    private var hasVitals: Bool {
        selectedSession?.vitals?.contains {
            !$0.title.localizedCaseInsensitiveContains("Respiratory")
        } == true
    }

    private var visibleSections: [SectionType] {
        var sections: [SectionType] = [.header]
        if !overviewMetrics.isEmpty {
            sections.append(.grid)
        }
        if hasVitals {
            sections.append(.healthVitals)
        }
        return sections
    }

    private var gridSectionHeight: CGFloat {
            return 310
        }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
            UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
                guard let self = self,
                      self.visibleSections.indices.contains(sectionIndex) else { return nil }
                let sectionType = self.visibleSections[sectionIndex]
                switch sectionType {
                    
                case .header:
                    let itemSize = NSCollectionLayoutSize(widthDimension:.fractionalWidth(1.0),heightDimension:.fractionalHeight(1.0))
                    let item = NSCollectionLayoutItem(layoutSize: itemSize)
                    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: .absolute(88))
                    let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                    let section = NSCollectionLayoutSection(group: group)
                    return section

                case .grid:
                    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: .fractionalHeight(1.0))
                    let item = NSCollectionLayoutItem(layoutSize: itemSize)
                    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: .absolute(self.gridSectionHeight))
                    let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                    let section = NSCollectionLayoutSection(group: group)
                    section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0)
                    return section
                    
                case .healthVitals:
                    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: .fractionalHeight(1.0))
                    let item = NSCollectionLayoutItem(layoutSize: itemSize)
                    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: .absolute(190))
                    let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                    let section = NSCollectionLayoutSection(group: group)
                    section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0)
                    return section
                }
            }
        }

    func setupCollectionView() {
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.collectionViewLayout = createLayout()
            collectionView.register(UINib(nibName: "HeaderCardCell", bundle: nil), forCellWithReuseIdentifier: "HeaderCardCell")
            collectionView.register(UINib(nibName: "GridStatCell", bundle: nil), forCellWithReuseIdentifier: "GridStatCell")
            collectionView.register(UINib(nibName: "HealthVitalsCollectionViewCell", bundle: nil),forCellWithReuseIdentifier:"HealthVitalsCollectionViewCell")
        }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
            visibleSections.count
        }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            visibleSections.indices.contains(section) ? 1 : 0
        }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let sectionType = visibleSections[indexPath.section]

            switch sectionType {
            case .header:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HeaderCardCell", for: indexPath) as! HeaderCardCell
                cell.containerView.backgroundColor = theme.glassMedium
                cell.containerView.layer.borderWidth = 1
                cell.containerView.layer.borderColor = theme.glassBorderLight.cgColor
                cell.configure(title: "Session Time",subtitle: selectedSession?.time ?? "--",icon: UIImage(systemName: selectedActivityIcon),accentColor: activityAccentColor,theme: theme)
                return cell

            case .grid:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridStatCell", for: indexPath) as! GridStatCell
                cell.theme = theme
                cell.configure(metrics: overviewMetrics, theme : theme)
                return cell
                
            case .healthVitals:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HealthVitalsCollectionViewCell", for: indexPath) as! HealthVitalsCollectionViewCell
                cell.theme = theme
                let avgHeart = formattedVital(title: "Heart Rate")
                let peakHeart = formattedVital(title: "Peak Heart Rate")
                cell.configureCell(avgHeartRate: avgHeart,peakHeartRate: peakHeart,theme: theme)
                return cell
            }
        }

    private func formattedVital(title: String) -> String {
        let value = vitalValue(for: title, fallback: "--")
        let unit = vitalUnit(for: title, fallback: "")
        return unit.isEmpty ? value : "\(value) \(unit)"
    }

    func collectionView(_ collectionView: UICollectionView,willDisplay cell: UICollectionViewCell,forItemAt indexPath: IndexPath) {
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: 0, y: 30)
            UIView.animate(withDuration: 0.5,delay: Double(indexPath.item) * 0.05,usingSpringWithDamping: 0.85,initialSpringVelocity: 0.8,options: [],animations: {
                cell.alpha = 1
                cell.transform = .identity
            })
        }
    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
