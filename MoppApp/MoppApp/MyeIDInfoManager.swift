//
//  MyeIDInfoManager.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2024 Riigi Infosüsteemi Amet
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

import ASN1Decoder

protocol MyeIDInfoManagerDelegate: AnyObject {
    func didCompleteInformationRequest(success:Bool)
    func didTapChangePinPukCode(actionType: MyeIDChangeCodesModel.ActionType)
}

enum LastFocusElement: String {
    case changePIN1
    case changePIN2
    case unblockPIN1
    case unblockPIN2
    case changePUK
}

enum IdCardCodeName: String {
    case PIN1 = "PIN1"
    case PIN2 = "PIN2"
    case PUK = "PUK"
}

enum IdCardCodeLengthLimits:Int {
    case pin1Minimum = 4
    case pin2Minimum = 5
    case pukMinimum = 8
    case maxRetryCount = 3
}

class MyeIDInfoManager {
    weak var delegate: MyeIDInfoManagerDelegate? = nil

    var actionKind: MyeIDChangeCodesModel.ActionType?

    var personalData: MoppLibPersonalData? = nil
    var authCertData: X509Certificate? = nil
    var signCertData: X509Certificate? = nil

    var estonianDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy";
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
            var displayName: String {
                switch self {
                case .pin1: return IdCardCodeName.PIN1.rawValue
                case .pin2: return IdCardCodeName.PIN2.rawValue
                case .puk: return IdCardCodeName.PUK.rawValue
                }
            }
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

    struct RetryCounts {
        var pin1:Int = 0
        var pin2:Int = 0
        var puk:Int = 0
        
        mutating func setRetryCount(for actionType: MyeIDChangeCodesModel.ActionType, with value:Int) {
            switch actionType {
            case .changePin1:
                pin1 = value
            case .changePin2:
                pin2 = value
            case .changePuk, .unblockPin1, .unblockPin2:
                puk = value
            }
        }
    }

    var retryCounts = RetryCounts()
    
    var pin1CertInfoAttributedString: NSAttributedString? = nil
    var pin2CertInfoAttributedString: NSAttributedString? = nil

    var isAuthCertValid:Bool {
        get {
            return Date() < authCertData?.notAfter ?? Date()
        }
    }
    
    var isSignCertValid:Bool {
        get {
            return Date() < signCertData?.notAfter ?? Date()
        }
    }

    func requestInformation(with viewController: UIViewController) {
        let failureClosure = { [weak self] in
            self?.delegate?.didCompleteInformationRequest(success: false)
        }
        
        MoppLibCardActions.minimalCardPersonalData(success: { moppLibPersonalData in
            MoppLibCardActions.authenticationCertificate(success: { moppLibAuthCertData in
                MoppLibCardActions.signingCertificate(success: { [weak self] moppLibSignCertData in
                    self?.requestRetryCounts(with: viewController, success: { [weak self] (pin1RetryCount, pin2RetryCount, pukRetryCount) in
                        guard let strongSelf = self else { return }
                        strongSelf.personalData = moppLibPersonalData
                        strongSelf.authCertData = try? X509Certificate(der: moppLibAuthCertData ?? Data())
                        strongSelf.signCertData = try? X509Certificate(der: moppLibSignCertData ?? Data())
                        strongSelf.retryCounts.pin1 = pin1RetryCount
                        strongSelf.retryCounts.pin2 = pin2RetryCount
                        strongSelf.retryCounts.puk  = pukRetryCount
                        strongSelf.setup()
                        strongSelf.createCertInfoAttributedString(kind: .pin1)
                        strongSelf.createCertInfoAttributedString(kind: .pin2)
                        self?.delegate?.didCompleteInformationRequest(success: true)
                    }, failure: {_ in failureClosure() })
                }, failure: {_ in failureClosure() })
            }, failure: {_ in failureClosure() })
        }, failure: {_ in failureClosure() })
    }
    
