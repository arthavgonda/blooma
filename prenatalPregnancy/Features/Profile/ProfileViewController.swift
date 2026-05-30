//
//  ProfileViewController.swift
//  prenatalPregnancy
//
//  Created by GEU on 24/03/26.
//

import UIKit
import PhotosUI

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var dataController: DataController!
    var theme: AppTheme!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Profile"
        
        theme = dataController.theme
        
        setupCollectionView()
        setupUI()
        
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        collectionView.reloadData()
    }
    
    func setupUI() {
        applyAnimatedBackground(theme: theme)
        collectionView.backgroundColor = .clear
    }
    
    func setupCollectionView() {
        
        collectionView.backgroundColor = .clear
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        registerCells()
        
        collectionView.collectionViewLayout = generateLayout()
    }
    
    func registerCells() {
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Register Cells
        collectionView.register(UINib(nibName: "ProfileHeaderCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ProfileHeaderCollectionViewCell")
        
        collectionView.register(UINib(nibName: "ProfileMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ProfileMenuCollectionViewCell")
        
        // Register Header
        collectionView.register(UINib(nibName: "ProfileMenuHeaderReusableView", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "ProfileMenuHeaderReusableView")
        
        collectionView.register(UINib(nibName: "ProfileFooterReusableView", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "ProfileFooterReusableView")
    }
    
    func generateLayout() -> UICollectionViewLayout {
        
        return UICollectionViewCompositionalLayout { sectionIndex, _ in
            
            let sectionType = ProfileSection.allCases[sectionIndex]
            
            if sectionType == .header {
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(120))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                return section
            }
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(56))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(CGFloat(sectionType.rows.count * 56)))
            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: groupSize,
                subitems: Array(repeating: item, count: sectionType.rows.count)
            )
            group.interItemSpacing = .fixed(0)
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0)
            
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(28))
            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            header.contentInsets = NSDirectionalEdgeInsets(top: -8, leading: 0, bottom: 0, trailing: 0)
            section.boundarySupplementaryItems = [header]
            
            if sectionType == .about {
                
                let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(70))
                
                let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
                
                section.boundarySupplementaryItems.append(footer)
            }
            
            return section
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "go_to_profile_detail" {
            
            guard let destination = segue.destination as? ProfileDetailViewController,
                  let row = sender as? ProfileRow else { return }
            
            destination.dataController = dataController
            destination.title = row.title
            
            destination.row = row
            destination.dataController = dataController
        }
    }
    
    private func mapRowToSection(_ row: ProfileRow) -> ProfileSection {
        
        switch row {
            
        case .personalInformation, .pregnancyInformation:
            return .yourInformation
            
        case .medicalConditions, .activityStatus:
            return .healthActivity
            
        case .appleWatch:
            return .devices
            
        case .legalCompliance, .permissions:
            return .privacy
            
        case .helpSupport, .researchInsights, .dataSources:
            return .support
            
        case .aboutBlooma, .credits, .logout:
            return .about
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

extension ProfileViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        ProfileSection.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let sectionType = ProfileSection.allCases[section]
        
        if sectionType == .header {
            return 1
        }
        
        return sectionType.rows.count
    }
}

extension ProfileViewController {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let sectionType = ProfileSection.allCases[indexPath.section]
        
