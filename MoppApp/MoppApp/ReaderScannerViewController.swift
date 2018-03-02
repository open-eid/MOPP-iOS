//
//  ReaderScannerViewController.swift
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
protocol ReaderScannerDelegate : class {
    func readerScannerDidSelectPeripheral(peripheral: CBPeripheral?)
}


class ReaderScannerViewController : MoppViewController {
    weak var delegate: ReaderScannerDelegate!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        
        CBManagerHelper.sharedInstance().startScan()
        CBManagerHelper.sharedInstance().add(self)
    }
    
    deinit {
        CBManagerHelper.sharedInstance().remove(self)
        CBManagerHelper.sharedInstance().stopScan()
    }
}

extension ReaderScannerViewController : UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section_: Int) -> Int {
        return CBManagerHelper.sharedInstance().foundPeripherals.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withType: ReaderScannerPeripheralCell.self, for: indexPath)!
            let peripheral = CBManagerHelper.sharedInstance().foundPeripherals[indexPath.row] as! CBPeripheral
            cell.populate(
                with: peripheral.name ?? "<Missing>",
                uuid: peripheral.identifier.uuidString,
                showBottomBorder: indexPath.row < (CBManagerHelper.sharedInstance().foundPeripherals.count - 1))
        return cell
    }
}

extension ReaderScannerViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate.readerScannerDidSelectPeripheral(peripheral: CBManagerHelper.sharedInstance().foundPeripherals?[indexPath.row] as? CBPeripheral)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = MoppApp.instance.nibs[.signingElements]?.instantiate(withOwner: self, type: ReaderScannerHeaderView.self)
            view?.delegate = self
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 100
    }
}

extension ReaderScannerViewController : ReaderScannerHeaderDelegate {
    func readerScannerHeaderDidTapDismiss() {
        dismiss(animated: true, completion: nil)
    }
}

extension ReaderScannerViewController : CBManagerHelperDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect didFailToConnectPeripheral:CBPeripheral, error: Error) {
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData data: [String : Any], rssi RSSI: NSNumber) {
        tableView.reloadData()
        if let name = peripheral.name {
            if name == "ACR3901U-S1" {
                print("Card ACR3901U-S1 found")
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnect peripheral: CBPeripheral, error: Error) {
        if let name = peripheral.name {
            if name == "ACR3901U-S1" {
                print("Card ACR3901U-S1 disconnected")
            }
        }
    }
}
