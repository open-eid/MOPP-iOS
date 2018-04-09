//
//  MyeIDInfoManager.swift
//  MoppApp
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
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
protocol MyeIDInfoManagerDelegate: class {
    func didCompleteInformationRequest(success:Bool)
    func didTapChangePinPukCode(kind: MyeIDInfoManager.PinPukCell.Kind)
}

class MyeIDInfoManager {
    public static var shared = MyeIDInfoManager()

    weak var delegate: MyeIDInfoManagerDelegate? = nil

    var personalData: MoppLibPersonalData? = nil
    var authCertData: MoppLibCertData? = nil
    var signCertData: MoppLibCertData? = nil

    var expiryDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"; // Estonian date format
        return dateFormatter
    }()

    struct PersonalInfo {
        enum ItemType {
            case myeID
            case givenNames
            case surname
            case personalCode
            case citizenship
            case documentNumber
            case expiryDate
        }
        
        var itemTitles: [ItemType: String] = [
            .myeID:         L(.myEidInfoMyEid),
            .givenNames:    L(.myEidInfoItemGivenNames),
            .surname:       L(.myEidInfoItemSurname),
            .personalCode:  L(.myEidInfoItemPersonalCode),
            .citizenship:   L(.myEidInfoItemCitizenship),
            .documentNumber: L(.myEidInfoItemDocumentNumber),
            .expiryDate:    L(.myEidInfoItemExpiryDate)
        ]
        
        var items: [(type: ItemType, value: String)] = []
    }

    var personalInfo = PersonalInfo()

    struct PinPukCell {
        enum Kind {
            case pin1, pin2, puk
        }
        struct Info {
            init(kind: Kind, title: String, linkText: String, buttonText: String, certInfoText: String?) {
                self.kind = kind
                self.title = title
                self.certInfoText = certInfoText
                self.linkText = linkText
                self.buttonText = buttonText
            }
            var kind: Kind!
            var title: String!
            var certInfoText: String?
            var linkText: String!
            var buttonText: String!
        }
        var items:[Info] = [
            Info(
                kind: .pin1,
                title: L(.myEidInfoPin1Title) ,
                linkText: L(.myEidInfoPin1LinkText),
                buttonText: L(.myEidInfoPin1ButtonTitle),
                certInfoText: nil
                ),
            Info(
                kind: .pin2,
                title: L(.myEidInfoPin2Title),
                linkText: L(.myEidInfoPin2LinkText),
                buttonText: L(.myEidInfoPin2ButtonTitle),
                certInfoText: nil
                ),
            Info(
                kind: .puk,
                title: L(.myEidInfoPukTitle),
                linkText: L(.myEidInfoPukLinkText),
                buttonText: L(.myEidInfoPukButtonTitle),
                certInfoText: L(.myEidInfoPukCertInfoText)
                )
        ]
    }
    
    var pinPukCell = PinPukCell()

    func requestInformation(with viewController: UIViewController) {
        let failureClosure = { [weak self] in
            self?.delegate?.didCompleteInformationRequest(success: false)
        }
        MoppLibCardActions.minimalCardPersonalData(with: viewController, success: { moppLibPersonalData in
            MoppLibCardActions.authenticationCert(with: viewController, success: { moppLibAuthCertData in
                MoppLibCardActions.signingCert(with: viewController, success: { [weak self] moppLibSignCertData in
                    guard let strongSelf = self else { return }
                    strongSelf.personalData = moppLibPersonalData
                    strongSelf.authCertData = moppLibAuthCertData
                    strongSelf.signCertData = moppLibSignCertData
                    strongSelf.setup()
                    self?.delegate?.didCompleteInformationRequest(success: true)
                }, failure: {_ in failureClosure() })
            }, failure: {_ in failureClosure() })
        }, failure: {_ in failureClosure() })
    }
    
    func setup() {
        personalInfo.items.removeAll()
        guard let personalData = personalData else { return }
        let certOrganization = authCertData?.organization ?? MoppLibCertOrganization.Unknown
        personalInfo.items.append((type: .myeID, value: organizationDisplayString(certOrganization)))
        personalInfo.items.append((type: .givenNames, value: personalData.givenNames()))
        personalInfo.items.append((type: .surname, value: personalData.surname))
        personalInfo.items.append((type: .personalCode, value: personalData.personalIdentificationCode))
        personalInfo.items.append((type: .citizenship, value: personalData.nationality))
        personalInfo.items.append((type: .documentNumber, value: personalData.documentNumber))
        personalInfo.items.append((type: .expiryDate, value: personalData.expiryDate))
    }
    
    func organizationDisplayString(_ certOrganization: MoppLibCertOrganization) -> String {
        switch certOrganization {
        case .IDCard:
            return L(.myEidInfoMyEidIdCard)
        case .DigiID, .EResident:
            return L(.myEidInfoMyEidDigiId)
        case .MobileID:
            return L(.myEidInfoMyEidMobileId)
        case .Unknown:
            return L(.myEidInfoMyEidUnknown)
        }
    }
    
    func expiryDateAttributedString(dateString: String, font: UIFont, capitalized: Bool, valid: inout Bool) -> NSAttributedString? {
        return expiryDateAttributedString(date: expiryDateFormatter.date(from: dateString), font: font, capitalized: capitalized, valid: &valid)
    }
    
    func expiryDateAttributedString(date: Date?, font: UIFont, capitalized: Bool, valid: inout Bool) -> NSAttributedString? {
        if let expiryDate = date {
            let attrText = NSMutableAttributedString()
        
            valid = expiryDate >= Date()
        
            if valid {
                let certValidText = capitalized ? L(.myEidCertValid).capitalized : L(.myEidCertValid)
                let validText = NSAttributedString(string: certValidText, attributes:
                    [.foregroundColor : UIColor.moppSuccess,
                     .font : font])
                attrText.append(validText)
            } else {
                let certExpiredText = capitalized ? L(.myEidCertExpired).capitalized : L(.myEidCertExpired)
                let expiredText = NSAttributedString(string: certExpiredText, attributes:
                    [.foregroundColor : UIColor.moppError,
                     .font : font])
                attrText.append(expiredText)
            }
            
            return attrText
        }

        return nil
    }
}