    func requestRetryCounts(with viewController: UIViewController, success:@escaping (_ pin1RetryCount:Int, _ pin2RetryCount:Int, _ pukRetryCount:Int)->Void, failure:@escaping (Error?)->Void) {
        var pin1RetryCount:Int = 0
        var pin2RetryCount:Int = 0
        var pukRetryCount:Int = 0
        MoppLibCardActions.pin1RetryCount(success: { number in
            pin1RetryCount = number?.intValue ?? 0
            MoppLibCardActions.pin2RetryCount(success: { number in
                pin2RetryCount = number?.intValue ?? 0
                MoppLibCardActions.pukRetryCount(success: { number in
                    pukRetryCount = number?.intValue ?? 0
                    success(pin1RetryCount, pin2RetryCount, pukRetryCount)
                }, failure: failure)
            }, failure: failure)
        }, failure: failure)
    }
    
    func setup() {
        personalInfo.items.removeAll()
        guard let personalData = personalData else { return }
        personalInfo.items.append((type: .myeID, value: organizationDisplayString(authCertData?.certType())))
        personalInfo.items.append((type: .givenNames, value: personalData.givenNames()))
        personalInfo.items.append((type: .surname, value: personalData.surname))
        personalInfo.items.append((type: .personalCode, value: personalData.personalIdentificationCode))
        personalInfo.items.append((type: .citizenship, value: personalData.nationality))
        personalInfo.items.append((type: .documentNumber, value: personalData.documentNumber))
        personalInfo.items.append((type: .expiryDate, value: personalData.expiryDate))
        
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: "")
    }
    
    func organizationDisplayString(_ certOrganization: X509Certificate.CertType?) -> String {
        switch certOrganization {
        case .IDCardType:
            return L(.myEidInfoMyEidIdCard)
        case .DigiIDType, .EResidentType:
            return L(.myEidInfoMyEidDigiId)
        case .MobileIDType:
            return L(.myEidInfoMyEidMobileId)
        case .SmartIDType:
            return L(.myEidInfoMyEidSmartId)
        case .UnknownType:
            return L(.myEidInfoMyEidUnknown)
        default:
            return ""
        }
    }
    
    func expiryDateAttributedString(dateString: String, capitalized: Bool) -> NSAttributedString? {
        let isValid = Date() < estonianDateFormatter.date(from: dateString) ?? Date()
        return expiryDateAttributedString(isValid: isValid, capitalized: capitalized)
    }
    
    func expiryDateAttributedString(isValid: Bool, capitalized: Bool) -> NSAttributedString {
        let attrText = NSMutableAttributedString()
    
        if isValid {
            let certValidText = capitalized ? L(.myEidCertValid).capitalized : L(.myEidCertValid)
            let validText = NSAttributedString(string: certValidText, attributes:
                [.foregroundColor : UIColor.moppGreen700])
            attrText.append(validText)
        } else {
            let certExpiredText = capitalized ? L(.myEidCertExpired).capitalized : L(.myEidCertExpired)
            let expiredText = NSAttributedString(string: certExpiredText, attributes:
                [.foregroundColor : UIColor.moppError])
            attrText.append(expiredText)
        }
        
        return attrText
    }
    
    func certInfoAttributedString(for kind: PinPukCell.Kind) -> NSAttributedString? {
        if kind == .pin1 {
            return pin1CertInfoAttributedString
        }
        else if kind == .pin2 {
            return pin2CertInfoAttributedString
        }
        
        return nil
    }
    
    func createCertInfoAttributedString(kind: PinPukCell.Kind) {
        var certExpiryDate: Date? = nil
        var isCertValid = false
        if kind == .pin1 {
            certExpiryDate = authCertData?.notAfter
            isCertValid = isAuthCertValid
        }
        else if kind == .pin2 {
            certExpiryDate = signCertData?.notAfter
            isCertValid = isSignCertValid
        }
    
        let statusAttributedString = self.expiryDateAttributedString(isValid: isCertValid, capitalized: false)
        
        var expiryDateAttributedString: NSAttributedString!
        if let expiryDate = certExpiryDate {
            let expiryDateString = estonianDateFormatter.string(from: expiryDate)
            expiryDateAttributedString = NSAttributedString(string: expiryDateString, attributes: [:])
        }
        
        let certInfoString = NSMutableAttributedString()
        if isCertValid {
            certInfoString.append(NSAttributedString(
                string: L(.myEidCertInfoValid),
                attributes: [.foregroundColor: UIColor.moppLabelDarker]
                ))
            certInfoString.replaceOccurrences(of: "[VALID_EXPIRY_STATUS]", with: statusAttributedString)
            if expiryDateAttributedString != nil {
                certInfoString.replaceOccurrences(of: "[EXPIRY_DATE]", with: expiryDateAttributedString)
            }
        } else {
            certInfoString.append(NSAttributedString(
                string: L(.myEidCertInfoExpired),
                attributes: [:]
                ))
            certInfoString.replaceOccurrences(of: "[EXPIRED_EXPIRY_STATUS]", with: statusAttributedString)
            certInfoString.replaceOccurrences(of: "[PIN]", with: NSAttributedString(string: kind.displayName, attributes: [:]))
        }
        
        if kind == .pin1 {
            pin1CertInfoAttributedString = certInfoString
        }
        else if kind == .pin2 {
            pin2CertInfoAttributedString = certInfoString
        }
    }
}