        if sectionType == .header {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileHeaderCollectionViewCell", for: indexPath) as! ProfileHeaderCollectionViewCell
            
            cell.onCameraTap = { [weak self] in
                self?.showImageSourceActionSheet()
            }
            
            let profile = dataController.userProfile
            
            cell.configure(name: profile.name, nickname: profile.userName, image: profile.profileImageData, imageUrl: profile.profileImageUrl, theme: theme)
            
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileMenuCollectionViewCell", for: indexPath) as! ProfileMenuCollectionViewCell
        
        let row = sectionType.rows[indexPath.item]
        let isFirst = indexPath.item == 0
        let isLast = indexPath.item == sectionType.rows.count - 1
        
        cell.configure(row: row, isFirst: isFirst, isLast: isLast, theme: theme)
        
        cell.backgroundColor = .clear
        cell.layer.borderWidth = 0
        cell.layer.cornerRadius = 0
        
        if row == .logout {
            
            cell.iconImageView.image = UIImage(systemName: row.icon)?.withRenderingMode(.alwaysTemplate)
            
            cell.iconImageView.tintColor = .systemRed
            cell.titleLabel.textColor = .systemRed
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let sectionType = ProfileSection.allCases[indexPath.section]
        
        if kind == UICollectionView.elementKindSectionHeader {
            
            if sectionType == .header {
                return UICollectionReusableView()
            }
            
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ProfileMenuHeaderReusableView", for: indexPath) as! ProfileMenuHeaderReusableView
            
            header.configure(title: sectionType.title, theme: theme)
            return header
        }
        
        if kind == UICollectionView.elementKindSectionFooter,
           sectionType == .about {
            
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ProfileFooterReusableView", for: indexPath) as! ProfileFooterReusableView
            
            footer.configure(theme: theme)
            return footer
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 20)
        
        UIView.animate(
            withDuration: 0.4,
            delay: Double(indexPath.item) * 0.03,
            options: [],
            animations: {
                cell.alpha = 1
                cell.transform = .identity
            }
        )
    }
}

extension ProfileViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let sectionType = ProfileSection.allCases[indexPath.section]
        if sectionType == .header { return }
        
        let row = sectionType.rows[indexPath.item]
        
        if row == .logout {
            showLogoutConfirmation()
            return
        }
        
        performSegue(withIdentifier: "go_to_profile_detail", sender: row)
    }
    
    func showLogoutConfirmation() {
        
        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
            
            guard let self = self else { return }
            
            self.dataController.logout()
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
            
            let nav = UINavigationController(rootViewController: loginVC)
            
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first {
                
                window.rootViewController = nav
                window.makeKeyAndVisible()
            }
        })
        
        present(alert, animated: true)
    }
}


extension ProfileViewController {
    
    func showImageSourceActionSheet() {
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        let alert = UIAlertController(title: "Update Profile Picture", message: "Choose an option", preferredStyle: .actionSheet)
        
        let cameraAction = UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
            self?.openCamera()
        }
        
        let galleryAction = UIAlertAction(title: "Choose from Gallery", style: .default) { [weak self] _ in
            self?.openGallery()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(cameraAction)
        alert.addAction(galleryAction)
        alert.addAction(cancelAction)
        
        alert.view.tintColor = theme.buttonGlassBackground
        
        present(alert, animated: true)
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("Camera not available")
            return
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.allowsEditing = true
        
        present(picker, animated: true)
    }
    
    func openGallery() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images   // JPEG, PNG, HEIC, WebP — all image types

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true)
        
        let selectedImage = (info[.editedImage] ?? info[.originalImage]) as? UIImage
        
        if let image = selectedImage {
            dataController.updateProfileImage(image)
            collectionView.reloadData()
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
}

extension ProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }

        // file extension supported
        let supportedExtensions = ["jpg", "jpeg", "png", "heic", "heif", "webp"]
        if let identifier = result.itemProvider.registeredTypeIdentifiers.first {
            let ext = identifier.components(separatedBy: ".").last ?? ""
            if !supportedExtensions.contains(ext.lowercased()) && !identifier.contains("image") {
                showUnsupportedFormatAlert()
                return
            }
        }

        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            DispatchQueue.main.async {
                guard let self, let image = object as? UIImage else { return }
                self.showUploadingIndicator()
                self.dataController.updateProfileImage(image)
                self.collectionView.reloadData()
                self.hideUploadingIndicator()
            }
        }
    }

    private func showUnsupportedFormatAlert() {
        let alert = UIAlertController(
            title: "Unsupported Format",
            message: "Please choose a JPEG, PNG, HEIC, or WebP image.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showUploadingIndicator() {
        // Optional: show a small spinner on the profile image cell
    }

    private func hideUploadingIndicator() {
        // Hide spinner
    }
}
