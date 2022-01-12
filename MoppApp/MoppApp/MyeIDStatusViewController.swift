//
//  MyeIDStatusViewController.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2022 Riigi Infosüsteemi Amet
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
class MyeIDStatusViewController : MoppViewController {
    @IBOutlet weak var titleLabel: UILabel!
    
    enum State {
        case readerNotFound
        case idCardNotFound
        case requestingData
    }
    
    var state: State = .readerNotFound {
        didSet {
            switch (state) {
            case .readerNotFound:
                titleLabel.text = L(.myEidStatusReaderNotFound)
                UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: titleLabel)
            case .idCardNotFound:
                titleLabel.text = L(.myEidStatusCardNotFound)
                UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: titleLabel)
            case .requestingData:
                titleLabel.text = L(.myEidStatusRequestingData)
                UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: titleLabel)
            }
            titleLabel.setNeedsDisplay()
        }
    }
}