class MyeIDChangeCodesModel {
    enum ActionType {
        case changePin1
        case unblockPin1
        case changePin2
        case unblockPin2
        case changePuk
        
        var codeDisplayName: String {
            switch self {
            case .changePin1, .unblockPin1:
                return IdCardCodeName.PIN1.rawValue
            case .changePin2, .unblockPin2:
                return IdCardCodeName.PIN2.rawValue
            case .changePuk:
                return IdCardCodeName.PUK.rawValue
            }
        }
        
        var codeDisplayNameForWrongOrBlocked: String {
            switch self {
            case .changePin1:
                return IdCardCodeName.PIN1.rawValue
            case .changePin2:
                return IdCardCodeName.PIN2.rawValue
            case .changePuk, .unblockPin1, .unblockPin2:
                return IdCardCodeName.PUK.rawValue
            }
        }
    }
    var actionType: ActionType = .changePin1
    var titleText = String()
    var infoBullets = [String]()
    var firstTextFieldLabelText = String()
    var secondTextFieldLabelText = String()
    var thirdTextFieldLabelText = String()
    var discardButtonTitleText = String()
    var confirmButtonTitleText = String()
}


extension MyeIDInfoManager {
    class func createChangeCodesModel(actionType: MyeIDChangeCodesModel.ActionType) -> MyeIDChangeCodesModel {
        let model = MyeIDChangeCodesModel()
            model.actionType = actionType
        
