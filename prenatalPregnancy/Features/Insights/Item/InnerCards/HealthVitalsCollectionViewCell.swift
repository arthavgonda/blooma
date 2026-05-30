//
//  HealthVitalsCollectionViewCell.swift
//  prenatalPregnancy
//
//  Created by GEU on 27/03/26.
//

import UIKit

class HealthVitalsCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var peakTitle: UILabel!
    @IBOutlet weak var breathsPerMinLabel: UILabel!
    @IBOutlet weak var heartRateContainerView: UIView!
    @IBOutlet weak var PeakRespiratoryRateLabel: UILabel!
    @IBOutlet weak var peakRespiratoryTitle: UILabel!
    @IBOutlet weak var respiratoryRateTitle: UILabel!
    @IBOutlet weak var RespiratoryImageView: UIImageView!
    @IBOutlet weak var peakBeatsPerTitle: UILabel!
    @IBOutlet weak var beatsPerMinTitle: UILabel!
    @IBOutlet weak var heartRateTitle: UILabel!
    @IBOutlet weak var heartImageView: UIImageView!
    @IBOutlet weak var respiratoryRateContainerView: UIView!
    @IBOutlet weak var containerView: UIView!
 
    var theme: AppTheme!

      override func awakeFromNib() {
          super.awakeFromNib()
          setupUI()
      }

      override func layoutSubviews() {
          super.layoutSubviews()
          containerView.layer.shadowPath = UIBezierPath(
              roundedRect: containerView.bounds,
              cornerRadius: 26
          ).cgPath
      }
     
     
    override func prepareForReuse() {
        super.prepareForReuse()
        beatsPerMinTitle.text = nil
        peakBeatsPerTitle.text = nil
        breathsPerMinLabel.text = nil
        PeakRespiratoryRateLabel.text = nil
        respiratoryRateContainerView.isHidden = true
    }
    
      private func setupUI() {
          backgroundColor = .clear
          contentView.backgroundColor = .clear
          styleStaticCardShape()
          styleStaticLabels()
          styleStaticIcons()
      }

      private func styleStaticCardShape() {
          heartRateContainerView.layer.cornerRadius = 22
          heartRateContainerView.layer.masksToBounds = true
          respiratoryRateContainerView.layer.cornerRadius = 22
          respiratoryRateContainerView.layer.masksToBounds = true
          respiratoryRateContainerView.isHidden = true
      }

      private func styleStaticLabels() {
          peakTitle.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
          heartRateTitle.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
          heartRateTitle.adjustsFontSizeToFitWidth = true
          heartRateTitle.minimumScaleFactor = 0.75
          heartRateTitle.lineBreakMode = .byTruncatingTail
          beatsPerMinTitle.font = UIFont.systemFont(ofSize: 14	, weight: .regular)
          peakRespiratoryTitle.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
          peakRespiratoryTitle.textAlignment = .right
          peakBeatsPerTitle.font = UIFont.systemFont(ofSize: 16, weight: .regular)
          peakBeatsPerTitle.textAlignment = .right
          respiratoryRateTitle.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
          breathsPerMinLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
          PeakRespiratoryRateLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
          PeakRespiratoryRateLabel.textAlignment = .right
          [beatsPerMinTitle, peakBeatsPerTitle, breathsPerMinLabel, PeakRespiratoryRateLabel].forEach {
              $0?.adjustsFontSizeToFitWidth = true
              $0?.minimumScaleFactor = 0.75
              $0?.lineBreakMode = .byTruncatingTail
          }
      }

      private func styleStaticIcons() {
          heartImageView.image = UIImage(systemName: "heart.fill")
          heartImageView.contentMode = .scaleAspectFit
          RespiratoryImageView.image = UIImage(systemName: "waveform.path.ecg")
          RespiratoryImageView.contentMode = .scaleAspectFit
      }

      private func applyTheme() {
          let heartTint = UIColor.systemPink
          let respTint = UIColor.systemPurple
          heartRateContainerView.backgroundColor = heartTint.withAlphaComponent(0.12)
          respiratoryRateContainerView.backgroundColor = respTint.withAlphaComponent(0.12)
          peakTitle.textColor = theme.primaryText
          peakRespiratoryTitle.textColor = theme.primaryText
          heartRateTitle.textColor = heartTint
          beatsPerMinTitle.textColor = heartTint
          peakBeatsPerTitle.textColor = heartTint
          respiratoryRateTitle.textColor = respTint
          breathsPerMinLabel.textColor = respTint
          PeakRespiratoryRateLabel.textColor = respTint
          heartImageView.tintColor = heartTint
          RespiratoryImageView.tintColor = respTint
      }

      func configureCell(avgHeartRate: String,peakHeartRate: String,theme:AppTheme) {
          self.theme = theme
          containerView.backgroundColor = theme.glassMedium
          containerView.layer.borderWidth = 1
          containerView.layer.cornerRadius = 16
          containerView.layer.borderColor = theme.glassBorderLight.cgColor
          peakTitle.text = "Peak"
          heartRateTitle.text = "Heart Rate (Avg)"
          beatsPerMinTitle.text = avgHeartRate
          peakBeatsPerTitle.text = peakHeartRate
          respiratoryRateContainerView.isHidden = true
          peakRespiratoryTitle.text = nil
          respiratoryRateTitle.text = nil
          breathsPerMinLabel.text = nil
          PeakRespiratoryRateLabel.text = nil
          applyTheme()
      }
  }
