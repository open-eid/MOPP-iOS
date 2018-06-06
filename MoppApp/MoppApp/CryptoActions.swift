//
//  CryptoActions.swift
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
import Foundation

protocol CryptoActions {
    func startEncryptingProcess()
}

extension CryptoActions where Self: CryptoContainerViewController {
    
    func startEncryptingProcess() {
        if container.addressees.count > 0 {
            MoppLibCryptoActions.sharedInstance().encryptData(
                container.filePath as String?,
                withDataFiles: container.dataFiles as! [Any],
                withAddressees: container.addressees as! [Any],
                success: {
                    self.isCreated = false
                    self.isForPreview = false
                    self.state = .loading
                    self.containerViewDelegate.openContainer(afterSignatureCreated: true)
                    self.notifications.append((true, L(.cryptoEncryptionSuccess)))
                    self.reloadCryptoData()
                    
            },
                failure: { _ in
                    DispatchQueue.main.async {
                        self.errorAlert(message: L(.cryptpEncryptionErrorText))
                    }
                }
            )
        } else {
            self.errorAlert(message: L(.cryptoNoAddresseesWarning))
        }
    }
    
}
