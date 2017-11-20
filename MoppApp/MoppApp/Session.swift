//
//  Session.m
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

class Session
{
    static let shared = Session()

    func setup() {
        let newContainerFormat: String = DefaultsHelper.newContainerFormat
        if newContainerFormat == "" {
            DefaultsHelper.newContainerFormat = ContainerFormatBdoc
        }
    }

    func createMobileSignature(withContainer containerPath: String, idCode: String, language: String, phoneNumber: String) {
        MoppLibContainerActions.sharedInstance().getContainerWithPath(
            containerPath,
            success: { (_ initialContainer: MoppLibContainer) -> Void in
        
                MoppLibService.sharedInstance().mobileCreateSignature(
                    withContainer: containerPath,
                    idCode: idCode,
                    language: language,
                    phoneNumber: phoneNumber,
                    withCompletion: { (_ response: MoppLibMobileCreateSignatureResponse) -> Void in
                    
                        NotificationCenter.default.post(
                            name: .createSignatureNotificationName,
                            object: nil,
                            userInfo: [kCreateSignatureResponseKey: response])
                        
                    } as! MobileCreateSignatureResponseBlock,
                    andStatus: { (_ container: MoppLibContainer?, _ error: NSError?, _ status: String) -> Void in
                    
                        if error?.domain != nil {
                            NotificationCenter.default.post(name: .errorNotificationName, object: nil, userInfo: [kErrorKey: error])
                        }
                        else if container != nil {
                            NotificationCenter.default.post(name: .signatureAddedToContainerNotificationName, object: nil, userInfo: [kNewContainerKey: container, kOldContainerKey: initialContainer])
                        }

                        } as! SignatureStatusBlock
                    
                )} as! ContainerBlock,
            failure: { (_ error: Error?) -> Void in
            NotificationCenter.default.post(name: .errorNotificationName, object: nil, userInfo: [kErrorKey: error])
                return
            })
    }
}
