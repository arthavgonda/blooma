//
//  WeekPickerViewController.swift
//  prenatalPregnancy
//
//  Created by GEU on 18/04/26.
//

import UIKit

protocol WeekPickerViewControllerDelegate: AnyObject {
    func didSelectWeeks(_ weeks: [String])
}


class WeekPickerViewController: UIViewController {

    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var exportButton: UIButton!
    
    
    
    var dataController: DataController!
    var theme: AppTheme!
    weak var delegate: WeekPickerViewControllerDelegate?
    
    var selectedWeeks: Set<Int> = []
    
    var availableWeeks: [Int] {
        let currentWeek = max(1, min(dataController?.userProfile.gestationalWeek ?? 1, PregnancyDateCalculation.maxGestationalWeek))
        return Array(1...currentWeek)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        theme = dataController.theme
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        subtitleLabel.text = "Please select the weeks for which you want to share the data"
                collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = true
        collectionView.backgroundColor = .clear
        
        collectionView.register(
            UINib(nibName: "WeekCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "week_cell"
        )
        
        collectionView.setCollectionViewLayout(generateLayout(), animated: false)
        
     
        if let currentWeek = availableWeeks.last {
            selectedWeeks.insert(currentWeek)
        }
        applyAnimatedBackground(theme: theme)

        subtitleLabel.textColor = theme.tertiaryText
        
                    exportButton.backgroundColor = UIColor.white.withAlphaComponent(0.42)
        exportButton.setTitleColor(theme.primaryText, for: .normal)

        exportButton.layer.cornerRadius = 24
        exportButton.layer.cornerCurve = .continuous

        exportButton.layer.borderWidth = 1
        exportButton.layer.borderColor = UIColor.white.withAlphaComponent(0.55).cgColor
        exportButton.layer.shadowColor = UIColor.white.withAlphaComponent(0.2).cgColor
        exportButton.layer.shadowOpacity = 1
        exportButton.layer.shadowRadius = 8
        exportButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        
        collectionView.backgroundColor = .clear
    }
    

    
    @IBAction func didTapCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        
    }
    @IBAction func didTapExport(_ sender: UIButton) {
        let formattedWeeks = selectedWeeks
            .sorted()
            .map { "W\($0)" }
        
        dismiss(animated: true) {
            self.delegate?.didSelectWeeks(formattedWeeks)
        }
    }
}

extension WeekPickerViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return availableWeeks.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "week_cell",
            for: indexPath
        ) as! WeekCollectionViewCell

        let weekNumber = availableWeeks[indexPath.item]

        cell.configure(
            title: "W\(weekNumber)",
            isSelected: selectedWeeks.contains(weekNumber),
            themeColor: theme.accentSecondary,
            theme: theme
        )

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let week = availableWeeks[indexPath.item]

        if selectedWeeks.contains(week) {
            selectedWeeks.remove(week)
        } else {
            selectedWeeks.insert(week)
        }

        collectionView.reloadItems(at: [indexPath])
    }
}


extension WeekPickerViewController {

    func generateLayout() -> UICollectionViewLayout {

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(64),
            heightDimension: .absolute(52)
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .estimated(64),
            heightDimension: .absolute(52)
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 12,
            leading: 16,
            bottom: 12,
            trailing: 16
        )

        return UICollectionViewCompositionalLayout(section: section)
    }
}
