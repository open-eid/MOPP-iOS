//
//  SignatureWarningsCell.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2023 Riigi Infosüsteemi Amet
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

import Foundation

class SignatureWarningsCell: UITableViewCell {
    
    var onTechnicalInformationButtonTapped: (() -> Void)?
    
    @IBOutlet weak var warningsHeader: ScaledLabel!
    @IBOutlet weak var warningsDescription: ScaledTextView!
    @IBOutlet weak var technicalInformationButton: ScaledButton!
    @IBOutlet weak var warningsDetails: ScaledLabel!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var detailsStackView: UIStackView!
    
    var isDetailsHidden = true
    
    @IBAction func toggleTechnicalInformationInfo(_ sender: ScaledButton) {
        updateTechnicalInformationView()
    }
    
    var technicalInformation: WarningDetail?
    
    func populate(signatureStatus: MoppLibSignatureStatus?, warningDetail: WarningDetail) {
        technicalInformation = warningDetail
        warningsHeader.text = warningDetail.warningHeader
        warningsDescription.text = warningDetail.warningDescription
        
        warningsDescription.textContainerInset = .zero
        warningsDescription.textContainer.lineFragmentPadding = 0
        
        warningsHeader.accessibilityLabel = warningDetail.warningHeader
        warningsDescription.accessibilityLabel = warningDetail.warningDescription
        
        if let _ = warningDetail.warningDetails {
            setWarningDetails()
            detailsStackView.isHidden = false
            technicalInformationButton.setTitle(L(.containerSignatureTechnicalInformationButton))
            if isDetailsHidden {
                setTechnicalInformation()
                detailsStackView.isHidden = false
                warningsDetails.isHidden = true
                iconView.image = UIImage(named: "Accordion_arrow_right")
            }
            
            let tapGR = UITapGestureRecognizer()
            tapGR.addTarget(self, action: #selector(updateTechnicalInformationView))
            detailsStackView.addGestureRecognizer(tapGR)
        } else {
            detailsStackView.isHidden = true
            warningsDetails.isHidden = true
        }
        
        if let status = signatureStatus {
            if status == .Warning || status == .NonQSCD {
                warningsHeader.textColor = UIColor.moppWarningText
            } else if status == .UnknownStatus || status == .Invalid {
                warningsHeader.textColor = UIColor.moppError
            }
        }
    }
    
    func setWarningDetails() {
        if let warnDetails = technicalInformation?.warningDetails {
            warningsDetails.text = warnDetails
            warningsDetails.accessibilityLabel = warnDetails
            warningsDetails.isAccessibilityElement = true
            warningsDetails.accessibilityUserInputLabels = [""]
        }
    }
    
    @objc func updateTechnicalInformationView() {
        setTechnicalInformation()
        self.contentView.layoutIfNeeded()
        onTechnicalInformationButtonTapped?()
    }
    
    func setTechnicalInformation() {
        setWarningDetails()
        technicalInformationButton.setTitle(L(.containerSignatureTechnicalInformationButton))
        if warningsDetails.isHidden {
            iconView.image = UIImage(named: "Accordion_arrow_down")
            warningsDetails.isHidden = false
            isDetailsHidden = false
            warningsDetails.isAccessibilityElement = true
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .screenChanged, argument: warningsDetails)
            }
        } else {
            iconView.image = UIImage(named: "Accordion_arrow_right")
            warningsDetails.isHidden = true
            isDetailsHidden = true
        }
    }
}
