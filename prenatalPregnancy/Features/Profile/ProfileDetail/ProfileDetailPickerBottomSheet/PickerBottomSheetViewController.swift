//
//  PickerBottomSheetViewController.swift
//  prenatalPregnancy
//
//  Created by GEU on 28/03/26.
//

import UIKit

class PickerBottomSheetViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var applyButton: UIButton!
    
    var type: PickerType = .age
    var theme: AppTheme!
    var selectedIndexValue: Any?
    
    var onApply: ((Any) -> Void)?
    
    private var ageData = Array(18...45)
    private var weekData = Array(1...42)
    private var activityLevels = ActivityLevel.allCases
    private var medicalConditions = MedicalCondition.allCases
    
    private var selectedIndex = 0
    private var selectedDate = Date()
    private var selectedConditions: Set<MedicalCondition> = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupDelegates()
        updateUI()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setDefaultSelection()
    }
    
    private func setupUI() {
        applyAnimatedBackground(theme: theme)

        containerView.backgroundColor = UIColor.clear
        collectionView.backgroundColor = .clear
        
        pickerView.backgroundColor = .clear
        pickerView.subviews.forEach { $0.backgroundColor = .clear }
        
        datePicker.datePickerMode = .date
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.backgroundColor = .clear
        datePicker.tintColor = theme.accentPrimary

        applyButton.layer.cornerRadius = 24
        applyButton.clipsToBounds = true

        applyButton.setTitle("Apply", for: .normal)
        applyButton.setTitleColor(theme.primaryText, for: .normal)
        applyButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        
        applyButton.backgroundColor = theme.buttonGlassBackground
        applyButton.layer.cornerRadius = 18
        applyButton.layer.borderWidth = 1
        applyButton.layer.borderColor = theme.buttonGlassBorder.cgColor
        
        applyButton.layer.shadowColor = theme.shadowMedium.cgColor
        applyButton.layer.shadowOpacity = 0.08
        applyButton.layer.shadowRadius = 8
        applyButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        
        applyGlassEffect(to: applyButton)
        
    }
    
    private func applyGlassEffect(to view: UIView) {
        
        let blur = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blur)
        
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        blurView.layer.cornerRadius = view.layer.cornerRadius
        blurView.clipsToBounds = true
        
        blurView.isUserInteractionEnabled = false
        
        view.insertSubview(blurView, at: 0)
    }
    
    private func setupDelegates() {
        pickerView.delegate = self
        pickerView.dataSource = self
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.contentInsetAdjustmentBehavior = .never
        
        collectionView.register(UINib(nibName: "MedicalConditionCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "MedicalConditionCollectionViewCell")
    }
    
    private func updateUI() {
        switch type {
        case .age, .week, .activity:
            pickerView.isHidden = false
            datePicker.isHidden = true
            collectionView.isHidden = true
        case .lmpDate, .eddDate:
            pickerView.isHidden = true
            datePicker.isHidden = false
            collectionView.isHidden = true
            configureDatePickerLimits()
        }
    }
    
    func enableMedicalMode(selected: [MedicalCondition]) {
        selectedConditions = Set(selected)
        
        collectionView.setCollectionViewLayout(generateMedicalLayout(), animated: false)
        
        pickerView.isHidden = true
        datePicker.isHidden = true
        collectionView.isHidden = false
    }
    
    @IBAction func applyTapped(_ sender: UIButton) {
        if !collectionView.isHidden {
            onApply?(Array(selectedConditions))
            dismiss(animated: true)
            return
        }
        
        if !datePicker.isHidden {
            onApply?(selectedDate)
            dismiss(animated: true)
            return
        }
        
        switch type {
        case .age:
            onApply?(ageData[selectedIndex])
        case .week:
            onApply?(weekData[selectedIndex])
        case .activity:
            onApply?(activityLevels[selectedIndex])
        case .lmpDate, .eddDate:
            break
        }
        
        dismiss(animated: true)
    }
    
    @IBAction func datePickerChanged(_ sender: UIDatePicker) {
        selectedDate = sender.date
        
        UIView.animate(withDuration: 0.16, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.18) {
                sender.transform = .identity
            }
        }
    }
    
    private func setDefaultSelection() {
        if type == .lmpDate || type == .eddDate {
            configureDatePickerLimits()
            
            if let date = selectedIndexValue as? Date {
                selectedDate = date
            }
            
            datePicker.setDate(clampedDate(selectedDate), animated: false)
            selectedDate = datePicker.date
            return
        }
        
        guard let value = selectedIndexValue else { return }
        
        switch type {
        case .age:
            if let age = value as? Int,
               let index = ageData.firstIndex(of: age) {
                pickerView.selectRow(index, inComponent: 0, animated: false)
                selectedIndex = index
            }
        case .week:
            if let week = value as? Int,
               let index = weekData.firstIndex(of: week) {
                pickerView.selectRow(index, inComponent: 0, animated: false)
                selectedIndex = index
            }
        case .activity:
            if let activity = value as? ActivityLevel,
               let index = activityLevels.firstIndex(of: activity) {
                pickerView.selectRow(index, inComponent: 0, animated: false)
                selectedIndex = index
            }
        case .lmpDate, .eddDate:
            break
        }
        
        pickerView.reloadAllComponents()
    }
    
    private func configureDatePickerLimits() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        switch type {
        case .lmpDate:
            datePicker.minimumDate = calendar.date(byAdding: .day, value: -294, to: today)
            datePicker.maximumDate = today
        case .eddDate:
            datePicker.minimumDate = today
            datePicker.maximumDate = calendar.date(byAdding: .day, value: 294, to: today)
        default:
            datePicker.minimumDate = nil
            datePicker.maximumDate = nil
        }
        
        selectedDate = clampedDate(selectedDate)
        datePicker.date = selectedDate
    }
    
    private func clampedDate(_ date: Date) -> Date {
        if let minimumDate = datePicker.minimumDate, date < minimumDate {
            return minimumDate
        }
        
        if let maximumDate = datePicker.maximumDate, date > maximumDate {
            return maximumDate
        }
        
        return date
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension PickerBottomSheetViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch type {
        case .age: return ageData.count
        case .week: return weekData.count
        case .activity: return activityLevels.count
        case .lmpDate, .eddDate: return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        let label = (view as? UILabel) ?? UILabel()
        label.textAlignment = .center
        
        switch type {
        case .age:
            label.text = "\(ageData[row]) years"
        case .week:
            label.text = "Week \(weekData[row])"
        case .activity:
            label.text = activityLevels[row].displayName
        case .lmpDate, .eddDate:
            label.text = nil
        }
        
        let isSelected = (row == selectedIndex)
        
        if let theme = theme {
            if isSelected {
                label.textColor = theme.primaryText
                label.font = .systemFont(ofSize: 22, weight: .bold)
                label.alpha = 1.0
            } else {
                label.textColor = theme.primaryText.withAlphaComponent(0.35)
                label.font = .systemFont(ofSize: 18, weight: .regular)
                label.alpha = 0.6
            }
        }
        
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedIndex = row
        pickerView.reloadAllComponents()
    }
}

extension PickerBottomSheetViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        medicalConditions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MedicalConditionCollectionViewCell", for: indexPath) as? MedicalConditionCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let condition = medicalConditions[indexPath.item]
        
        cell.configure(title: condition.rawValue.capitalized, isSelected: selectedConditions.contains(condition), theme: theme!)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let condition = medicalConditions[indexPath.item]
        
        if condition == .none {
            selectedConditions = [.none]
        } else {
            selectedConditions.remove(.none)
            
            if selectedConditions.contains(condition) {
                selectedConditions.remove(condition)
            } else {
                selectedConditions.insert(condition)
            }
            
            if selectedConditions.isEmpty {
                selectedConditions = [.none]
            }
        }
        
        collectionView.reloadData()
    }
    
    private func generateMedicalLayout() -> UICollectionViewLayout {
        
        return UICollectionViewCompositionalLayout { _, _ in
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(64))
            
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(64))
            
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
            
            return section
        }
    }
    
}

private func generateMedicalLayout() -> UICollectionViewLayout {
    
    return UICollectionViewCompositionalLayout { _, _ in
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(64))
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(64))
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        
        return section
    }
}
