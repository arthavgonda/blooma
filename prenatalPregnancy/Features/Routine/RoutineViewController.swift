//
//  ViewController.swift
//  prenatalPregnancy
//
//  Created by GEU on 30/01/26.
//

import UIKit

class RoutineViewController: UIViewController {

    @IBOutlet weak var routineCollectionView: UICollectionView!
    
    var dataController: DataController!
    private var todaySession: [RoutineSession] = []
    
    private var istToday: Date { dataController.startOfDayInIST() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let theme = dataController.theme
        applyAnimatedBackground(theme: theme)
        
        routineCollectionView.backgroundColor = .clear
        
        title = "Routine"
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.tintColor = theme.accentPrimary
        
        navigationController?.navigationBar.standardAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        navigationController?.navigationBar.scrollEdgeAppearance?.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        registerCells()
        
        routineCollectionView.collectionViewLayout = generateLayout()
        routineCollectionView.dataSource = self
        routineCollectionView.delegate = self
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTodayRoutine()
        // Single reloadData call — loadTodayRoutine already reloads inside.
    }
    
    private func registerCells() {
        routineCollectionView.register(UINib(nibName: "RoutineCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "routine_card_cell")
        routineCollectionView.register(UINib(nibName: "RecommendedFlowCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "recommended_flow_cell")
        routineCollectionView.register(UINib(nibName: "RoutineHeaderCollectionReusableView", bundle: nil), forSupplementaryViewOfKind: "header", withReuseIdentifier: "routine_header")
        routineCollectionView.register(UINib(nibName: "RoutineFooterCollectionReusableView", bundle: nil), forSupplementaryViewOfKind: "footer", withReuseIdentifier: "routine_footer")
    }
    
    private func loadTodayRoutine() {
        let date = istToday
        dataController.loadTodayRoutineSnapshot { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                // getTodayRoutineSummary returns one RoutineSession per RoutineType,
                // each with the correct totalItems/totalDuration from the DataController
                // cache after Firestore has been checked for today's snapshot.
                self.todaySession = self.dataController.getTodayRoutineSummary(for: date)
                self.routineCollectionView.reloadData()
            }
        }
    }
    
    private func generateLayout() -> UICollectionViewLayout {
        
        return UICollectionViewCompositionalLayout { sectionIndex, _ in
            
            guard let sectionType = RoutineSection(rawValue: sectionIndex) else { return nil }
            
            switch sectionType {
                
            case .recommended:
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(90))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0)
                
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(70))
                
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: "header", alignment: .top)
                
                section.boundarySupplementaryItems = [header]
                
                return section
                
                
            case .routine:
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(140))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                
                // Footer
                let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(180))
                let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerSize, elementKind: "footer", alignment: .bottom)
                
                section.boundarySupplementaryItems = [footer]
                
                return section
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard segue.identifier == "routine_to_dailyRoutine", let indexPath = sender as? IndexPath, let destinationVC = segue.destination as? DailyRoutineViewController else { return }
        
        let session = todaySession[indexPath.item]
        
        destinationVC.dataController = dataController
        let date = istToday
        destinationVC.selectedDate = date
        destinationVC.routineType = session.routineType
        destinationVC.currentSession = session
        
        switch session.routineType {
        case .walking:  destinationVC.title = "Walking for Today"
        case .exercise: destinationVC.title = "Exercise for Today"
        case .yoga:     destinationVC.title = "Yoga for Today"
        }
    }

}

extension RoutineViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return RoutineSection.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let sectionType = RoutineSection(rawValue: section) else { return 0 }
        
        switch sectionType {
        case .recommended:
            return 1
            
        case .routine:
            return todaySession.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let sectionType = RoutineSection(rawValue: indexPath.section) else {
            return UICollectionViewCell()
        }
        
        switch sectionType {
            
        case .recommended:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "recommended_flow_cell", for: indexPath) as! RecommendedFlowCollectionViewCell
            cell.configure(theme: dataController.theme)
            return cell
            
            
        case .routine:
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "routine_card_cell", for: indexPath) as! RoutineCollectionViewCell
            
            let session = todaySession[indexPath.item]
            
            let date = istToday
            
            let items = dataController.getRoutineItems(for: session.routineType, date: date)
            
            let handledCount = items.filter {
                let progress = dataController.loadProgress(for: $0, date: date)
                return progress.status == .completed || progress.status == .skipped
            }.count
            
            let totalCount = items.count
            
            let footnote = dataController.dynamicFootnote(routineType: session.routineType, completedItems: handledCount, totalItems: totalCount, rotationSeed: 4)
            
            cell.configureCell(routineType: session.routineType, completedItems: handledCount, totalItems: totalCount, footnote: footnote, theme: dataController.theme)
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        guard let sectionType = RoutineSection(rawValue: indexPath.section) else {
            return UICollectionReusableView()
        }
        
        if sectionType == .recommended && kind == "header" {
            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "routine_header", for: indexPath) as! RoutineHeaderCollectionReusableView
            
            let day = max(1, dataController.userProfile.gestationalDay)
            
            headerView.configure(gestationalWeek: dataController.userProfile.gestationalWeek, day: day, trimester: dataController.userProfile.trimester, theme: dataController.theme)
            
            return headerView
        }
        
        if sectionType == .routine && kind == "footer" {
            
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "routine_footer", for: indexPath) as! RoutineFooterCollectionReusableView
            
            footerView.configureCell(theme: dataController.theme)
            
            return footerView
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 30)
        
        UIView.animate(withDuration: 0.5, delay: Double(indexPath.item) * 0.05, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.8, options: [], animations: {
            cell.alpha = 1
            cell.transform = .identity
        })
    }
    
}

extension RoutineViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let sectionType = RoutineSection(rawValue: indexPath.section) else { return }
        
        if sectionType == .routine {
            performSegue(withIdentifier: "routine_to_dailyRoutine", sender: indexPath)
        }
    }
}
