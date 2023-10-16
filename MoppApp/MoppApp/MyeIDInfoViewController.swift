//
//  MyeIDInfoViewController.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2023 Riigi Infosüsteemi Amet
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

class MyeIDInfoViewController: MoppViewController {
    @IBOutlet weak var ui: MyeIDInfoViewControllerUI!
    
    weak var infoManager: MyeIDInfoManager!
    var initialLoadingComplete = false
    var isCancelMessageAnnounced = false
    var isInitializedWithBackButton = false
    
    var changePinCell: MyeIDPinPukCell?
    
    enum Segment {
        case info
        case changePins
        case margin
    }
    
    var segments: [Segment] = [.info, .margin, .changePins]
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UIAccessibility.isVoiceOverRunning && !initialLoadingComplete {
            setAccessibility(isElement: false)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if UIAccessibility.isVoiceOverRunning && !initialLoadingComplete {
            setAccessibility(isElement: false)
        }
        ui.setupOnce()
        ui.delegate = self
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didFinishAnnouncement(_:)),
            name: UIAccessibility.announcementDidFinishNotification,
            object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(handleBackButtonPressed), name: .isBackButtonPressed, object: nil)
    }
    
    @objc func didFinishAnnouncement(_ notification: Notification) {
        DispatchQueue.main.async {
            printLog("Cancel message announced")
            guard let cell = self.changePinCell else { return }
            
            for subview in cell.subviews {
                subview.isAccessibilityElement = true
            }
            
            cell.setAccessibilityFocusOnButton(actionButton: nil, cellKind: self.infoManager.actionKind)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.isCancelMessageAnnounced = false
                self.setAccessibility(isElement: true)
                self.ui.tableView.accessibilityElementsHidden = false
            }
        }
    }
    
    func setAccessibility(isElement: Bool) {
        for section in 0..<self.ui.tableView.numberOfSections {
            for row in 0..<self.ui.tableView.numberOfRows(inSection: section) {
                if let cell = self.ui.tableView.cellForRow(at: IndexPath(row: row, section: section)) {
                    for subview in cell.subviews {
                        if subview.isKind(of: UIView.self) {
                            subview.isAccessibilityElement = false
                        } else {
                            subview.isAccessibilityElement = isElement
                        }
                    }
                    cell.isAccessibilityElement = false
                }
            }
        }
    }

    private func announceCancelMessage() {
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .screenChanged, argument: changePinCell)
            if !isCancelMessageAnnounced {
                printLog("Announcing cancel message")
                self.isCancelMessageAnnounced = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    let actionKind = self.infoManager.actionKind
                    if let actionType = actionKind {
                        if actionType == .changePin1 {
                            self.postAccessibilityMessage(message: L(.myEidInfoPin1ChangeCancelled))
                        } else if actionType == .unblockPin1 {
                            self.postAccessibilityMessage(message: L(.myEidInfoPin1UnblockCancelled))
                        } else if actionType == .changePin2 {
                            self.postAccessibilityMessage(message: L(.myEidInfoPin2ChangeCancelled))
                        } else if actionType == .unblockPin2 {
                            self.postAccessibilityMessage(message: L(.myEidInfoPin2UnblockCancelled))
                        } else if actionType == .changePuk {
                            self.postAccessibilityMessage(message: L(.myEidInfoPukChangeCancelled))
                        }
                    }
                }
            }
        }
    }
    
    private func postAccessibilityMessage(message: String) {
        UIAccessibility.post(notification: .announcement, argument: NSAttributedString(string: message, attributes: [.accessibilitySpeechQueueAnnouncement: false]))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if UIAccessibility.isVoiceOverRunning && !initialLoadingComplete {
            UIAccessibility.post(notification: .screenChanged, argument: ui.tableView)
        } else if UIAccessibility.isVoiceOverRunning && !isInitializedWithBackButton {
            self.setAccessibility(isElement: false)
            self.ui.tableView.accessibilityElementsHidden = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.setAccessibility(isElement: true)
            }
        }
        
        self.isInitializedWithBackButton = false
        ui.tableView.reloadData()
    }
    
    @objc func handleBackButtonPressed() {
        self.isInitializedWithBackButton = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension MyeIDInfoViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return infoManager.personalInfo.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = infoManager.personalInfo.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withType: MyeIDInfoCell.self, for: indexPath)!
            cell.infoManager = infoManager
        if item.type == .expiryDate {
            cell.populate(titleText: infoManager.personalInfo.itemTitles[item.type]!, with: item.value)
        } else {
            cell.populate(titleText: infoManager.personalInfo.itemTitles[item.type]!, contentText: item.value)
        }
        
        return cell
    }
}

extension MyeIDInfoViewController: MyeIDInfoViewControllerUIDelegate {
    func numberOfContentCells(in segment: Int) -> Int {
        switch segments[segment] {
        case .info:
            return infoManager.personalInfo.items.count
        case .changePins:
            return infoManager.pinPukCell.items.count
        case .margin:
            return 1
        }
    }
    
    func numberOfSegments() -> Int {
        return segments.count
    }
    
