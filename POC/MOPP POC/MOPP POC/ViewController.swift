//
//  ViewController.swift
//  MOPP POC
//
//  Created by Katrin Annuk on 12/12/16.
//  Copyright © 2016 Katrin Annuk. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UITableViewController, CBCentralManagerDelegate, CBPeripheralDelegate, CardReaderARC3901U_S1Delegate {
    @IBOutlet weak var cardReaderCell: UITableViewCell!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var idCodeLabel: UILabel!
    @IBOutlet weak var birthDateLabel: UILabel!
    @IBOutlet weak var authCertIssuerLabel: UILabel!
    @IBOutlet weak var authCertExpirationLabel: UILabel!
    @IBOutlet weak var signingCertIssuerLabel: UILabel!
    @IBOutlet weak var signingCertExpirationLabel: UILabel!
    @IBOutlet weak var signingTextField: UITextView!
    @IBOutlet weak var signingResultField: UITextView!
    
    var centralManager:CBCentralManager!
    var peripheral:CBPeripheral! {
        didSet {
            if peripheral != nil {
                if peripheral.name != nil && peripheral.name!.characters.count > 0 {
                    cardReaderCell.textLabel?.text = peripheral.name
                } else {
                    cardReaderCell.textLabel?.text = peripheral.identifier.uuidString
                }
            } else {
                cardReaderCell.textLabel?.text = "Ühenda lugejaga"
            }
        }
    }
    var peripherals:NSMutableArray = []
    
    var cardActions:Array<CardAction> = Array()
    var currentAction:CardAction = CardAction.none
    
    var readerSelection:ReaderSelectionController?
    
    var cardReader:CardReaderWrapper?
    
    
    let commandSelectMaster = "00 A4 00 0C"
    let commandSelectEEEE = "00 A4 01 0C 02 EE EE"
    let commandSelect5044 = "00 A4 02 04 02 50 44"
    let commandSelectAACE = "00 A4 02 04 02 AA CE"
    let commandSelectDDCE = "00 A4 02 04 02 DD CE"

    let commandReadLastName = "00 B2 01 04"
    let commandReadFirstNameLine1 = "00 B2 02 04"
    let commandReadFirstNameLine2 = "00 B2 03 04"
    let commandReadBirthDate = "00 B2 06 04"
    let commandReadIdCode = "00 B2 07 04"

    let commandReadBinary = "00 B0"
    
    let commandSetSecurityEnv1 = "00 22 F3 01"
    let commandVerifyPin2 = "00 20 00 02"
    let commandCalculateSignature = "00 2A 9E 9A"
    
    enum CardAction {
        case none
        case readPublicData
        case readAuthCert
        case readSigningCert
    }

    var atrString:String = ""
    var hasAuthenticated = false
    
    var cardState = ABTBluetoothReaderCardStatusUnknown
    
    var firstNameLine1:String = ""
    var firstNameLine2:String = ""
    var lastName:String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cardReaderARC3901U_S1 = CardReaderARC3901U_S1()
        cardReaderARC3901U_S1.setup(delegate: self)
        self.cardReader = cardReaderARC3901U_S1
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "ReaderSelection" {
            
            readerSelection = segue.destination as? ReaderSelectionController
            readerSelection?.peripheral = nil
            readerSelection?.peripherals = peripherals
            
            if peripheral != nil {
                centralManager.cancelPeripheralConnection(peripheral)
            }
            
            
            if centralManager.state == CBManagerState.poweredOn {
                print("Starting scan")

                centralManager.scanForPeripherals(withServices: nil, options: nil)
            } else {
                print("Bluetooth not available")
            }
        }
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        
        if segue.source is ReaderSelectionController {
            print("Stoping scan")

            centralManager.stopScan()
            peripheral = readerSelection?.peripheral
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    // MARK: - CBCentralManager
    
    private var firstRun = true;
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central manager did update state \(central.state)")

        var message:NSString?
        
        switch central.state {
        case CBManagerState.unknown,
             CBManagerState.resetting:
            message = "The update is being started. Please wait until Bluetooth is ready."
            break
            
        case CBManagerState.unsupported:
            message = "This device does not support Bluetooth low energy."
            break
            
        case CBManagerState.unauthorized:
            message = "This app is not authorized to use Bluetooth low energy."
            break
            
        case CBManagerState.poweredOff:
            if firstRun == false {
                message = "You must turn on Bluetooth in Settings in order to use the reader."
            }
            break
        default:
            break
        }
        
        if message != nil {
            let alertController = UIAlertController(title: "Bluetooth", message: "\(message)", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: {(alert: UIAlertAction!) in
                }))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Central manager did connect")
        
        if cardReader is CardReaderARC3901U_S1 {
            let reader:CardReaderARC3901U_S1 = cardReader as! CardReaderARC3901U_S1
            
            reader.attachReader(with: peripheral, success: { (result) in
                self.resetData()
                let alertController = UIAlertController(title: "Reader attached", message: "The reader is attached to the peripheral successfully.", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: {(alert: UIAlertAction!) in
                }))
                self.present(alertController, animated: true, completion: nil)
                
            }, failure: { (error) in
                self.showError(error: error)
            })
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripherals.index(of: peripheral) == NSNotFound {

            peripherals.add(peripheral)
            if readerSelection != nil {
                readerSelection!.peripherals = peripherals
            }
        }
    }
    
    // MARK: - CardReaderARC3901U_S1Delegate
    
    func cardStatusChanged(to: UInt) {
         self.cardStatusUpdated(status: Int(to))
    }
    
    // MARK: - Private methods
    
    func showError(error: Error!) {
        let alertController = UIAlertController(title: "Error", message: "\(error.localizedDescription)", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: {(alert: UIAlertAction!) in
            }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func readCardData() {
        self.addCardAction(action: CardAction.readPublicData)
        self.addCardAction(action: CardAction.readAuthCert)
        self.addCardAction(action: CardAction.readSigningCert)
        
        self.startNextActionIfNeeded()
    }

    func readCardPublicData() {
        self.navigateToFile5044 { (data) in
            let responseBytes = data as! Data
            
            if responseBytes.count > 0 {
                self.readName(completion: {
                    self.updateName()
                    self.readBirthDate(completion: {
                        self.readIdCode(completion: {
                            self.currentAction = CardAction.none
                            self.startNextActionIfNeeded()
                        })
                    })
                })
            }
        }
    }
    
    func readBirthDate(completion: @escaping () -> Void) {
        self.readRecordWith(command: commandReadBirthDate, completion: { (string) in
            self.birthDateLabel.text = string
            completion()
        })
    }
    
    func readIdCode(completion: @escaping () -> Void) {
        self.readRecordWith(command: commandReadIdCode, completion: { (string) in
            self.idCodeLabel.text = string
            completion()
        })
    }
    
    func readName(completion:@escaping () -> Void) {
        self.readLastName { 
            self.readFirstNameLine1(completion: {
                self.readFirstNameLine2(completion: {
                    completion()
                })
            })
        }
    }
    
    func readLastName(completion:@escaping () -> Void) {
        self.readRecordWith(command: commandReadLastName, completion: { (string) in
            self.lastName = string
            completion()
        })
    }
    
    func readFirstNameLine1(completion:@escaping () -> Void) {
        self.readRecordWith(command: commandReadFirstNameLine1, completion: { (string) in
            self.firstNameLine1 = string
            completion()
        })
    }
    
    func readFirstNameLine2(completion:@escaping () -> Void) {
        self.readRecordWith(command: commandReadFirstNameLine2, completion: { (string) in
            self.firstNameLine2 = string
            completion()
        })
    }
    
    func readRecordWith(command:String, completion:@escaping (String) -> Void) {
        let commandHex = ABDHex.byteArray(fromHexString:command)
        let success = self.cardReader?.transmit(apdu: commandHex!, success: { (data) in
            let apdu:Data = data as! Data
            let trimmedApdu = self.removeOkTrailer(string: ABDHex.hexString(fromByteArray: apdu))
            let string = self.hexToString(string: trimmedApdu)
            completion(string)
            
        }, failure: { (error) in
            self.showError(error: error)
            completion("")
        })
        
        if success == false {
            print("Unable to transmit data")
            completion("")
        }
    }
    
    func readAuthCertificate() {
        // Select correct file
        
        self.navigateToFileAACE { (data) in
            let responseBytes = data as! Data

            if responseBytes.count > 0 {
                let index: Data.Index = responseBytes.startIndex + 11
                let sizeData = responseBytes.subdata(in: Range<Data.Index>(uncheckedBounds: (lower: index, upper: index + 2)))
                let size = ABDHex.hexString(fromByteArray: sizeData).replacingOccurrences(of: " ", with: "")
                let sizeDecimal = Int("\(size)", radix:16)
                self.readFile(fileSize:sizeDecimal!, completion: { (data) in
                    self.updateAuthCertificate(data: data)
                    self.currentAction = CardAction.none
                    self.startNextActionIfNeeded()
                })
            }
        }
    }
    
    func readSigningCertificate() {
        // Select correct file
        
        self.navigateToFileDDCE { (data) in
            let responseBytes = data as! Data
            if responseBytes.count > 0 {
                let index: Data.Index = responseBytes.startIndex + 11
                let sizeData = responseBytes.subdata(in: Range<Data.Index>(uncheckedBounds: (lower: index, upper: index + 2)))
                let size = ABDHex.hexString(fromByteArray: sizeData).replacingOccurrences(of: " ", with: "")
                let sizeDecimal = Int("\(size)", radix:16)
                self.readFile(fileSize:sizeDecimal!, completion: { (data) in
                    self.updateSigningCertificate(data: data)
                    self.currentAction = CardAction.none
                    self.startNextActionIfNeeded()
                })
            }
        }
    }
    
    func navigateToFile5044(completion:@escaping (AnyObject?) -> Void) {
        self.navigateToFileEEEE { (data) in
            self.navigateToFile(command: self.commandSelect5044, completion: { (data) in
                completion(data)
            })
        }
    }
    
    func navigateToFileEEEE(completion:@escaping (AnyObject?) -> Void) {
        self.navigateToFile(command: self.commandSelectMaster, completion: { (data) in
            self.navigateToFile(command: self.commandSelectEEEE, completion: { (data) in
                completion(data)
            })
        })
    }
    
    
    func navigateToFileAACE(completion:@escaping (AnyObject?) -> Void) {
        self.navigateToFileEEEE { (data) in
            self.navigateToFile(command: self.commandSelectAACE, completion: { (data) in
                completion(data)
            })
        }
    }
    
    func navigateToFileDDCE(completion:@escaping (AnyObject?) -> Void) {
        self.navigateToFileEEEE { (data) in
            self.navigateToFile(command: self.commandSelectDDCE, completion: { (data) in
                completion(data)
            })
        }
    }
    
    func navigateToFile(command:String, completion:@escaping (AnyObject?) -> Void) {
        let commandHex = ABDHex.byteArray(fromHexString:command)
        let success = self.cardReader?.transmit(apdu: commandHex!, success: { (data) in
            completion(data)

        }, failure: { (error) in
            self.showError(error: error)
            completion(nil)
        })
        
        if success == false {
            print("Unable to transmit data")
            completion(nil)
        }
    }
    
    
    
    let maxReadLength = 254
    
    func readFile(fileSize:(Int), completion: @escaping (Data) -> Void) {
        self.readFile(offsetByte: 0, fileSizeBytes: fileSize, readBytes:Data(), completion: { (data) in
            completion(data)
        })
    }
    
    func readFile(offsetByte:Int, fileSizeBytes:Int, readBytes:Data, completion: @escaping (Data) -> Void) {
        
        let offsetHex1 = String(format:"%04X", offsetByte)
        var length = fileSizeBytes - offsetByte
        if length > maxReadLength {
            length = maxReadLength
        }
        
        let lengthString = String(format:"%02X", length)
        
        let command = commandReadBinary.appending(" \(offsetHex1) \(lengthString)")

        let success = self.cardReader?.transmit(apdu: ABDHex.byteArray(fromHexString: command), success: {(result) in
            let apdu:Data = result as! Data
            let trimmedApdu = ABDHex.byteArray(fromHexString: self.removeOkTrailer(string: ABDHex.hexString(fromByteArray: apdu)))
            
            var newReadBytes = readBytes
            newReadBytes.append(trimmedApdu!)
            
            let newOffset = offsetByte + length
            
            if newOffset < fileSizeBytes {
                // Read next part
                self.readFile(offsetByte: newOffset, fileSizeBytes: fileSizeBytes, readBytes:newReadBytes, completion:completion)
            } else {
                // File reading complete
                completion(newReadBytes)
            }
        }, failure: { (error) in
            
        })
        
        if success == true {
            
        }
    }
    
    func calculateSignatureFor(text:String, pin2:String, completion:@escaping (AnyObject?) -> Void) {
        
        self.setSecurityEnv1 { (securityEnvResult) in

            self.verify(pin2: pin2, completion: { (pin2Result) in

                let sha1String = NSString(string: text).sha1()
                let lengthHex = String(format:"%02X", sha1String!.characters.count)
                let sha1Hex = ABDHex.hex(fromStr: sha1String!)
                
                let command = self.commandCalculateSignature.appending("3021300906052B0E03021A05000414\(lengthHex) \(sha1Hex)")
                let commandHex = ABDHex.byteArray(fromHexString:command)
                let success = self.cardReader?.transmit(apdu: commandHex!, success: { (data) in
                    completion(data)
                    
                }, failure: { (error) in
                    self.showError(error: error)
                    completion(nil)
                })
                
                if success == false {
                    print("Unable to transmit data")
                    completion(nil)
                }
            })
        }
    }
    
    func setSecurityEnv1(completion:@escaping (AnyObject?) -> Void) {
        let commandHex = ABDHex.byteArray(fromHexString:commandSetSecurityEnv1)
        let success = self.cardReader?.transmit(apdu: commandHex!, success: { (data) in
            completion(data)
            
        }, failure: { (error) in
            self.showError(error: error)
            completion(nil)
        })
        
        if success == false {
            print("Unable to transmit data")
            completion(nil)
        }
    }
    
    func verify(pin2:String, completion:@escaping (AnyObject?) -> Void) {
        let lengthString = String(format:"%02X", pin2.characters.count)
        let pinString = ABDHex.hex(fromStr: pin2)

        let command = commandVerifyPin2.appending(" \(lengthString)").appending(" \(pinString!)")
        let commandHex = ABDHex.byteArray(fromHexString:command)

        let success = self.cardReader?.transmit(apdu: commandHex!, success: { (data) in
            if ABDHex.hexString(fromByteArray: data as! Data!) != "90 00" {
                let alertController = UIAlertController(title: "Error", message: "PINi verfitseerimine ebaõnnestus. Tagastatud: \(ABDHex.hexString(fromByteArray: data as! Data!))", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: {(alert: UIAlertAction!) in
                }))
                self.present(alertController, animated: true, completion: nil)
            } else {
                completion(data)
            }
            
        }, failure: { (error) in
            self.showError(error: error)
            completion(nil)
        })
        
        if success == false {
            print("Unable to transmit data")
            completion(nil)
        }
    }

    
    func addCardAction(action: CardAction) {
        self.cardActions.append(action)

    }
    
    func authenticate(completion:@escaping (Bool) -> Void) {
        let key = ABDHex.byteArray(fromHexString: "FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF")
        let success = self.cardReader?.authenticateWith(masterKey: key!, success: { (result) in
            print("did authenticate")
            self.hasAuthenticated = true
            completion(true)
        }, failure: { (error) in
            self.hasAuthenticated = false
            self.showError(error: error)
            completion(false)
        })
        
        if success == false {
            print("Couldn't authenticate")
            completion(false)
        }
    }
    
    func getCardStatus(completion:@escaping (Bool) -> Void) {
        let success = self.cardReader?.getCardStatus(success: { (result) in
            self.cardStatusUpdated(status: result as! Int)
            completion(true)

        }, failure: { (error) in
            self.showError(error: error)
            completion(false)
        })
        
        if success == false {
            print("Couldn't get card status")
            completion(false)
        }
    }
    
    func powerOnCard(completion:@escaping (Bool) -> Void) {
        let success = self.cardReader?.powerOn(success: { (result) in
            let data:Data = result as! Data
            self.atrString = ABDHex.hexString(fromByteArray: data)
            completion(true);
            
        }, failure: { (error) in
            self.showError(error: error)
            completion(false);
        })
        
        if success == false {
            print("Couldn't power on card")
            completion(true);
        }
    }
    
    func startNextActionIfNeeded() {
        if self.currentAction != CardAction.none {
            // Can't start new action before previous one is finished
            return;
        }
        
        if cardState == ABTBluetoothReaderCardStatusAbsent {
            // User needs to insert card first
            return
        } else if cardState == ABTBluetoothReaderCardStatusPowerSavingMode {
            executeAfterCardStatusUpdate(execute: { () in
                self.startNextActionIfNeeded()
            })
            
        } else if self.cardActions.count > 0 {
            self.currentAction = self.cardActions[0]
            self.cardActions.removeFirst()
            
            self.executeAfterAuthentication { () in
                self.executeAfterPowerOn(execute: { () in
                    self.handleCurrentAction()
                })
            }
        }
    }
    
    func executeAfterAuthentication(execute:@escaping (Void) -> Void) {
        if hasAuthenticated == false {
            authenticate(completion: { (success) in
                if(success == true) {
                    execute()
                }
            })

        } else {
            execute()
        }
    }
    
    func executeAfterCardStatusUpdate(execute:@escaping (Void) -> Void) {
        self.getCardStatus { (success) in
            execute()
        }
    }
    
    func executeAfterPowerOn(execute:@escaping (Void) -> Void) {
        if atrString.characters.count == 0 {
            self.powerOnCard { (success) in
                if(success == true) {
                    execute()
                }
            }
        } else {
            execute()
        }
    }
    
    func handleCurrentAction() {
        switch self.currentAction {
        case CardAction.readAuthCert:
            readAuthCertificate()
            break
            
        case CardAction.readSigningCert:
            readSigningCertificate()
            break
            
        case CardAction.readPublicData:
                readCardPublicData()
            break
            
        default:
            break
        }
    }
    
    func hexToString(string:String) -> String {
        let components = string.components(separatedBy: " ")
        let charArray = components.map { char -> Character in
            let code = Int(strtoul(char, nil, 16))
            return Character(UnicodeScalar(code)!)
        }

        var result = String(charArray)
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        return result
    }
    
    func removeOkTrailer(string:String) -> String {
        var newString = string
        if newString.hasSuffix("90 00") {
            let toIndex = newString.index(newString.endIndex, offsetBy: -5)
            
            newString = newString.substring(to: toIndex)
        }
        
        newString = newString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return newString
    }
    
    func updateName() {
        var name = ""
        var separator = ""
        
        if firstNameLine1.characters.count > 0 {
            name.append(firstNameLine1)
            separator = " "
        }
        
        if firstNameLine2.characters.count > 0 {
            name.append(separator)
            name.append(firstNameLine2)
            separator = " "
        }
        
        if lastName.characters.count > 0 {
            name.append(separator)
            name.append(lastName)
            separator = " "
        }
        
        if name.characters.count > 0 {
            self.nameLabel.text = name
        } else {
            self.nameLabel.text = "-"
        }
    }
    
    func updateAuthCertificate(data:Data) {
        self.authCertIssuerLabel.text = X509Wrapper.getIssuerName(data)
        let date = X509Wrapper.getExpiryDate(data)
        if date != nil {
            let formatter = DateFormatter()
            formatter.dateStyle = DateFormatter.Style.medium
            self.authCertExpirationLabel.text = formatter.string(from: date!)
        }
    }
    
    func updateSigningCertificate(data:Data) {
        self.signingCertIssuerLabel.text = X509Wrapper.getIssuerName(data)
        let date = X509Wrapper.getExpiryDate(data)
        if date != nil {
            let formatter = DateFormatter()
            formatter.dateStyle = DateFormatter.Style.medium
            self.signingCertExpirationLabel.text = formatter.string(from: date!)
        }
    }
    
    func resetData() {
        self.firstNameLine2 = ""
        self.firstNameLine1 = ""
        self.lastName = ""
        self.atrString = ""
        
        self.idCodeLabel.text = "-"
        self.birthDateLabel.text = "-"
        
        hasAuthenticated = false
        self.cardActions.removeAll()
        
        self.updateName()
    }
    
    func cardStatusUpdated(status:Int) {
        if cardState == status {
            return
        }
        
        cardState = Int(status)
        
        switch cardState {
        case ABTBluetoothReaderCardStatusUnknown:
            break
            
        case ABTBluetoothReaderCardStatusAbsent:
            self.resetData()
            break
            
        case ABTBluetoothReaderCardStatusPresent:
            self.readCardData()
            break
            
        case ABTBluetoothReaderCardStatusPowered:
            break
            
        case ABTBluetoothReaderCardStatusPowerSavingMode:
            break
            
        default: break
            
        }
    }
    
    @IBAction func signTextTapped(_ sender: Any) {
        
        let alertController = UIAlertController(title: "PIN 2", message: "Sisesta PIN 2", preferredStyle: UIAlertControllerStyle.alert)
        
        alertController.addTextField { (textField) in
            
        }
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: {[weak alertController] (_) in
            let textField = alertController!.textFields![0]
            self.sign(text:self.signingTextField.text , pin2: textField.text!)
        }))
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func sign(text:String, pin2:String) {
        if text.characters.count > 0 && pin2.characters.count > 0 {
            self.navigateToFileEEEE(completion: { (data) in
                self.calculateSignatureFor(text: self.signingTextField.text, pin2: pin2, completion: { (data) in
                    if data != nil {
                        self.tableView.beginUpdates()
                        self.signingResultField.text = ABDHex.hexString(fromByteArray: data as! Data!)
                        self.tableView.endUpdates()
                    }
                })
            })
        } else {
            let alertController = UIAlertController(title: "Error", message: "Tekst või pin 2 on puudu", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: {(alert: UIAlertAction!) in
            }))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

