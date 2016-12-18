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
    
    var commands:Array<Data> = Array()
    
    var readerSelection:ReaderSelectionController?
    
    var cardReader:CardReaderWrapper?
    
    
    let commandSelectMaster = "00 A4 00 0C"
    let commandSelectEEEE = "00 A4 01 0C 02 EE EE"
    let commandSelect5044 = "00 A4 02 04 02 50 44"
    let commandSelectAACE = "00 A4 02 04 02 AA CE"
    
    let commandReadLastName = "00 B2 01 04"
    let commandReadFirstNameLine1 = "00 B2 02 04"
    let commandReadFirstNameLine2 = "00 B2 03 04"
    let commandReadBirthDate = "00 B2 06 04"
    let commandReadIdCode = "00 B2 07 04"

    let commandReadBinary = "00 B0"

    var atrString:String = ""
    var hasAuthenticated = false
    
    var certificateAACE:Data = Data()
    
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
        self.readCardPublicData()
        self.readCertificates()
    }

    func readCardPublicData() {
        self.addCommand(command: commandSelectMaster)
        self.addCommand(command: commandSelectEEEE)
        self.addCommand(command: commandSelect5044)
        self.addCommand(command: commandReadLastName)
        self.addCommand(command: commandReadFirstNameLine1)
        self.addCommand(command: commandReadFirstNameLine2)
        self.addCommand(command: commandReadBirthDate)
        self.addCommand(command: commandReadIdCode)
    }
    
    func readCertificates() {
        // Select correct file
        self.addCommand(command: commandSelectMaster)
        self.addCommand(command: commandSelectEEEE)
        self.addCommand(command: commandSelectAACE)

        // file can be read after navigation to AACE file will be done (need file length)
    }
    
    let maxReadLength = 254
    
    func readFile(fileSize:(Int)) {
        self.readFile(offsetByte: 0, fileSizeBytes: fileSize)
    }
    
    func readFile(offsetByte:Int, fileSizeBytes:Int) {
        
        let offsetHex1 = String(format:"%04X", offsetByte)
        var length = fileSizeBytes - offsetByte
        if length > maxReadLength {
            length = maxReadLength
        }
        
        let lengthString = String(format:"%02X", length)
        
        let command = commandReadBinary.appending(" \(offsetHex1) \(lengthString)")

        let success = self.cardReader?.transmit(apdu: ABDHex.byteArray(fromHexString: command), success: { (result) in
            let apdu:Data = result as! Data
            let trimmedApdu = ABDHex.byteArray(fromHexString: self.removeOkTrailer(string: ABDHex.hexString(fromByteArray: apdu)))
            
            self.certificateAACE.append(trimmedApdu!)
            
            let newOffset = offsetByte + length
            
            if newOffset < fileSizeBytes {
                // Read next part
                self.readFile(offsetByte: newOffset, fileSizeBytes: fileSizeBytes)
            } else {
                // File reading complete
                self.updateCertificateData()
            }
        }, failure: { (error) in
            
        })
        
        if success == true {
            
        }
    }
    
    func addCommand(command:String) {
        commands.append(ABDHex.byteArray(fromHexString: command))
        if commands.count == 1 {
            self.transmitNextCommand()
        }
    }
    
    func authenticate() {
        let key = ABDHex.byteArray(fromHexString: "FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF")
        let success = self.cardReader?.authenticateWith(masterKey: key!, success: { (result) in
            print("did authenticate")
            self.hasAuthenticated = true
            self.transmitNextCommand()
        }, failure: { (error) in
            self.hasAuthenticated = false
            self.showError(error: error)
        })
        
        if success == false {
            print("Couldn't authenticate")
        }
    }
    
    func getCardStatus() {
        let success = self.cardReader?.getCardStatus(success: { (result) in
            self.cardStatusUpdated(status: result as! Int)

        }, failure: { (error) in
            self.showError(error: error)
        })
        
        if success == false {
            print("Couldn't get card status")
        }
    }
    
    func powerOnCard() {
        let success = self.cardReader?.powerOn(success: { (result) in
            let data:Data = result as! Data
            self.atrString = ABDHex.hexString(fromByteArray: data)
            self.transmitNextCommand()
        }, failure: { (error) in
            self.showError(error: error)
        })
        
        if success == false {
            print("Couldn't power on card")
        }
    }
    
    func transmitApdu(data:Data) {
        let success = self.cardReader?.transmit(apdu: data, success: { (result) in
            let apdu:Data = result as! Data
            
            let commandString = ABDHex.hexString(fromByteArray: data)
                
                print("return apdu: \(ABDHex.hexString(fromByteArray: apdu))")
                
                let trimmedApdu = self.removeOkTrailer(string: ABDHex.hexString(fromByteArray: apdu))
                
                if commandString == self.commandReadLastName {
                    self.lastName = self.hexToString(string: trimmedApdu)
                    self.updateName()
                    
                } else if commandString == self.commandReadFirstNameLine1 {
                    self.firstNameLine1 = self.hexToString(string: trimmedApdu)
                    self.updateName()
                    
                } else if commandString == self.commandReadFirstNameLine2 {
                    self.firstNameLine2 = self.hexToString(string: trimmedApdu)
                    self.updateName()
                    
                } else if commandString == self.commandReadIdCode {
                    self.idCodeLabel.text = self.hexToString(string: trimmedApdu)
                    
                } else if commandString == self.commandReadBirthDate {
                    self.birthDateLabel.text = self.hexToString(string: trimmedApdu)
                    
                } else if commandString == self.commandSelectAACE {
                    let index: Data.Index = apdu.startIndex + 11
                    let sizeData = apdu.subdata(in: Range<Data.Index>(uncheckedBounds: (lower: index, upper: index + 2)))
                    let size = ABDHex.hexString(fromByteArray: sizeData).replacingOccurrences(of: " ", with: "")
                    let sizeDecimal = Int("\(size)", radix:16)
                    
                    self.readFile(fileSize:sizeDecimal!)
                    return;
                } else if commandString!.hasPrefix(self.commandReadBinary) {
                    let trimmedApdu = self.removeOkTrailer(string: ABDHex.hexString(fromByteArray: apdu))

                    self.certificateAACE.append(ABDHex.byteArray(fromHexString: trimmedApdu))
                    self.updateCertificateData()
                }
                
                self.transmitNextCommand()
        }, failure: { (error) in
            self.showError(error: error)
            self.transmitNextCommand()
        })
        
        if success == false {
            print("Couldn't transmit apdu")
        }
    }
    
    func transmitNextCommand() {
        if hasAuthenticated == false {
            authenticate()

        } else if cardState == ABTBluetoothReaderCardStatusAbsent {
            // User needs to insert card first
            
        } else if cardState == ABTBluetoothReaderCardStatusPowerSavingMode {
            self.getCardStatus()
            
        } else if atrString.characters.count == 0 {
            self.powerOnCard()
            
        } else if commands.count > 0 {
            let data = commands.first
            commands.removeFirst()
            
            self.transmitApdu(data: data!)
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
    
    func updateCertificateData() {
        self.authCertIssuerLabel.text = X509Wrapper.getIssuerName(self.certificateAACE)
        let date = X509Wrapper.getExpiryDate(self.certificateAACE)
        if date != nil {
            let formatter = DateFormatter()
            formatter.dateStyle = DateFormatter.Style.medium
            self.authCertExpirationLabel.text = formatter.string(from: date!)
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
        self.commands.removeAll()
        
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
}

