//
//  greetCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 13/05/26.
//

import UIKit

class greetCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var trimesterBadgeView: UIView!
    @IBOutlet weak var badgeDotView: UIView!
    @IBOutlet weak var trimesterBadge: UILabel!
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var dueInTitleLabel: UILabel!
    @IBOutlet weak var dueSubLabel: UILabel!
    @IBOutlet weak var weekText: UILabel!
    @IBOutlet weak var trimEndTitleLabel: UILabel!
    @IBOutlet weak var trimEndValueLabel: UILabel!
    @IBOutlet weak var trimesterText: UILabel!
    
    private var theme: AppTheme?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    override func layoutSubviews() {
        super.layoutSubviews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
//        pregnancyRingView.reset()
    }

    // MARK: - Setup

    private func setupUI(theme: AppTheme) {
        layer.shadowOpacity = 0
        layer.masksToBounds = false

        // MARK: Glass card
        cardView.backgroundColor     = theme.glassMedium
        cardView.layer.cornerRadius  = 24
        cardView.layer.cornerCurve   = .continuous
        cardView.layer.masksToBounds = false
        cardView.layer.borderWidth   = 1
        cardView.layer.borderColor   = theme.glassBorderLight.cgColor
        cardView.layer.shadowColor   = theme.shadowSoft.cgColor
        cardView.layer.shadowOpacity = 1
        cardView.layer.shadowRadius  = 16
        cardView.layer.shadowOffset  = CGSize(width: 0, height: 4)

        // MARK: Trimester badge
        trimesterBadgeView.backgroundColor     = theme.accentPrimary.withAlphaComponent(0.12)
        trimesterBadgeView.layer.cornerRadius  = 10
        trimesterBadgeView.layer.cornerCurve   = .continuous
        trimesterBadgeView.layer.masksToBounds = true
        trimesterBadgeView.layer.borderWidth   = 1
        trimesterBadgeView.layer.borderColor   = theme.accentPrimary.withAlphaComponent(0.25).cgColor

        badgeDotView.backgroundColor     = theme.accentPrimary
        badgeDotView.layer.cornerRadius  = 3
        badgeDotView.layer.shadowOpacity = 0

        trimesterBadge.textColor = theme.accentSecondary
        trimesterBadge.font      = .systemFont(ofSize: 11, weight: .semibold)

        // MARK: Greeting
        greetingLabel.textColor = theme.secondaryText
        greetingLabel.font      = .systemFont(ofSize: 14, weight: .semibold)

        dueInTitleLabel.textColor = theme.secondaryText
        dueInTitleLabel.font      = .systemFont(ofSize: 11, weight: .medium)
        
        weekText.textColor = theme.secondaryText
        weekText.font = .systemFont(ofSize: 11, weight: .medium)
        
        trimesterText.textColor = theme.secondaryText
        trimesterText.font      = .systemFont(ofSize: 11, weight: .medium)

        dueSubLabel.textColor = theme.primaryText
        dueSubLabel.font = .systemFont(ofSize: 20, weight: .bold)
        
        trimEndTitleLabel.textColor = theme.secondaryText
        trimEndTitleLabel.font      = .systemFont(ofSize: 11, weight: .medium)

        trimEndValueLabel.textColor = theme.primaryText
        trimEndValueLabel.font      = .systemFont(ofSize: 20, weight: .bold)
    }

    private func styleStatContainer(_ view: UIView, theme: AppTheme) {
        view.backgroundColor     = theme.glassThin
        view.layer.cornerRadius  = 14
        view.layer.cornerCurve   = .continuous
        view.layer.masksToBounds = true
        view.layer.borderWidth   = 1
        view.layer.borderColor   = theme.glassBorderLight.cgColor
    }

    // MARK: - Configure

    func configure(week: Int, trimester: Int, dueDate: Date, profile: UserProfile, theme: AppTheme) {
        self.theme = theme
        setupUI(theme: theme)

        let firstName = profile.name
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: " ")
            .first
            .flatMap { $0.isEmpty ? nil : $0 } ?? "Mother"

        trimesterBadge.text  = "Trimester \(trimester) · Week \(week)"
        greetingLabel.text   = "\(greetingForTime()),"
        userName.text = "\(firstName)"

        let daysLeft         = daysUntilDue(dueDate)
        dueInTitleLabel.text = "Due in"
        weekText.text = "Weeks"
//        dueValue.text        = "\(daysLeft) days"
        dueSubLabel.text     = "\(daysLeft / 7)"

        let trimesterEndWeek   = trimester == 1 ? 13 : trimester == 2 ? 26 : 40
        let daysToTrimEnd      = max(0, (trimesterEndWeek - week) * 7)
        trimEndTitleLabel.text = "Trimester ends"
        trimEndValueLabel.text = "\(daysToTrimEnd)"
        trimesterText.text = "Days"
//        trimEndSubLabel.text   = "Baby's Size: \(babySize(for: week))"

//        let progress          = CGFloat(min(week * 7, 280)) / 280.0
//        ringPercentLabel.text = "\(Int(progress * 100))%"
//        pregnancyJourney.text = "Your journey"
//        pregnancyRingView.animateTo(progress: progress)
    }

    // MARK: - Helpers

    private func daysUntilDue(_ dueDate: Date) -> Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0)
    }

    private func greetingForTime() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

}
