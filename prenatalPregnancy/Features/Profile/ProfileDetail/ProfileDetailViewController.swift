//
//  ProfileDetailViewController.swift
//  prenatalPregnancy
//
//  Created by GEU on 25/03/26.
//

import UIKit

class ProfileDetailViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var editBarButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchBarHeightConstraint: NSLayoutConstraint!
    
    var dataController: DataController!
    var theme: AppTheme!
    var row: ProfileRow!
    
    private var valueItems: [ProfileDetailItem] = []
    private var permissionItems: [PermissionItem] = []
    private var faqItems: [BloomaFAQItem] = []
    private var filteredFAQItems: [BloomaFAQItem] = []
    private var expandedFAQIds: Set<Int> = []
    
    private var isEditingMode = false
    var selectedIndexValue: Any?
    
    private var selectedPickerTitle: String?
    private var appContent: AppContent?
    
    private var isHelpSupport: Bool {
        row == .helpSupport
    }
    
    private func setValue() {
        
        self.theme = dataController.theme
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setValue()
        
        setupUI()
        setupCollectionView()
        generateItems()
        
        navigationController?.navigationBar.tintColor = theme.accentPrimary
        navigationItem.largeTitleDisplayMode = .never
        
        // Do any additional setup after loading the view.
    }
    
    private func setupUI() {
        applyAnimatedBackground(theme: theme)
        collectionView.backgroundColor = .clear
        
        if row.isEditable {
            navigationItem.rightBarButtonItem = editBarButton
            editBarButton.title = "Edit"
            editBarButton.tintColor = theme.accentPrimary
        } else {
            navigationItem.rightBarButtonItem = nil
        }
        
        setupSearchBar()
    }
    
    private func setupSearchBar() {
        searchBar.isHidden = !isHelpSupport
        searchBarHeightConstraint.constant = isHelpSupport ? 56 : 0
        searchBar.delegate = self
        searchBar.placeholder = "Search FAQs"
        searchBar.backgroundImage = UIImage()
        searchBar.searchTextField.backgroundColor = theme.glassMedium
        searchBar.searchTextField.textColor = theme.primaryText
        searchBar.tintColor = theme.accentPrimary
        searchBar.searchTextField.leftView?.tintColor = theme.accentPrimary
    }
    
    private func setupCollectionView() {
        
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        
        collectionView.register(UINib(nibName: "ProfileDetailValueCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "valueCell")
        
        collectionView.register(UINib(nibName: "CustomPickerViewCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "CustomPickerViewCollectionViewCell")
        
        collectionView.register(UINib(nibName: "PermissionCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "permissionCell")
        
        collectionView.register(UINib(nibName: "ContentIntroCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "introCell")

        collectionView.register(UINib(nibName: "ContentFeatureCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "featureCell")
        
        collectionView.register(UINib(nibName: "FAQCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "faqCell")
        
        collectionView.register(UINib(nibName: "ContentSectionHeaderView", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "ContentSectionHeaderView")
        
        collectionView.collectionViewLayout = createLayout()
        
        collectionView.alwaysBounceVertical = true
        
        collectionView.delegate = self
    }
    
    func createLayout() -> UICollectionViewLayout {
        
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            
            guard let self = self else { return nil }
            
            if self.isHelpSupport {
                
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(86))
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 8
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 24, trailing: 0)
                
                return section
            }
            
            if self.row == .permissions {
                
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(120))
                
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 0

                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                
                return section
            }
            
            if self.appContent != nil {

                let isIntroSection = sectionIndex % 2 == 0

                let height: CGFloat = isIntroSection ? 420 : 140

                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(height))

                let item = NSCollectionLayoutItem(layoutSize: size)

                let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)

                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50))

                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)

                if isIntroSection {
                    section.boundarySupplementaryItems = [header]
                }

                return section
            }
            
            if sectionIndex == 0 && !self.valueItems.isEmpty {
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(80))
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 0
                
                return section
            }
            
            let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
            
            let item = NSCollectionLayoutItem(layoutSize: size)
            let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            
            return section
        }
    }
    
    private func generateItems() {
        
        let profile = dataController.userProfile
        
        if let contentId = row.contentId {
            appContent = dataController.loadAppContent(id: contentId)
            
            valueItems = []
            collectionView.reloadData()
            return
        }
        
        switch row {
            
        case .personalInformation:
            valueItems = [
                .value(title: "Name", value: profile.name),
                .value(title: "Username", value: profile.userName),
                .value(title: "Password", value: "••••••••"),
                .value(title: "Age", value: "\(profile.age)")
            ]
            
        case .pregnancyInformation:
            valueItems = [
                .value(title: "LMP", value: displayDate(profile.lmpDate)),
                .value(title: "EDD", value: displayDate(profile.eddDate)),
                .value(title: "Gestational Week & Day", value: "Week \(profile.gestationalWeek) + \(profile.gestationalDay) days"),
                .value(title: "Trimester", value: profile.trimester.displayTitle)
            ]
            
        case .medicalConditions:
            let conditions = profile.medicalConditions
            let display: String
            
            if conditions.isEmpty {
                display = "None"
            } else if conditions.count <= 1 {
                display = conditions.map { $0.displayName }.joined(separator: ", ")
            } else {
                let first = conditions.prefix(1).map { $0.displayName }
                let remaining = conditions.count - 1
                display = first.joined(separator: ", ") + " +\(remaining) more"
            }
            
            valueItems = [.value(title: "Medical Conditions", value: display)]
            
        case .activityStatus:
            valueItems = [.value(title: "Activity Level", value: profile.activityLevel.displayName)]
            
        case .appleWatch:
            valueItems = [.value(title: "Apple Watch", value: profile.hasAppleWatch ? "Connected" : "Not Connected")]
        
        case .permissions:
            permissionItems = PermissionItem.all
            valueItems = []
            
        case .helpSupport:
            faqItems = loadFAQItems()
            filteredFAQItems = faqItems
            valueItems = []
            
        case .logout:
            valueItems = [.value(title: "Logout", value: nil)]
            
        default:
            valueItems = []
        }
        
        collectionView.reloadData()
    }
    
    private func loadFAQItems() -> [BloomaFAQItem] {
        guard let url = Bundle.main.bloomaResourceURL(named: "blooma_faq", fileExtension: "json") else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(BloomaFAQResponse.self, from: data)
            return decoded.faqs
        } catch {
            print("FAQ Decode error:", error)
            return []
        }
    }
    
    func showAppleWatchDialog() {
        
        let isConnected = dataController.userProfile.hasAppleWatch
        
        let alert = UIAlertController(title: "Apple Watch", message: isConnected ? "Manage connection" : "Connect your Apple Watch", preferredStyle: .actionSheet)
        
        if isConnected {
            alert.addAction(UIAlertAction(title: "Disconnect", style: .destructive) { _ in
                self.dataController.updateHasAppleWatch(false)
                self.generateItems()
            })
            
            alert.addAction(UIAlertAction(title: "Reconnect", style: .default) { _ in
                self.connectAppleWatchFromProfile()
            })
        } else {
            alert.addAction(UIAlertAction(title: "Connect", style: .default) { _ in
                self.connectAppleWatchFromProfile()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func connectAppleWatchFromProfile() {
        dataController.connectAppleWatch { [weak self] success in
            guard let self else { return }
            self.generateItems()
            
            guard !success else { return }
            
            let alert = UIAlertController(
                title: "Health Access Unavailable",
                message: "We could not connect to Health right now. You can enable it later from Settings.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    private func displayDate(_ date: Date?) -> String {
        guard let date else { return "Not set" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func defaultLMPDate() -> Date {
        let profile = dataController.userProfile
        
        if let lmpDate = profile.lmpDate {
            return lmpDate
        }
        
        return PregnancyDateCalculation.estimatedLMP(
            fromWeek: profile.gestationalWeek,
            day: profile.gestationalDay
        )
    }
    
    private func defaultEDDDate() -> Date {
        let profile = dataController.userProfile
        
        if let eddDate = profile.eddDate {
            return eddDate
        }
        
        return PregnancyDateCalculation.fromLMP(defaultLMPDate()).eddDate
    }
    
    func showChangePasswordPopup() {
        
        let alert = UIAlertController(title: "Change Password", message: nil, preferredStyle: .alert)
        
        alert.addTextField { field in
            field.placeholder = "Old Password"
            field.isSecureTextEntry = true
        }
        
        alert.addTextField { field in
            field.placeholder = "New Password"
            field.isSecureTextEntry = true
        }
        
        alert.addTextField { field in
            field.placeholder = "Confirm Password"
            field.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Change", style: .default) { [weak self] _ in
            
            guard let self = self else { return }
            
            let old = alert.textFields?[0].text ?? ""
            let new = alert.textFields?[1].text ?? ""
            let confirm = alert.textFields?[2].text ?? ""
            
            let result = self.dataController.changePassword(old: old, new: new, confirm: confirm)
            
            if result.0 {
                self.showAlert(title: "Success", message: result.1)
            } else {
                self.showAlert(title: "Error", message: result.1)
            }
        })
        
        present(alert, animated: true)
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func showLogoutConfirmation() {
        
        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            self.dataController?.logout()
            
            if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                sceneDelegate.dataModel = DataController(userProfile: UserProfile(
                    userId: UUID(),
                    profileImageData: nil,
                    name: "",
                    email: nil,
                    userName: "",
                    password: "",
                    age: 0,
                    lmpDate: nil,
                    eddDate: nil,
                    gestationalWeek: 1,
                    gestationalDay: 0,
                    trimester: .first,
                    medicalConditions: [],
                    activityLevel: .low,
                    hasAppleWatch: false
                ))
                sceneDelegate.showLogin(storyboard: storyboard)
            }
        })
        
        present(alert, animated: true)
    }
    
    @IBAction func editTapped(_ sender: UIBarButtonItem) {
        
        isEditingMode.toggle()
        editBarButton.title = isEditingMode ? "Save" : "Edit"
        
        collectionView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "show_picker_bottom_sheet" {
            
            guard let vc = segue.destination as? PickerBottomSheetViewController else { return }
            
            vc.theme = theme
            
            let profile = dataController.userProfile
            
            switch selectedPickerTitle {
                
            case "Age":
                vc.type = .age
                vc.selectedIndexValue = profile.age
                
            case "LMP":
                vc.type = .lmpDate
                vc.selectedIndexValue = defaultLMPDate()
                
            case "EDD":
                vc.type = .eddDate
                vc.selectedIndexValue = defaultEDDDate()
                
            case "Activity Level":
                vc.type = .activity
                vc.selectedIndexValue = profile.activityLevel
                
            case "Medical Conditions":
                vc.loadViewIfNeeded()
                vc.enableMedicalMode(selected: profile.medicalConditions)
                
            default:
                break
            }
            
            vc.onApply = { [weak self] value in
                guard let self else { return }
                
                switch self.selectedPickerTitle {
                    
                case "Age":
                    self.dataController.updateUserAge(value as! Int)
                    
                case "LMP":
                    let calculation = PregnancyDateCalculation.fromLMP(value as! Date)
                    self.dataController.updatePregnancyDates(
                        lmpDate: calculation.lmpDate,
                        eddDate: calculation.eddDate,
                        gestationalWeek: calculation.gestationalWeek,
                        gestationalDay: calculation.gestationalDay,
                        trimester: calculation.trimester
                    )
                    
                case "EDD":
                    let calculation = PregnancyDateCalculation.fromEDD(value as! Date)
                    self.dataController.updatePregnancyDates(
                        lmpDate: calculation.lmpDate,
                        eddDate: calculation.eddDate,
                        gestationalWeek: calculation.gestationalWeek,
                        gestationalDay: calculation.gestationalDay,
                        trimester: calculation.trimester
                    )
                    
                case "Activity Level":
                    self.dataController.updateActivityLevel(value as! ActivityLevel)
                    
                case "Medical Conditions":
                    if let conditions = value as? [MedicalCondition] {
                        self.dataController.updateMedicalCondition(conditions)
                    }
                    
                default:
                    break
                }
                
                self.generateItems()
            }
            
            vc.modalPresentationStyle = .pageSheet
            
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }
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

extension ProfileDetailViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        if let content = appContent {
            return content.sections.count * 2
        }
        
        if isHelpSupport {
            return 1
        }
        
        if row == .permissions {
            return 1
        }
        
        return valueItems.isEmpty ? 0 : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if row == .permissions {
            return permissionItems.count
        }
        
        if isHelpSupport {
            return filteredFAQItems.count
        }
        
        guard let content = appContent else {
            return valueItems.count
        }
        
        let contentIndex = section / 2
        let isIntroSection = section % 2 == 0
        
        let sectionData = content.sections[contentIndex]
        
        return isIntroSection ? sectionData.content.introBlocks.count : sectionData.content.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if row == .permissions {
            
            let item = permissionItems[indexPath.item]
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "permissionCell", for: indexPath) as! PermissionCollectionViewCell
            
            let status = dataController.getPermissionStatus(for: item.type)
            
            cell.configure(item: item, status: status, theme: theme)
            return cell
        }
        
        if isHelpSupport {
            
            let item = filteredFAQItems[indexPath.item]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "faqCell", for: indexPath) as! FAQCollectionViewCell
            
            cell.configure(
                icon: item.icon,
                question: item.displayQuestion,
                answer: item.answer,
                isExpanded: expandedFAQIds.contains(item.id),
                theme: theme
            )
            
            return cell
        }
        
        if row == .logout {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "valueCell", for: indexPath) as! ProfileDetailValueCollectionViewCell
            
            cell.configure(title: "Logout", value: nil, theme: theme, isEditing: false, isTextEditable: false, isPicker: false, isEditable: false)
            
            cell.titleLabel.textColor = theme.error
            
            cell.onTap = { [weak self] in
                self?.showLogoutConfirmation()
            }
            
            return cell
        }
        
        if let content = appContent {
            
            let contentIndex = indexPath.section / 2
            let isIntroSection = indexPath.section % 2 == 0
            
            let sectionData = content.sections[contentIndex]
            
            if isIntroSection {
                
                let block = sectionData.content.introBlocks[indexPath.item]
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "introCell", for: indexPath) as! ContentIntroCollectionViewCell
                
                cell.configure(section: block.label, heading: block.heading, body: block.paragraphs.joined(separator: "\n\n"), theme: theme)
                
                return cell
            }
            
            let item = sectionData.content.items[indexPath.item]
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "featureCell", for: indexPath) as! ContentFeatureCollectionViewCell
            
            cell.configure(icon: item.icon, title: item.title, description: item.description, theme: theme)
            
            return cell
        }
        
        let item = valueItems[indexPath.item]
        
        if case let .value(title, value) = item {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "valueCell", for: indexPath) as! ProfileDetailValueCollectionViewCell
            
            let isText = (title == "Name" || title == "Username")
            let isPicker = (title == "Age" || title == "LMP" || title == "EDD" || title == "Activity Level" || title == "Medical Conditions")
            let isEditable = (title != "Trimester" && title != "Gestational Week & Day")
            
            cell.configure(title: title, value: value, theme: theme, isEditing: isEditingMode, isTextEditable: isText, isPicker: isPicker, isEditable: isEditable)
            
            cell.onTextChange = { [weak self] text in
                guard let self = self else { return }
                
                if title == "Name" {
                    self.dataController.updateUserName(name: text)
                } else if title == "Username" {
                    self.dataController.updateUserCredentials(username: text, password: self.dataController.userProfile.password)
                }
                
                self.generateItems()
            }
            
            cell.onTap = { [weak self] in
                guard let self = self else { return }
                guard self.isEditingMode else { return }
                
                if title == "Password" {
                    self.showChangePasswordPopup()
                    return
                }
                
                if title == "Name" || title == "Username" {
                    return
                }
                
                if title == "Age" || title == "LMP" || title == "EDD" || title == "Activity Level" || title == "Medical Conditions" {
                    self.selectedPickerTitle = title
                    self.performSegue(withIdentifier: "show_picker_bottom_sheet", sender: nil)
                    return
                }
                
                if title == "Apple Watch" {
                    self.showAppleWatchDialog()
                    return
                }
            }
            
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        guard let content = appContent else {
            return UICollectionReusableView()
        }
        
        let isIntroSection = indexPath.section % 2 == 0
        
        if !isIntroSection {
            return UICollectionReusableView()
        }
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ContentSectionHeaderView", for: indexPath) as! ContentSectionHeaderView
        
        let contentIndex = indexPath.section / 2
        
        let section = content.sections[contentIndex]
        
        header.configure(title: section.title, theme: theme)
        
        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 20)
        
        UIView.animate(withDuration: 0.4, delay: Double(indexPath.item) * 0.03, options: [], animations: {
            cell.alpha = 1
            cell.transform = .identity
        }
        )
    }
    
}

extension ProfileDetailViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if isHelpSupport {
            let item = filteredFAQItems[indexPath.item]
            
            if expandedFAQIds.contains(item.id) {
                expandedFAQIds.remove(item.id)
            } else {
                expandedFAQIds.insert(item.id)
            }
            
            collectionView.reloadSections(IndexSet(integer: 0))
            return
        }
        
        guard row == .permissions else { return }
        
        let item = permissionItems[indexPath.item]
        let status = dataController.getPermissionStatus(for: item.type)

        switch status {
            
        case .authorized:
            return
            
        case .notDetermined:
            dataController.requestPermission(item.type) {
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
            
        case .denied:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
    }
}

extension ProfileDetailViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if query.isEmpty {
            filteredFAQItems = faqItems
        } else {
            filteredFAQItems = faqItems.filter { item in
                item.question.localizedCaseInsensitiveContains(query) ||
                item.answer.localizedCaseInsensitiveContains(query) ||
                item.category.localizedCaseInsensitiveContains(query) ||
                item.keywords.contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }
        
        guard collectionView.numberOfSections > 0 else { return }
        collectionView.reloadSections(IndexSet(integer: 0))
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
