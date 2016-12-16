//
//  CardReaderWrapper.swift
//  MOPP POC
//
//  Created by Katrin Annuk on 15/12/16.
//  Copyright © 2016 Katrin Annuk. All rights reserved.
//

import Foundation

protocol CardReaderWrapper {
    func authenticateWith(masterKey:Data, success: @escaping (AnyObject?) -> Void, failure: @escaping (Error) -> Void) -> Bool
    func powerOn(success: @escaping (AnyObject?) -> Void, failure: @escaping (Error) -> Void) -> Bool
    func getCardStatus(success: @escaping (AnyObject?) -> Void, failure: @escaping (Error) -> Void) -> Bool
    func transmit(apdu:Data, success: @escaping (AnyObject?) -> Void, failure: @escaping (Error) -> Void) -> Bool
    
}
