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
        case givenNames
        case surname
        case personalCode
        case citizenship
        case documentNumber
        case expiryDate
    }
    
    var itemTitles: [ItemType: String] = [
        .givenNames: "EESNIMED",
        .surname: "PEREKONNANIMI",
        .personalCode: "ISIKUKOOD",
        .citizenship: "KODAKONDSUS",
        .documentNumber: "DOKUMENDI NUMBER",
        .expiryDate: "KEHTIV KUNI"
    ]
    
    var items: [(type: ItemType, value: String)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 62
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    func loadItems(personalData: MoppLibPersonalData?) {
        items.removeAll()
        guard let personalData = personalData else { return }
        items.append((type: .givenNames, value: personalData.givenNames()))
        items.append((type: .surname, value: personalData.surname))
        items.append((type: .personalCode, value: personalData.personalIdentificationCode))
        items.append((type: .citizenship, value: personalData.nationality))
        items.append((type: .documentNumber, value: personalData.documentNumber))
        items.append((type: .expiryDate, value: personalData.expiryDate))
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
            let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd.MM.yyyy";
            let date = dateFormatter.date(from: item.value)
            cell.populate(titleText: itemTitles[item.type]!, with: date)
        } else {
            cell.populate(titleText: itemTitles[item.type]!, contentText: item.value)
        }
        
        return cell
    }
}
