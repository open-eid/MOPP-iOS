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

    enum PersonalInfo {
        case myeID
        case givenNames
        case surname
        case personalCode
        case citizenship
        case documentNumber
        case expiryDate

        var itemTitle: String {
            switch self {
            case .myeID:         L(.myEidInfoMyEid)
            case .givenNames:    L(.myEidInfoItemGivenNames)
            case .surname:       L(.myEidInfoItemSurname)
            case .personalCode:  L(.myEidInfoItemPersonalCode)
            case .citizenship:   L(.myEidInfoItemCitizenship)
            case .documentNumber: L(.myEidInfoItemDocumentNumber)
            case .expiryDate:    L(.myEidInfoItemExpiryDate)
            }
        }
    }

    var personalInfo = [(type: PersonalInfo, value: String)]()

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
    var canChangePUK = true
    var pin2Active = true

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

        mutating func resetRetryCount(for actionType: MyeIDChangeCodesModel.ActionType) {
            setRetryCount(for: actionType, with: IdCardCodeLengthLimits.maxRetryCount.rawValue)
            switch actionType {
            case .unblockPin1:
                pin1 = IdCardCodeLengthLimits.maxRetryCount.rawValue
            case .unblockPin2:
                pin2 = IdCardCodeLengthLimits.maxRetryCount.rawValue
            default: break
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

    func requestInformation(_ cardCommands: CardCommands) {
        Task.detached { [weak self] in
            do {
                let personalData = try await cardCommands.readPublicData()
                let authCertData = try await cardCommands.readAuthenticationCertificate()
                let signCertData = try await cardCommands.readSignatureCertificate()
                let (pin1RetryCount, _) = try await cardCommands.readCodeCounterRecord(.pin1)
                let (pin2RetryCount, pin2Active) = try await cardCommands.readCodeCounterRecord(.pin2)
                let (pukRetryCount, _) = try await cardCommands.readCodeCounterRecord(.puk)

                guard let self else { return }

                self.canChangePUK = cardCommands.canChangePUK
                self.personalData = personalData
                self.authCertData = try? X509Certificate(der: authCertData)
                self.signCertData = try? X509Certificate(der: signCertData)
                self.retryCounts.pin1 = Int(pin1RetryCount)
                self.retryCounts.pin2 = Int(pin2RetryCount)
                self.retryCounts.puk  = Int(pukRetryCount)
                self.pin2Active = pin2Active
                self.personalInfo = [
                    (type: .myeID, value: self.authCertData?.certType().organizationDisplayString ?? .init()),
                    (type: .givenNames, value: personalData.givenNames),
                    (type: .surname, value: personalData.surname),
                    (type: .personalCode, value: personalData.personalIdentificationCode),
                    (type: .citizenship, value: personalData.nationality),
                    (type: .documentNumber, value: personalData.documentNumber),
                    (type: .expiryDate, value: personalData.expiryDate)
                ]

                await MainActor.run {
                    UIAccessibility.post(notification: .screenChanged, argument: "")
                    self.createCertInfoAttributedString(kind: .pin1)
                    self.createCertInfoAttributedString(kind: .pin2)
                    self.delegate?.didCompleteInformationRequest(success: true)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.delegate?.didCompleteInformationRequest(success: false)
                }
            }
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
    let actionType: ActionType
    let cardCommands: CardCommands
    let titleText: String
    let infoBullets: [String]
    let firstTextFieldLabelText: String?
    let secondTextFieldLabelText: String?
    let thirdTextFieldLabelText: String?
    let confirmButtonTitleText: String?
    let discardButtonTitleText = L(.myEidDiscardButtonTitle)

    init(actionType: MyeIDChangeCodesModel.ActionType, cardCommands: CardCommands) {
        self.actionType = actionType
        self.cardCommands = cardCommands
        switch actionType {
        case .changePin1:
            titleText = L(.myEidChangeCodeTitle, [actionType.codeDisplayName])
            infoBullets = [
                L(.myEidInfoBulletSameCodesWarning, [actionType.codeDisplayName]),
                L(.myEidInfoBulletAuthCertInfo),
                L(.myEidInfoBulletPin1BlockedWarning)
            ]
            firstTextFieldLabelText = L(.myEidCurrentCodeLabel, [actionType.codeDisplayName])
            secondTextFieldLabelText = L(.myEidNewCodeLabel, [actionType.codeDisplayName, 4])
            thirdTextFieldLabelText = L(.myEidNewCodeAgainLabel, [actionType.codeDisplayName])
            confirmButtonTitleText = L(.myEidConfirmChangeButtonTitle)
        case .unblockPin1:
            titleText = L(.myEidUnblockCodeTitle, [actionType.codeDisplayName])
            infoBullets = [
                L(.myEidInfoBulletSameCodesWarning, [actionType.codeDisplayName]),
                L(.myEidInfoBulletAuthCertInfo),
                L(.myEidInfoBulletForgotCodeNote, [actionType.codeDisplayName]),
                L(.myEidInfoBulletPukEnvelopeInfo)
            ]
            firstTextFieldLabelText = L(.myEidCurrentCodeLabel, [IdCardCodeName.PUK.rawValue])
            secondTextFieldLabelText = L(.myEidNewCodeLabel, [actionType.codeDisplayName, 4])
            thirdTextFieldLabelText = L(.myEidNewCodeAgainLabel, [actionType.codeDisplayName])
            confirmButtonTitleText = L(.myEidConfirmUnblockButtonTitle)
        case .changePin2:
            titleText = L(.myEidChangeCodeTitle, [actionType.codeDisplayName])
            infoBullets = [
                L(.myEidInfoBulletSameCodesWarning, [actionType.codeDisplayName]),
                L(.myEidInfoBulletSignCertInfo),
                L(.myEidInfoBulletPin2BlockedWarning)
            ]
            firstTextFieldLabelText = L(.myEidCurrentCodeLabel, [actionType.codeDisplayName])
            secondTextFieldLabelText = L(.myEidNewCodeLabel, [actionType.codeDisplayName, 5])
            thirdTextFieldLabelText = L(.myEidNewCodeAgainLabel, [actionType.codeDisplayName])
            confirmButtonTitleText = L(.myEidConfirmChangeButtonTitle)
        case .unblockPin2:
            titleText = L(.myEidUnblockCodeTitle, [actionType.codeDisplayName])
            infoBullets = [
                L(.myEidInfoBulletSameCodesWarning, [actionType.codeDisplayName]),
                L(.myEidInfoBulletSignCertInfo),
                L(.myEidInfoBulletForgotCodeNote, [actionType.codeDisplayName]),
                L(.myEidInfoBulletPukEnvelopeInfo)
            ]
            firstTextFieldLabelText = L(.myEidCurrentCodeLabel, [IdCardCodeName.PUK.rawValue])
            secondTextFieldLabelText = L(.myEidNewCodeLabel, [actionType.codeDisplayName, 5])
            thirdTextFieldLabelText = L(.myEidNewCodeAgainLabel, [actionType.codeDisplayName])
            confirmButtonTitleText = L(.myEidConfirmUnblockButtonTitle)
        case .changePuk:
            titleText = L(.myEidChangeCodeTitle, [actionType.codeDisplayName])
            infoBullets = [
                L(.myEidInfoBulletPukUnblockInfo),
                L(.myEidInfoBulletPukBlockedWarning)
            ]
            firstTextFieldLabelText = cardCommands.canChangePUK ? L(.myEidCurrentCodeLabel, [actionType.codeDisplayName]) : nil
            secondTextFieldLabelText = cardCommands.canChangePUK ? L(.myEidNewCodeLabel, [actionType.codeDisplayName, 8]) : nil
            thirdTextFieldLabelText = cardCommands.canChangePUK ? L(.myEidNewCodeAgainLabel, [actionType.codeDisplayName]) : nil
            confirmButtonTitleText = cardCommands.canChangePUK ? L(.myEidConfirmChangeButtonTitle) : nil
        }
    }
}

extension MyeIDInfoManager {
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

extension CertType {
    var organizationDisplayString: String {
        switch self {
        case .IDCardType:
            return L(.myEidInfoMyEidIdCard)
        case .DigiIDType:
            return L(.myEidInfoMyEidDigiId)
        case .EResidentType:
            return L(.myEidInfoMyEidEResident)
        case .MobileIDType:
            return L(.myEidInfoMyEidMobileId)
        case .SmartIDType:
            return L(.myEidInfoMyEidSmartId)
        case .UnknownType:
            return L(.myEidInfoMyEidUnknown)
        default:
            return .init()
        }
    }
}