    func contentCell(at indexPath: IndexPath) -> UITableViewCell {
        let segment = segments[indexPath.section]
        switch segment {
        case .info:
            let item = infoManager.personalInfo.items[indexPath.row]
            let cell = ui.tableView.dequeueReusableCell(withType: MyeIDInfoCell.self, for: indexPath)!
                cell.infoManager = infoManager
            if item.type == .expiryDate {
                cell.populate(titleText: infoManager.personalInfo.itemTitles[item.type]!, with: item.value)
            } else {
                cell.populate(titleText: infoManager.personalInfo.itemTitles[item.type]!, contentText: item.value)
            }
            
            if UIAccessibility.isVoiceOverRunning && !initialLoadingComplete {
                if item.type == .myeID {
                    initialLoadingComplete = true
                    UIAccessibility.post(notification: .screenChanged, argument: cell)
                }
            }
            return cell
        case .changePins:
            let cell = ui.tableView.dequeueReusableCell(withType: MyeIDPinPukCell.self, for: indexPath)!
            cell.infoManager = infoManager
            if UIAccessibility.isVoiceOverRunning && infoManager.actionKind != nil && !isCancelMessageAnnounced {
                if (infoManager.actionKind == .changePin1 || infoManager.actionKind == .unblockPin1) && cell.kind == .pin1 {
                    cancelMessage(cell: cell)
                } else if (infoManager.actionKind == .changePin2 || infoManager.actionKind == .unblockPin2) && cell.kind == .pin2 {
                    cancelMessage(cell: cell)
                } else if infoManager.actionKind == .changePuk && cell.kind == .puk {
                    cancelMessage(cell: cell)
                }
            }
            cell.bounds = CGRect(x: 0, y: 0, width: ui.tableView.bounds.width, height: 99999)
            let pinPukCellInfo: MyeIDInfoManager.PinPukCell.Info = infoManager.pinPukCell.items[indexPath.row]
            cell.populate(pinPukCellInfo: pinPukCellInfo, shouldFocusOnElement: false)
            cell.certInfoView.accessibilityLabel = "\(pinPukCellInfo.title ?? ""). \(infoManager.certInfoAttributedString(for: pinPukCellInfo.kind)?.string ?? pinPukCellInfo.certInfoText ?? "")"
            cell.accessibilityLabel = ""
            if UIAccessibility.isVoiceOverRunning {
                if (infoManager.actionKind == .changePin1 || infoManager.actionKind == .unblockPin1) && cell.kind == .pin1 {
                    changePinCell = cell
                } else if (infoManager.actionKind == .changePin2 || infoManager.actionKind == .unblockPin2) && cell.kind == .pin2 {
                    changePinCell = cell
                } else if infoManager.actionKind == .changePuk && cell.kind == .puk {
                    changePinCell = cell
                }
            }
            return cell
        case .margin:
            return ui.tableView.dequeueReusableCell(withIdentifier: "marginCell", for: indexPath)
        }
    }
    
    func cancelMessage(cell: MyeIDPinPukCell) {
        if UIAccessibility.isVoiceOverRunning {
            let label = UILabel()
            UIAccessibility.post(notification: .screenChanged, argument: label)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.announceCancelMessage()
            }
        }
    }
    
    func segmentHeaderCell(for segment: Int, at indexPath: IndexPath) -> UITableViewCell {
        switch segments[segment] {
        case .info, .margin:
            return UITableViewCell()
        case .changePins:
            let cell = ui.tableView.dequeueReusableCell(withType: MyeIDSegmentHeaderCell.self, for: indexPath)!
            cell.accessibilityTraits = UIAccessibilityTraits.button
            return cell
        }
    }
    
    func didSelectContentCell(at row:Int, in segment:Int) {
    }
    
    func shouldShowSegmentHeader(in segment:Int) -> Bool {
        switch segments[segment] {
        case .info, .margin:
            return false
        case .changePins:
            return true
        }
    }
    
    func shouldAlwaysShowContent(in segment:Int) -> Bool {
        switch segments[segment] {
        case .info, .margin:
            return true
        case .changePins:
            return false
        }
    }
    
    func shouldScrollToTopWhenExpanding(segment:Int) -> Bool {
        return true
    }
    
    func willExpandContent(in segment:Int, segmentHeaderCell: UITableViewCell?) {
        if segments[segment] == .changePins {
            if let cell = segmentHeaderCell as? MyeIDSegmentHeaderCell {
                cell.updateExpandedState(with: true)
            }
        }
    }
    
    func willCollapseContent(in segment:Int, segmentHeaderCell: UITableViewCell?) {
        if segments[segment] == .changePins {
            if let cell = segmentHeaderCell as? MyeIDSegmentHeaderCell {
                cell.updateExpandedState(with: false)
            }
        }
    }
    
    func willDisplayContentCell(_ cell: UITableViewCell, in segment:Int, at row:Int) {
        if segments[segment] == .changePins {
            if let cell = cell as? MyeIDPinPukCell {
                cell.populateForWillDisplayCell(pinPukCellInfo: infoManager.pinPukCell.items[row])
                cell.layoutIfNeeded()
            }
        }
    }
}