        switch actionType {
        case .changePin1:
        
            model.titleText = L(.myEidChangeCodeTitle, [IdCardCodeName.PIN1.rawValue])
            model.infoBullets.append(L(.myEidInfoBulletSameCodesWarning, [IdCardCodeName.PIN1.rawValue]))
            model.infoBullets.append(L(.myEidInfoBulletAuthCertInfo))
            model.infoBullets.append(L(.myEidInfoBulletPin1BlockedWarning))
            
            model.firstTextFieldLabelText = L(.myEidCurrentCodeLabel, [IdCardCodeName.PIN1.rawValue])
            model.secondTextFieldLabelText = L(.myEidNewCodeLabel, [IdCardCodeName.PIN1.rawValue, 4])
            model.thirdTextFieldLabelText = L(.myEidNewCodeAgainLabel, [IdCardCodeName.PIN1.rawValue])
            
            model.discardButtonTitleText = L(.myEidDiscardButtonTitle)
            model.confirmButtonTitleText = L(.myEidConfirmChangeButtonTitle)
            
        case .unblockPin1:
        
            model.titleText = L(.myEidUnblockCodeTitle, [IdCardCodeName.PIN1.rawValue])
            model.infoBullets.append(L(.myEidInfoBulletSameCodesWarning, [IdCardCodeName.PIN1.rawValue]))
            model.infoBullets.append(L(.myEidInfoBulletAuthCertInfo))
            model.infoBullets.append(L(.myEidInfoBulletForgotCodeNote, [IdCardCodeName.PIN1.rawValue]))
            model.infoBullets.append(L(.myEidInfoBulletPukEnvelopeInfo))
            
            model.firstTextFieldLabelText = L(.myEidCurrentCodeLabel, [IdCardCodeName.PUK.rawValue])
            model.secondTextFieldLabelText = L(.myEidNewCodeLabel, [IdCardCodeName.PIN1.rawValue, 4])
            model.thirdTextFieldLabelText = L(.myEidNewCodeAgainLabel, [IdCardCodeName.PIN1.rawValue])
            
            model.discardButtonTitleText = L(.myEidDiscardButtonTitle)
            model.confirmButtonTitleText = L(.myEidConfirmUnblockButtonTitle)
            
        case .changePin2:
        
            model.titleText = L(.myEidChangeCodeTitle, [IdCardCodeName.PIN2.rawValue])
            model.infoBullets.append(L(.myEidInfoBulletSameCodesWarning, [IdCardCodeName.PIN2.rawValue]))
            model.infoBullets.append(L(.myEidInfoBulletSignCertInfo))
            model.infoBullets.append(L(.myEidInfoBulletPin2BlockedWarning))
            
            model.firstTextFieldLabelText = L(.myEidCurrentCodeLabel, [IdCardCodeName.PIN2.rawValue])
            model.secondTextFieldLabelText = L(.myEidNewCodeLabel, [IdCardCodeName.PIN2.rawValue, 5])
            model.thirdTextFieldLabelText = L(.myEidNewCodeAgainLabel, [IdCardCodeName.PIN2.rawValue])
            
            model.discardButtonTitleText = L(.myEidDiscardButtonTitle)
            model.confirmButtonTitleText = L(.myEidConfirmChangeButtonTitle)
            
        case .unblockPin2:
        
            model.titleText = L(.myEidUnblockCodeTitle, [IdCardCodeName.PIN2.rawValue])
            model.infoBullets.append(L(.myEidInfoBulletSameCodesWarning, [IdCardCodeName.PIN2.rawValue]))
            model.infoBullets.append(L(.myEidInfoBulletSignCertInfo))
            model.infoBullets.append(L(.myEidInfoBulletForgotCodeNote, [IdCardCodeName.PIN2.rawValue]))
            model.infoBullets.append(L(.myEidInfoBulletPukEnvelopeInfo))
            
            model.firstTextFieldLabelText = L(.myEidCurrentCodeLabel, [IdCardCodeName.PUK.rawValue])
            model.secondTextFieldLabelText = L(.myEidNewCodeLabel, [IdCardCodeName.PIN2.rawValue, 5])
            model.thirdTextFieldLabelText = L(.myEidNewCodeAgainLabel, [IdCardCodeName.PIN2.rawValue])
            
            model.discardButtonTitleText = L(.myEidDiscardButtonTitle)
            model.confirmButtonTitleText = L(.myEidConfirmUnblockButtonTitle)
            
        case .changePuk:
        
            model.titleText = L(.myEidChangeCodeTitle, [IdCardCodeName.PUK.rawValue])
            model.infoBullets.append(L(.myEidInfoBulletPukUnblockInfo))
            model.infoBullets.append(L(.myEidInfoBulletPukBlockedWarning))
            
            model.firstTextFieldLabelText = L(.myEidCurrentCodeLabel, [IdCardCodeName.PUK.rawValue])
            model.secondTextFieldLabelText = L(.myEidNewCodeLabel, [IdCardCodeName.PUK.rawValue, 8])
            model.thirdTextFieldLabelText = L(.myEidNewCodeAgainLabel, [IdCardCodeName.PUK.rawValue])
            
            model.discardButtonTitleText = L(.myEidDiscardButtonTitle)
            model.confirmButtonTitleText = L(.myEidConfirmChangeButtonTitle)
            
        }
        return model
    }
    
    func isNewCodeBirthdateVariant(_ newCodeValue:String) -> Bool? {
        guard let birthDateString = personalData?.birthDate,
            let birthDate = estonianDateFormatter.date(from: birthDateString) else {
            return nil
        }
    
        let dateComponents = Calendar.current.dateComponents([.year,.month,.day], from: birthDate)
    
        guard let year = dateComponents.year else {
            return nil
        }
    
        guard let month = dateComponents.month else {
            return nil
        }
        
        guard let day = dateComponents.day else {
            return nil
        }
    
        let birthYear = String(year)
        let birthMonth = String(format: "%.2i", month)
        let birthDay = String(format: "%.2i", day)
    
        return newCodeValue == birthYear || newCodeValue == (birthMonth + birthDay) || newCodeValue == (birthDay + birthMonth)
    }
}
