//
//  OptionsCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 09/04/26.
//

import UIKit

class OptionsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!

    private var selectedIndex: Int = -1
    private var theme: AppTheme!

    var onSelectionChanged: ((Int) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupButtons()
        // Initialization code
    }

    private func setupButtons() {
        [button1, button2, button3].forEach { button in
            button?.layer.cornerRadius = 20
            button?.layer.cornerCurve = .continuous
            button?.layer.borderWidth = 1
            button?.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            button?.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
            button?.addTarget(self, action: #selector(optionTouchDown(_:)), for: [.touchDown, .touchDragEnter])
            button?.addTarget(self, action: #selector(optionTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        }
    }

    func configure(options: [String], selected: Int?, theme: AppTheme) {
        self.theme = theme
        self.selectedIndex = selected ?? -1

        let buttons = [button1, button2, button3]

        for i in 0..<buttons.count {
            let button = buttons[i]
            button?.setTitle(options[i], for: .normal)
            updateButtonStyle(button: button!, isSelected: i == selectedIndex)
        }
    }

    private func updateButtonStyle(button: UIButton, isSelected: Bool) {
        UIView.transition(with: button, duration: 0.18, options: [.transitionCrossDissolve, .allowUserInteraction]) {
            if isSelected {
                button.backgroundColor = self.theme.accentPrimary.withAlphaComponent(0.12)
                button.layer.borderWidth = 2
                button.layer.borderColor = self.theme.accentPrimary.cgColor
                button.setTitleColor(self.theme.accentSecondary, for: .normal)
            } else {
                button.backgroundColor = self.theme.glassMedium
                button.layer.borderWidth = 1
                button.layer.borderColor = self.theme.glassBorderStrong.withAlphaComponent(0.45).cgColor
                button.setTitleColor(self.theme.secondaryText, for: .normal)
            }
            
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.08
            button.layer.shadowRadius = 8
            button.layer.shadowOffset = CGSize(width: 0, height: 4)
        }
    }

    private func updateSelection(index: Int) {
        selectedIndex = index

        let buttons = [button1, button2, button3]

        for i in 0..<buttons.count {
            updateButtonStyle(button: buttons[i]!, isSelected: i == index)
        }

        onSelectionChanged?(index)
    }

    @IBAction func button1Tapped(_ sender: UIButton) {
        updateSelection(index: 0)
    }

    @IBAction func button2Tapped(_ sender: UIButton) {
        updateSelection(index: 1)
    }

    @IBAction func button3Tapped(_ sender: UIButton) {
        updateSelection(index: 2)
    }

    @objc private func optionTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            sender.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }
    }

    @objc private func optionTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.7, options: [.allowUserInteraction]) {
            sender.transform = .identity
        }
    }
}
