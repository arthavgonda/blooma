//
//  ProfileDetailValueCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 25/03/26.
//

import UIKit

class ProfileDetailValueCollectionViewCell: UICollectionViewCell, UITextFieldDelegate {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var chevronImageView: UIImageView!
    @IBOutlet weak var tapButton: UIButton!
    
    private var theme: AppTheme!
    
    var onTextChange: ((String) -> Void)?
    var onTap: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupBase()
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.cornerRadius = 16
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        valueLabel.text = nil
        valueTextField.text = nil
    }
    
    
    private func setupBase() {
        
        valueTextField.delegate = self
        
        valueTextField.borderStyle = .none
        valueTextField.textAlignment = .right
    }
    
    private func setupUI() {

        containerView.backgroundColor = theme.glassMedium
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = theme.glassBorderLight.cgColor

        containerView.layer.shadowColor = theme.shadowSoft.cgColor
        containerView.layer.shadowOpacity = 0.15
        containerView.layer.shadowRadius = 10
        containerView.layer.shadowOffset = CGSize(width: 0, height: 6)

        titleLabel.textColor = theme.primaryText
        valueLabel.textColor = theme.secondaryText

        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = theme.secondaryText
    }
    
    
    func configure(title: String, value: String?, theme: AppTheme, isEditing: Bool, isTextEditable: Bool, isPicker: Bool = false, isEditable: Bool = true       ) {
        
        self.theme = theme
        setupUI()
        
        titleLabel.text = title
        valueLabel.text = value
        valueTextField.text = value
        
        if !isEditable {
            valueLabel.isHidden = false
            valueTextField.isHidden = true
            chevronImageView.isHidden = true
            return
        }
        
        if isEditing && isTextEditable {
            
            valueLabel.isHidden = true
            valueTextField.isHidden = false
            chevronImageView.isHidden = true
            
            valueTextField.textColor = .systemBlue
        }
        
        else if isEditing && isPicker {
            
            valueLabel.isHidden = false
            valueTextField.isHidden = true
            valueLabel.textColor = theme.buttonText
            
            valueLabel.textColor = .systemBlue
            chevronImageView.isHidden = false
        }
        
        else {
            
            valueLabel.isHidden = false
            valueTextField.isHidden = true
            
            valueLabel.textColor = theme.secondaryText
            chevronImageView.isHidden = !isEditing
        }
    }
    
    @IBAction func valueTextFieldChanged(_ sender: UITextField) {
        onTextChange?(sender.text ?? "")
    }
    
    @IBAction func tapButtonTapped(_ sender: UIButton) {
        
        if !valueTextField.isHidden {
            valueTextField.becomeFirstResponder()
        } else {
            onTap?()
        }
    }
    
}

extension ProfileDetailValueCollectionViewCell {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        onTextChange?(textField.text ?? "")
    }
}
