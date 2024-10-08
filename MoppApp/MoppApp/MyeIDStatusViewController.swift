//
//  MyeIDStatusViewController.swift
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
class MyeIDStatusViewController : MoppViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusStackView: UIStackView!
    
    var loadingView: SpinnerView?
    
    enum State {
        case initial
        case readerNotFound
        case readerRestarted
        case idCardNotFound
        case readerProcessFailed
        case requestingData
    }
    
    override func viewDidLoad() {
        if let spinnerView = MoppApp.instance.nibs[.customElements]?.instantiate(withOwner: self, type: SpinnerView.self) {
            spinnerView.show(true)
            spinnerView.translatesAutoresizingMaskIntoConstraints = false
            statusStackView.addArrangedSubview(spinnerView)
            loadingView = spinnerView
        }
    }
    
    var state: State = .readerNotFound {
        didSet {
            switch (state) {
            case .initial:
                titleLabel.text = L(.myEidStatusReaderNotFound)
                UIAccessibility.post(notification: .layoutChanged, argument: titleLabel)
                setSpinnerView(loadingView, false)
            case .readerNotFound:
                titleLabel.text = L(.myEidStatusReaderNotFound)
                UIAccessibility.post(notification: .layoutChanged, argument: titleLabel)
                setSpinnerView(loadingView, false)
            case .readerRestarted:
                titleLabel.text = L(.cardReaderStateReaderRestarted)
                UIAccessibility.post(notification: .layoutChanged, argument: titleLabel)
                setSpinnerView(loadingView, true)
            case .idCardNotFound:
                titleLabel.text = L(.myEidStatusCardNotFound)
                UIAccessibility.post(notification: .layoutChanged, argument: titleLabel)
                setSpinnerView(loadingView, true)
            case .requestingData:
                titleLabel.text = L(.myEidStatusRequestingData)
                UIAccessibility.post(notification: .layoutChanged, argument: titleLabel)
                setSpinnerView(loadingView, true)
            case .readerProcessFailed:
                titleLabel.text = L(.cardReaderStateReaderProcessFailed)
                UIAccessibility.post(notification: .layoutChanged, argument: titleLabel)
                setSpinnerView(loadingView, false)
            }
            titleLabel.font = UIFont.moppUltraLargeMedium
            titleLabel.setNeedsDisplay()
        }
    }
    
    func setSpinnerView(_ loadingView: SpinnerView?, _ show: Bool) {
        if let spinnerView = loadingView {
            spinnerView.show(show)
        }
    }
}

