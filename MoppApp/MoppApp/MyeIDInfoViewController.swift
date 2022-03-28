//
//  MyeIDInfoViewController.swift
//  MoppApp
//
/*
 * Copyright 2017 - 2021 Riigi Infosüsteemi Amet
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
class MyeIDInfoViewController: MoppViewController {
    @IBOutlet weak var ui: MyeIDInfoViewControllerUI!
    
    weak var infoManager: MyeIDInfoManager!
    
    enum Segment {
        case info
        case changePins
        case margin
    }
    
    var segments: [Segment] = [.info, .margin, .changePins]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ui.setupOnce()
        ui.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ui.tableView.reloadData()
        UIAccessibility.post(notification: .screenChanged, argument: ui.tableView)
        // Prevent accessibility focus jumping after returning to main My eID view
        if infoManager.hasMyEidPageChanged {
            ui.tableView.accessibilityElementsHidden = true
            enableAccessibilityElements()
        }
    }
    
    func enableAccessibilityElements() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.ui.tableView.accessibilityElementsHidden = false
            self.ui.tableView.reloadData()
            self.infoManager.hasMyEidPageChanged = false
        }
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
            
            if UIAccessibility.isVoiceOverRunning {
                if item.type == .myeID {
                    UIAccessibility.post(notification: .screenChanged, argument: cell)
                }
                
                // Prevent accessibility focus jumping after returning to main My eID view
                if infoManager.hasMyEidPageChanged {
                    enableAccessibilityElements()
                }
            }
            return cell
        case .changePins:
            let cell = ui.tableView.dequeueReusableCell(withType: MyeIDPinPukCell.self, for: indexPath)!
                cell.infoManager = infoManager
                cell.bounds = CGRect(x: 0, y: 0, width: ui.tableView.bounds.width, height: 99999)
            let pinPukCellInfo: MyeIDInfoManager.PinPukCell.Info = infoManager.pinPukCell.items[indexPath.row]
                cell.populate(pinPukCellInfo: pinPukCellInfo)
                cell.certInfoView.accessibilityLabel = "\(pinPukCellInfo.title ?? ""). \(infoManager.certInfoAttributedString(for: pinPukCellInfo.kind)?.string ?? pinPukCellInfo.certInfoText ?? "")"
            cell.accessibilityLabel = ""
            if UIAccessibility.isVoiceOverRunning && infoManager.hasMyEidPageChanged {
                cell.setAccessibilityFocusOnButton()
            }
            return cell
        case .margin:
            return ui.tableView.dequeueReusableCell(withIdentifier: "marginCell", for: indexPath)
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
