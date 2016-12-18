//
//  CardReaderACR3901U-S1.swift
//  MOPP POC
//
//  Created by Katrin Annuk on 15/12/16.
//  Copyright © 2016 Katrin Annuk. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol CardReaderARC3901U_S1Delegate {
    func cardStatusChanged(to:UInt)
}

class CardReaderARC3901U_S1:NSObject, CardReaderWrapper, ABTBluetoothReaderManagerDelegate, ABTBluetoothReaderDelegate {
    
    var delegate:CardReaderARC3901U_S1Delegate?
    
    var bluetoothReader:ABTBluetoothReader?
    let bluetoothReaderManager:ABTBluetoothReaderManager = ABTBluetoothReaderManager()
    
    var successClosure:((AnyObject?) -> Void)?
    var errorClosure:((Error) -> Void)?
    
    // MARK: - Bluetooth reader manager
    
    func bluetoothReaderManager(_ bluetoothReaderManager: ABTBluetoothReaderManager!, didDetect reader: ABTBluetoothReader!, peripheral: CBPeripheral!, error: Error!) {
        if error != nil {
            
        } else {
            bluetoothReader = reader
            bluetoothReader?.delegate = self
            bluetoothReader?.attach(peripheral)
        }
    }
    
    // MARK: - Bluetooth Reader
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didAttach peripheral: CBPeripheral!, error: Error!) {
        if error != nil {
            if errorClosure != nil {
                errorClosure!(error)
            }
        } else {
            if successClosure != nil {
                successClosure!(true as AnyObject?)
            }
        }
    }
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didReturnDeviceInfo deviceInfo: NSObject!, type: UInt, error: Error!) {
        if error != nil {
  
        } else {

        }
    }
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didAuthenticateWithError error: Error!) {
        if error != nil {
            if errorClosure != nil {
                errorClosure!(error)
            }
        } else {
            if successClosure != nil {
                successClosure!(true as AnyObject?)
            }
        }
    }
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didReturnAtr atr: Data!, error: Error!) {
        if error != nil {
            if errorClosure != nil {
                errorClosure!(error)
            }
        } else {
            if successClosure != nil {
                successClosure!(atr as AnyObject?)
            }
        }
    }
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didPowerOffCardWithError error: Error!) {
        if error != nil {
            
        } else {
        }
    }
    
    
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didReturnCardStatus cardStatus: UInt, error: Error!) {
        if error != nil {
            if errorClosure != nil {
                errorClosure!(error)
            }
        } else {
            if successClosure != nil {
                successClosure!(cardStatus as AnyObject?)
            }
        }
    }
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didReturnResponseApdu apdu: Data!, error: Error!) {
        if error != nil {
            if errorClosure != nil {
                errorClosure!(error)
            }
        } else {
            if successClosure != nil {
                successClosure!(apdu as AnyObject?)
            }
        }
    }
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didReturnEscapeResponse response: Data!, error: Error!) {
        if error != nil {
            
        } else {
        }
    }
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didChangeCardStatus cardStatus: UInt, error: Error!) {
        if error != nil {
            
        } else {
            if delegate != nil {
                self.delegate?.cardStatusChanged(to: cardStatus)
            }
        }
    }
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didChangeBatteryStatus batteryStatus: UInt, error: Error!) {
        
        if error != nil {
            
        } else {
        }
    }
    
    func bluetoothReader(_ bluetoothReader: ABTBluetoothReader!, didChangeBatteryLevel batteryLevel: UInt, error: Error!) {
        if error != nil {
            
        } else {
        }
    }
    
    // MARK: - CardReaderWrapper
    
    func authenticateWith(masterKey:Data, success: @escaping (AnyObject?) -> Void, failure: @escaping (Error) -> Void) -> Bool {
        
        // TODO: - need to make sure closures are not overwritten prematurely
        
        self.successClosure = success
        self.errorClosure = failure
        return (bluetoothReader?.authenticate(withMasterKey: masterKey))!
    }
    
    func powerOn(success: @escaping (AnyObject?) -> Void, failure: @escaping (Error) -> Void) -> Bool {
        self.successClosure = success
        self.errorClosure = failure
        return (bluetoothReader?.powerOnCard())!
    }
    
    func getCardStatus(success: @escaping (AnyObject?) -> Void, failure: @escaping (Error) -> Void) -> Bool {
        self.successClosure = success
        self.errorClosure = failure
        return (bluetoothReader?.getCardStatus())!
    }
    
    func transmit(apdu:Data, success: @escaping (AnyObject?) -> Void, failure: @escaping (Error) -> Void) -> Bool {
        self.successClosure = success
        self.errorClosure = failure
        return (bluetoothReader?.transmitApdu(apdu))!
    }
    
    // MARK: - Public Methods
    func setup(delegate:CardReaderARC3901U_S1Delegate) {
        bluetoothReaderManager.delegate = self
        self.delegate = delegate
    }
    
    func attachReader(with:CBPeripheral, success: @escaping (AnyObject?) -> Void, failure: @escaping (Error) -> Void) {
        self.successClosure = success
        self.errorClosure = failure
        bluetoothReaderManager.detectReader(with: with)
    }
}
