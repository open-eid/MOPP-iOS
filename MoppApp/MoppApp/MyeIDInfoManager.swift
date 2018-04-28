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
    func didTapChangePinPukCode(actionType: MyeIDChangeCodesModel.ActionType)
}

enum IdCardCodeName: String {
    case pin1 = "PIN1"
    case pin2 = "PIN2"
    case puk = "PUK"
}

enum IdCardCodeLengthLimits:Int {
    case pin1Minimum = 4
    case pin2Minimum = 5
    case pukMinimum = 8
    case maxRetryCount = 3
}

class MyeIDInfoManager {
    public static var shared = MyeIDInfoManager()

    weak var delegate: MyeIDInfoManagerDelegate? = nil

    var personalData: MoppLibPersonalData? = nil
    var authCertData: MoppLibCertData? = nil
    var signCertData: MoppLibCertData? = nil

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
            return Date() < authCertData?.expiryDate ?? Date()
        }
    }
    
    var isSignCertValid:Bool {
        get {
            return Date() < signCertData?.expiryDate ?? Date()
        }
    }

    func requestInformation(with viewController: UIViewController) {
        let failureClosure = { [weak self] in
            self?.delegate?.didCompleteInformationRequest(success: false)
        }
        
        MoppLibCardActions.minimalCardPersonalData(with: viewController, success: { moppLibPersonalData in
            MoppLibCardActions.authenticationCert(with: viewController, success: { moppLibAuthCertData in
                MoppLibCardActions.signingCert(with: viewController, success: { [weak self] moppLibSignCertData in
                    self?.requestRetryCounts(with: viewController, success: { [weak self] (pin1RetryCount, pin2RetryCount, pukRetryCount) in
                        guard let strongSelf = self else { return }
                        strongSelf.personalData = moppLibPersonalData
                        strongSelf.authCertData = moppLibAuthCertData
                        strongSelf.signCertData = moppLibSignCertData
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
        MoppLibCardActions.pin1RetryCount(with: viewController, success: { number in
            pin1RetryCount = number?.intValue ?? 0
            MoppLibCardActions.pin2RetryCount(with: viewController, success: { number in
                pin2RetryCount = number?.intValue ?? 0
                MoppLibCardActions.pukRetryCount(with: viewController, success: { number in
                    pukRetryCount = number?.intValue ?? 0
                    success(pin1RetryCount, pin2RetryCount, pukRetryCount)
                }, failure: failure)
            }, failure: failure)
        }, failure: failure)
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
    
    func expiryDateAttributedString(dateString: String, font: UIFont, capitalized: Bool) -> NSAttributedString? {
        let isValid = Date() < estonianDateFormatter.date(from: dateString) ?? Date()
        return expiryDateAttributedString(isValid: isValid, font: font, capitalized: capitalized)
    }
    
    func expiryDateAttributedString(isValid:Bool, font: UIFont, capitalized: Bool) -> NSAttributedString {
        let attrText = NSMutableAttributedString()
    
        if isValid {
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
            certExpiryDate = MyeIDInfoManager.shared.authCertData?.expiryDate
            isCertValid = MyeIDInfoManager.shared.isAuthCertValid
        }
        else if kind == .pin2 {
            certExpiryDate = MyeIDInfoManager.shared.signCertData?.expiryDate
            isCertValid = MyeIDInfoManager.shared.isSignCertValid
        }
    
        let font = UIFont(name: MoppFontName.regular.rawValue, size: 16)!
    
        let certInfoString = NSMutableAttributedString()
        certInfoString.append(NSAttributedString(
            string: L(.myEidCertInfoPrefix),
            attributes: [.font: font]
            ))

        certInfoString.append(MyeIDInfoManager.shared.expiryDateAttributedString(isValid:isCertValid, font: font, capitalized: false))
    
        if isCertValid {
            if let expiryDate = certExpiryDate {
                certInfoString.append(NSAttributedString(string: L(.myEidCertInfoValidSuffix), attributes:[.font: font]))
                let dateString = MyeIDInfoManager.shared.estonianDateFormatter.string(from: expiryDate)
                certInfoString.append(NSAttributedString(string: dateString, attributes:[.font: font]))
            }
        } else {
            if let expiryDate = certExpiryDate {
                certInfoString.append(NSAttributedString(string: L(.myEidCertInfoExpiredSuffix), attributes:[.font: font]))
                let dateString = MyeIDInfoManager.shared.estonianDateFormatter.string(from: expiryDate)
                certInfoString.append(NSAttributedString(string: dateString, attributes:[.font: font]))
            }
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
                return "PIN1"
            case .changePin2, .unblockPin2:
                return "PIN2"
            case .changePuk:
                return "PUK"
            }
        }
        
        var codeDisplayNameForWrongOrBlocked: String {
            switch self {
            case .changePin1:
                return "PIN1"
            case .changePin2:
                return "PIN2"
            case .changePuk, .unblockPin1, .unblockPin2:
                return "PUK"
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
        
            model.titleText = L(.myEidChangeCodeTitle, ["PIN1"])
            model.infoBullets.append(L(.myEidInfoBulletSameCodesWarning, ["PIN1"]))
            model.infoBullets.append(L(.myEidInfoBulletAuthCertInfo))
            model.infoBullets.append(L(.myEidInfoBulletPin1BlockedWarning))
            
            model.firstTextFieldLabelText = L(.myEidCurrentCodeLabel, ["PIN1"])
            model.secondTextFieldLabelText = L(.myEidNewCodeLabel, ["PIN1", 4])
            model.thirdTextFieldLabelText = L(.myEidNewCodeAgainLabel, ["PIN1"])
            
            model.discardButtonTitleText = L(.myEidDiscardButtonTitle)
            model.confirmButtonTitleText = L(.myEidConfirmChangeButtonTitle)
            
        case .unblockPin1:
        
            model.titleText = L(.myEidUnblockCodeTitle, ["PIN1"])
            model.infoBullets.append(L(.myEidInfoBulletSameCodesWarning, ["PIN1"]))
            model.infoBullets.append(L(.myEidInfoBulletAuthCertInfo))
            model.infoBullets.append(L(.myEidInfoBulletForgotCodeNote, ["PIN1", "PIN1"]))
            model.infoBullets.append(L(.myEidInfoBulletPukEnvelopeInfo))
            
            model.firstTextFieldLabelText = L(.myEidCurrentCodeLabel, ["PUK"])
            model.secondTextFieldLabelText = L(.myEidNewCodeLabel, ["PIN1", 4])
            model.thirdTextFieldLabelText = L(.myEidNewCodeAgainLabel, ["PIN1"])
            
            model.discardButtonTitleText = L(.myEidDiscardButtonTitle)
            model.confirmButtonTitleText = L(.myEidConfirmUnblockButtonTitle)
            
        case .changePin2:
        
            model.titleText = L(.myEidChangeCodeTitle, ["PIN2"])
            model.infoBullets.append(L(.myEidInfoBulletSameCodesWarning, ["PIN2"]))
            model.infoBullets.append(L(.myEidInfoBulletSignCertInfo))
            model.infoBullets.append(L(.myEidInfoBulletPin2BlockedWarning))
            
            model.firstTextFieldLabelText = L(.myEidCurrentCodeLabel, ["PIN2"])
            model.secondTextFieldLabelText = L(.myEidNewCodeLabel, ["PIN2", 5])
            model.thirdTextFieldLabelText = L(.myEidNewCodeAgainLabel, ["PIN2"])
            
            model.discardButtonTitleText = L(.myEidDiscardButtonTitle)
            model.confirmButtonTitleText = L(.myEidConfirmChangeButtonTitle)
            
        case .unblockPin2:
        
            model.titleText = L(.myEidUnblockCodeTitle, ["PIN2"])
            model.infoBullets.append(L(.myEidInfoBulletSameCodesWarning, ["PIN2"]))
            model.infoBullets.append(L(.myEidInfoBulletSignCertInfo))
            model.infoBullets.append(L(.myEidInfoBulletForgotCodeNote, ["PIN2", "PIN2"]))
            model.infoBullets.append(L(.myEidInfoBulletPukEnvelopeInfo))
            
            model.firstTextFieldLabelText = L(.myEidCurrentCodeLabel, ["PUK"])
            model.secondTextFieldLabelText = L(.myEidNewCodeLabel, ["PIN2", 5])
            model.thirdTextFieldLabelText = L(.myEidNewCodeAgainLabel, ["PIN2"])
            
            model.discardButtonTitleText = L(.myEidDiscardButtonTitle)
            model.confirmButtonTitleText = L(.myEidConfirmUnblockButtonTitle)
            
        case .changePuk:
        
            model.titleText = L(.myEidChangeCodeTitle, ["PUK"])
            model.infoBullets.append(L(.myEidInfoBulletPukUnblockInfo))
            model.infoBullets.append(L(.myEidInfoBulletPukBlockedWarning))
            
            model.firstTextFieldLabelText = L(.myEidCurrentCodeLabel, ["PUK"])
            model.secondTextFieldLabelText = L(.myEidNewCodeLabel, ["PUK", 8])
            model.thirdTextFieldLabelText = L(.myEidNewCodeAgainLabel, ["PUK"])
            
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
