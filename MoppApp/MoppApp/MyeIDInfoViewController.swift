//
//  MyeIDInfoViewController.swift
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
class MyeIDInfoViewController: MoppViewController {
    @IBOutlet weak var tableView: UITableView!
    
    enum ItemType {
        case myeID
        case givenNames
        case surname
        case personalCode
        case citizenship
        case documentNumber
        case expiryDate
    }
    
    var itemTitles: [ItemType: String] = [
        .myeID:         L(.myEidInfoMyEid),
        .givenNames:    L(.myEidInfoItemGivenNames),
        .surname:       L(.myEidInfoItemSurname),
        .personalCode:  L(.myEidInfoItemPersonalCode),
        .citizenship:   L(.myEidInfoItemCitizenship),
        .documentNumber: L(.myEidInfoItemDocumentNumber),
        .expiryDate:    L(.myEidInfoItemExpiryDate)
    ]
    
    var items: [(type: ItemType, value: String)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 62
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.contentInset = UIEdgeInsetsMake(7, 0, 0, 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    func loadItems(personalData: MoppLibPersonalData?, authCertData: MoppLibCertData?) {
        items.removeAll()
        guard let personalData = personalData else { return }
        let certOrganization = authCertData?.organization ?? MoppLibCertOrganization.Unknown
        items.append((type: .myeID, value: organizationDisplayString(certOrganization)))
        items.append((type: .givenNames, value: personalData.givenNames()))
        items.append((type: .surname, value: personalData.surname))
        items.append((type: .personalCode, value: personalData.personalIdentificationCode))
        items.append((type: .citizenship, value: personalData.nationality))
        items.append((type: .documentNumber, value: personalData.documentNumber))
        items.append((type: .expiryDate, value: personalData.expiryDate))
    }
    
    func organizationDisplayString(_ certOrganization: MoppLibCertOrganization) -> String {
        switch certOrganization {
        case .IDCard:
            return L(.myEidInfoMyEidIdCard)
        case .DigiID:
            return L(.myEidInfoMyEidDigiId)
        case .MobileID:
            return L(.myEidInfoMyEidMobileId)
        case .EResident:
            return L(.myEidInfoMyEidEResident)
        case .Unknown:
            return L(.myEidInfoMyEidUnknown)
        }
    }
}

extension MyeIDInfoViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withType: MyeIDInfoCell.self, for: indexPath)!
        if item.type == .expiryDate {
            cell.populate(titleText: itemTitles[item.type]!, with: item.value)
        } else {
            cell.populate(titleText: itemTitles[item.type]!, contentText: item.value)
        }
        
        return cell
    }
}
