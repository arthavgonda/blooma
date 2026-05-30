//
//  ProfileHeaderCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 24/03/26.
//

import UIKit

class ProfileHeaderCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var cameraButton: UIButton!
    
    var theme: AppTheme!
    
    var onCameraTap: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        
        cameraButton.layer.cornerRadius = cameraButton.frame.height / 2
    }
    
    private func setupUI() {
        
        containerView.backgroundColor = theme.glassMedium
        containerView.layer.cornerRadius = 20
        containerView.layer.masksToBounds = true
        
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = theme.glassBorderLight.cgColor
        
        nameLabel.textColor = theme.primaryText
        nicknameLabel.textColor = theme.secondaryText
        
        profileImageView.backgroundColor = theme.glassThin
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = theme.glassBorderStrong.cgColor
        
        cameraButton.backgroundColor = theme.buttonGlassBackground
        cameraButton.layer.borderWidth = 1
        cameraButton.layer.borderColor = theme.buttonGlassBorder.cgColor
        cameraButton.tintColor = theme.primaryText
    }
    
    func configure(name: String, nickname: String, image: Data?, imageUrl: String? = nil, theme: AppTheme) {
        self.theme = theme
        setupUI()

        nameLabel.text = name
        nicknameLabel.text = "@\(nickname)"

        if let imageData = image, let uiImage = UIImage(data: imageData) {
            // Local data available — show immediately
            setProfileImage(uiImage)
        } else if let urlString = imageUrl, let url = URL(string: urlString) {
            // Fetch from Cloudinary
            profileImageView.image = UIImage(systemName: "person.fill",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .medium))
            profileImageView.tintColor = theme.accentPrimary
            profileImageView.contentMode = .center

            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self, let data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self.setProfileImage(image)
                    // Cache locally for next time
                    self.onImageDownloaded?(data)
                }
            }.resume()
        } else {
            // No image at all
            let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
            profileImageView.image = UIImage(systemName: "person.fill", withConfiguration: config)
            profileImageView.tintColor = theme.accentPrimary
            profileImageView.contentMode = .center
            profileImageView.backgroundColor = theme.glassThin
        }
    }

    var onImageDownloaded: ((Data) -> Void)?

    private func setProfileImage(_ image: UIImage) {
        profileImageView.image = image
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.tintColor = nil
    }
    
    @IBAction func cameraTapped() {
        onCameraTap?()
    }
    
}
