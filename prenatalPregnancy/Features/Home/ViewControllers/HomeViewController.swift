import UIKit

class HomeViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var pregnancyCollectionView: UICollectionView!
    @IBOutlet weak var profileBarButton: UIBarButtonItem!

    var dataController: DataController!
    private var todayDate = Date()
    private var routineCards: [RoutineCardData] = []
    private var encouragingText: String = ""
    private var categories: [Category] = []
    private var selectedCategory: Category?
    private var lastYogaVideoPrefetchDate: Date?
    private var lastRoutinePreparationDate: Date?
    private var isPreparingTodayRoutine = false

    private var currentWeek: String { "\(dataController.userProfile.gestationalWeek)" }
    private var currentDay: String { "\(dataController.userProfile.gestationalDay)" }
    private var currentTrimester: Int { dataController.userProfile.trimester.rawValue }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Home"
        applyBackground()
        dataController.requestStartupTrackingPermissions()
        setupCollectionView()
        registerCells()
        configureLayout()
        loadData()
        prepareTodayRoutineAndMediaIfNeeded()
        NotificationCenter.default.addObserver(self, selector: #selector(healthVitalsDidUpdate), name: .healthVitalsDidUpdate, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateProfileBarButton()
        prepareTodayRoutineAndMediaIfNeeded()
        loadRoutineCards()
        pregnancyCollectionView.reloadSections(IndexSet(integersIn: 1...2))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for (index, card) in self.routineCards.enumerated() {
                let indexPath = IndexPath(item: index, section: 1)
                guard let cell = self.pregnancyCollectionView.cellForItem(at: indexPath)
                        as? RoutineHomeCollectionViewCell else { continue }
                let progress = card.progress ?? (card.firstIncompleteItem.map {
                    self.dataController.loadProgress(for: $0, date: Date())
                })
                cell.refreshProgress(progress: progress)
            }

            if let cell = self.pregnancyCollectionView.cellForItem(
                at: IndexPath(item: 0, section: 2)
            ) as? ProgressCollectionViewCell {
                cell.animateTrackFill()
            }
        }
    }

    @objc private func healthVitalsDidUpdate(_ notification: Notification) {
        if let record = notification.userInfo?["record"] as? ActivityExecutionRecord {
            dataController.latestHealthVitals = record
        }
        pregnancyCollectionView.reloadSections(IndexSet([1, 2]))
    }

    private func applyBackground() {
        let theme = dataController.theme
        applyAnimatedBackground(theme: theme)
        pregnancyCollectionView.backgroundColor = .clear
    }

    private func loadData() {
        loadRoutineCards()
        categories = InsightsProvider.getCategories(for: dataController.userProfile.gestationalWeek)
        pregnancyCollectionView.reloadData()
    }

    private func prefetchYogaVideosIfNeeded() {
        let date = Calendar.current.startOfDay(for: Date())

        if let lastYogaVideoPrefetchDate,
           Calendar.current.isDate(lastYogaVideoPrefetchDate, inSameDayAs: date) {
            print("ℹ️ [Home] Yoga video prefetch already started for today")
            return
        }

        lastYogaVideoPrefetchDate = date

        let yogaItems = dataController.getRoutineItems(for: .yoga, date: date)
        print("🚀 [Home] Starting yoga video prefetch from home screen. Items: \(yogaItems.count)")

        CloudinaryVideoService.shared.prefetchVideos(for: yogaItems, routineType: .yoga)
    }

    private func prepareTodayRoutineAndMediaIfNeeded() {
        let date = Calendar.current.startOfDay(for: Date())

        if let lastRoutinePreparationDate,
           Calendar.current.isDate(lastRoutinePreparationDate, inSameDayAs: date) {
            return
        }

        guard !isPreparingTodayRoutine else { return }
        isPreparingTodayRoutine = true

        dataController.prepareTodayRoutineForHome { [weak self] routines in
            guard let self else { return }
            let allItems = routines.values.flatMap { $0 }
            CloudinaryImageCache.shared.prefetchImages(for: allItems)
            CloudinaryVideoService.shared.prefetchVideos(for: allItems.filter { $0.routineType == .yoga }, routineType: .yoga)

            DispatchQueue.main.async {
                self.isPreparingTodayRoutine = false
                self.lastRoutinePreparationDate = date
                self.loadData()
            }
        }
    }
    
    private func updateProfileBarButton() {
        if let imageData = dataController.userProfile.profileImageData,
           let image = UIImage(data: imageData) {
            setProfileBarButtonImage(image)
        } else if let urlString = dataController.userProfile.profileImageUrl,
                  let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self, let data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    // Cache locally
                    self.dataController.userProfile.profileImageData = data
                    self.setProfileBarButtonImage(image)
                }
            }.resume()
        } else {
            profileBarButton.image = UIImage(systemName: "person.circle")
        }
    }

    private func setProfileBarButtonImage(_ image: UIImage) {
        let size = CGSize(width: 32, height: 32)
        let renderer = UIGraphicsImageRenderer(size: size)
        let cropped = renderer.image { _ in
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).addClip()
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        profileBarButton.image = cropped.withRenderingMode(.alwaysOriginal)
    }

    private func loadRoutineCards() {
        let date = Calendar.current.startOfDay(for: Date())
        var hasAnyStarted = false

        routineCards = RoutineType.allCases.compactMap { type -> RoutineCardData? in
            let items = dataController.getRoutineItems(for: type, date: date)
            guard !items.isEmpty else { return nil }

            let total       = items.count
            let activeResult = dataController.getMostRecentlyActiveItem(for: type, date: date)
            let targetItem  = activeResult?.item
            let progress    = activeResult?.progress

            let incompleteCount = items.filter {
                dataController.loadProgress(for: $0, date: date).status == .pending
            }.count

            let anyHandled = items.contains {
                let p = dataController.loadProgress(for: $0, date: date)
                return p.status == .completed || p.status == .skipped || p.elapsedSeconds > 0
            }
            if anyHandled { hasAnyStarted = true }

            return RoutineCardData(
                routineType: type,
                firstIncompleteItem: targetItem,
                incompleteCount: incompleteCount,
                totalCount: total,
                progress: progress
            )
        }

        encouragingText = hasAnyStarted ? motivationalInProgress() : motivationalNotStarted()
    }

    private func motivationalNotStarted() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "A gentle start to your morning goes a long way, mama."
        case 12..<17: return "Afternoon movement boosts your energy and mood!"
        case 17..<22: return "A calm evening routine helps you and baby sleep better."
        default:      return "Every small step you take is a gift to you and your baby."
        }
    }

    private func motivationalInProgress() -> String {
        let messages = [
            "You've already started — keep that momentum going!",
            "Look at you showing up for yourself and your baby!",
            "Progress over perfection. You're doing amazing!",
            "Every rep, every breath counts. Keep going, mama!",
        ]
        return messages[Calendar.current.component(.minute, from: Date()) % messages.count]
    }

    private func setupCollectionView() {
        pregnancyCollectionView.delegate   = self
        pregnancyCollectionView.dataSource = self
        pregnancyCollectionView.showsVerticalScrollIndicator = false
    }

    private func registerCells() {
        pregnancyCollectionView.register(
            UINib(nibName: "greetCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "greetCollectionViewCell"
        )
        pregnancyCollectionView.register(
            UINib(nibName: "RoutineHomeCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "DailyRoutineCollectionViewCell"
        )
        pregnancyCollectionView.register(
            UINib(nibName: "InsightsCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "InsightCollectionViewCell"
        )
        pregnancyCollectionView.register(
            UINib(nibName: "ProgressCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "ProgressCollectionViewCell"
        )
        // Header — XIB based, no more programmatic UILabel
        pregnancyCollectionView.register(
            UINib(nibName: "SectionHeaderViewCollectionViewCell", bundle: nil),
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "SectionHeaderView"
        )
        // Footer — XIB based with UIPageControl
        pregnancyCollectionView.register(
            UINib(nibName: "SectionFooterViewCollectionViewCell", bundle: nil),
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: "SectionFooterView"
        )
    }

    private func configureLayout() {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            guard let self else { return nil }
            switch sectionIndex {
            case 0:  return self.topCardSection()
            case 1:  return self.routineSection()
            case 2:  return self.progressSection()
            case 3:  return self.insightsSection(environment: environment)
            default: return nil
            }
        }
        pregnancyCollectionView.setCollectionViewLayout(layout, animated: false)
    }

    private func topCardSection() -> NSCollectionLayoutSection {
        let size    = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(150))
        let item    = NSCollectionLayoutItem(layoutSize: size)
        let group   = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        return section
    }

    private func routineSection() -> NSCollectionLayoutSection {
        let itemSize  = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item      = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(200))
        let group     = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
        let header     = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(7))
        let footer     = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: footerSize,
            elementKind: UICollectionView.elementKindSectionFooter,
            alignment: .bottom
        )

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        section.interGroupSpacing           = 6
        section.contentInsets               = .zero
        section.boundarySupplementaryItems  = [header, footer]

        section.visibleItemsInvalidationHandler = { [weak self] visibleItems, offset, environment in
            guard let self else { return }
            
            let pageWidth = self.pregnancyCollectionView.frame.width
            guard pageWidth > 0 else { return }
            
            let page = min(
                self.routineCards.count - 1,
                max(0, Int(round(offset.x / pageWidth)))
            )
            
            DispatchQueue.main.async {
                if let footer = self.pregnancyCollectionView.supplementaryView(
                    forElementKind: UICollectionView.elementKindSectionFooter,
                    at: IndexPath(item: 0, section: 1)
                ) as? SectionFooterViewCollectionViewCell {
                    footer.pageControl.currentPage = page
                }
            }
        }

        return section
    }

    private func progressSection() -> NSCollectionLayoutSection {
        let itemSize  = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(600))
        let item      = NSCollectionLayoutItem(layoutSize: itemSize)
        let group     = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])

        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
        let header     = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets              = .init(top: 8, leading: 16, bottom: 16, trailing: 16)
        section.boundarySupplementaryItems = [header]
        return section
    }

    private func insightsSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let pad: CGFloat = 16

        let heroItemSize  = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let heroItem      = NSCollectionLayoutItem(layoutSize: heroItemSize)
        let heroGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(220))
        let heroGroup     = NSCollectionLayoutGroup.horizontal(layoutSize: heroGroupSize, subitems: [heroItem])
        heroGroup.contentInsets = .init(top: 0, leading: pad, bottom: 0, trailing: pad)

        let miniItemSize  = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / 3.0), heightDimension: .fractionalHeight(1.0))
        let miniItem      = NSCollectionLayoutItem(layoutSize: miniItemSize)
        miniItem.contentInsets = .init(top: 0, leading: 4, bottom: 0, trailing: 4)
        let miniGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(140))
        let miniGroup     = NSCollectionLayoutGroup.horizontal(layoutSize: miniGroupSize, repeatingSubitem: miniItem, count: 3)
        miniGroup.contentInsets = .init(top: 0, leading: pad - 4, bottom: 0, trailing: pad - 4)

        let outerGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(220 + 10 + 140))
        let outerGroup     = NSCollectionLayoutGroup.vertical(layoutSize: outerGroupSize, subitems: [heroGroup, miniGroup])
        outerGroup.interItemSpacing = .fixed(10)

        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
        let header     = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        let section = NSCollectionLayoutSection(group: outerGroup)
        section.contentInsets              = .init(top: 0, leading: 0, bottom: 32, trailing: 0)
        section.boundarySupplementaryItems = [header]
        return section
    }

    // MARK: - DataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int { 4 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:  return 1
        case 1:  return routineCards.count
        case 2:  return 1
        case 3:  return categories.count
        default: return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {

        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "greetCollectionViewCell", for: indexPath) as! greetCollectionViewCell
            let dueDate = dataController.userProfile.eddDate ?? Calendar.current.date(byAdding: .day, value: (40 - dataController.userProfile.gestationalWeek) * 7, to: Date()) ?? Date()
            cell.configure(
                week: dataController.userProfile.gestationalWeek,
                trimester: currentTrimester,
                dueDate: dueDate,
                profile: dataController.userProfile,
                theme: dataController.theme
            )
            cell.layer.shadowOffset  = CGSize(width: 0, height: 2)
            cell.layer.shadowOpacity = 0.1
            cell.layer.masksToBounds = false
            return cell

        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DailyRoutineCollectionViewCell", for: indexPath) as! RoutineHomeCollectionViewCell
            cell.dataController = dataController
            let card = routineCards[indexPath.item]

            if let item = card.firstIncompleteItem {
                let index    = card.totalCount - card.incompleteCount
                let progress = card.progress ?? dataController.loadProgress(for: item, date: Date())
                cell.configureCell(with: item, progress: progress, index: index, theme: dataController.theme)
            } else {
                let items = dataController.getRoutineItems(for: card.routineType, date: Date())
                guard let anyItem = items.first else { return cell }
                let doneProgress = RoutineItemProgress(
                    activityId: anyItem.activityId,
                    date: Date(),
                    elapsedSeconds: anyItem.durationSeconds,
                    heartRateAverage: nil,
                    caloriesBurned: nil,
                    distanceCovered: nil,
                    repetitionsCompleted: anyItem.reps,
                    status: .completed
                )
                cell.configureCell(with: anyItem, progress: doneProgress, index: card.totalCount, theme: dataController.theme)
            }
            return cell

        case 2:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProgressCollectionViewCell", for: indexPath) as! ProgressCollectionViewCell
            let date = Calendar.current.startOfDay(for: Date())
            let _ = RoutineType.allCases.flatMap { dataController.getRoutineItems(for: $0, date: date) }
            cell.onMiniCardTapped = { [weak self] routineType in
                guard let self else { return }
                if let card = self.routineCards.first(where: { $0.routineType == routineType }) {
                    self.performSegue(withIdentifier: "showRoutineList", sender: card)
                }
            }
            cell.configure(dataController: dataController, date: Date(), theme: dataController.theme)
            return cell

        case 3:
            let cell     = collectionView.dequeueReusableCell(withReuseIdentifier: "InsightCollectionViewCell", for: indexPath) as! InsightsCollectionViewCell
            let category = categories[indexPath.item]
            print("Looking for image: '\(category.heroImage)' → \(UIImage(named: category.heroImage) == nil ? "NIL ❌" : "Found ✅")")
            let isHero   = indexPath.item == 0
            cell.configure(
                with: Insights(image: UIImage(named: category.heroImage) ?? UIImage(), title: category.title, description: category.subtitle, points: ""),
                isHero: isHero
            )
            return cell

        default:
            return UICollectionViewCell()
        }
    }

    // MARK: - Supplementary Views (no programmatic UILabel)

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
     
        if kind == UICollectionView.elementKindSectionFooter {
            let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "SectionFooterView",
                for: indexPath
            ) as! SectionFooterViewCollectionViewCell
            footer.configure(pages: routineCards.count, current: 0, theme: dataController.theme)
            return footer
        }
     
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "SectionHeaderView",
            for: indexPath
        ) as! SectionHeaderViewCollectionViewCell
     
        switch indexPath.section {
        case 1:
            header.configure(
                title: "Today's Routine",
                subtitle: "Small steps, big difference.",
                theme: dataController.theme,
                leadingPadding: 20
            )
        case 2:
            header.configure(
                title: "Today's Progress",
                subtitle: "Every step counts!",
                theme: dataController.theme,
                leadingPadding: 16
            )
        case 3:
            header.configure(
                title: "Pregnancy Insights",
                subtitle: "Personalized guidance for Week \(currentWeek)",
                theme: dataController.theme,
                leadingPadding: 20
            )
        default:
            break
        }
     
        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let card = routineCards[indexPath.item]
            performSegue(withIdentifier: "showRoutineDetail", sender: card)
        }
        if indexPath.section == 3 {
            selectedCategory = categories[indexPath.item]
            performSegue(withIdentifier: "showInsightDetail", sender: self)
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "showRoutineDetail",
           let card = sender as? RoutineCardData,
           let destination = segue.destination as? RoutineItemDetailViewController {
            destination.dataModel    = dataController
            destination.selectedDate = Calendar.current.startOfDay(for: Date())
            if let item = card.firstIncompleteItem {
                destination.routineItem = item
                destination.title       = item.title
            }
        }

        if segue.identifier == "showRoutineList",
           let card = sender as? RoutineCardData,
           let destVC = segue.destination as? DailyRoutineViewController {
            destVC.dataController = dataController
            destVC.routineType    = card.routineType
            destVC.selectedDate   = Calendar.current.startOfDay(for: Date())
            destVC.currentSession = dataController
                .getTodayRoutineSummary(for: Calendar.current.startOfDay(for: Date()))
                .first { $0.routineType == card.routineType }
            switch card.routineType {
            case .walking:  destVC.title = "Walking for Today"
            case .exercise: destVC.title = "Exercise for Today"
            case .yoga:     destVC.title = "Yoga for Today"
            }
        }

        if segue.identifier == "showInsightDetail",
           let navController = segue.destination as? UINavigationController,
           let detailVC = navController.topViewController as? InsightsDetailViewController {
            detailVC.category       = selectedCategory
            detailVC.dataController = dataController
        }
        
        if segue.identifier == "showProfile",
           let destVC = segue.destination as? ProfileViewController {
            destVC.dataController = dataController
        }
    }
}
