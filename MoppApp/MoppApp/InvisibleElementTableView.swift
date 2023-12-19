//
//  InvisibleElementTableView.swift
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

protocol InvisibleElementTableView: AnyObject {
    var isInvisibleElementAdded: Bool { get set }

    func removeDefaultElement()
    func isScrollingNecessary(tableView: UITableView) -> Bool
    func addElementNoScroll(to view: UIView)
    func addElement(to view: UIView)
    func scrollViewScrolled(_ scrollView: UIScrollView)
}

extension InvisibleElementTableView where Self: UIViewController {
    func removeDefaultElement() {
        if DefaultsHelper.isDebugMode {
            let invisibleLabel = getInvisibleLabelInView(view, accessibilityIdentifier: invisibleElementAccessibilityIdentifier)
            invisibleLabel?.removeFromSuperview()
            isInvisibleElementAdded = false
        }
    }
    
    func isScrollingNecessary(tableView: UITableView) -> Bool {
        var totalVisibleRows = 0
        var totalRows = 0
        
        for section in 0..<tableView.numberOfSections {
            let numberOfVisibleRowsInSection = tableView.indexPathsForVisibleRows?.filter { $0.section == section }.count ?? 0
            let numberOfRowsInSection = tableView.numberOfRows(inSection: section)
            
            totalVisibleRows += numberOfVisibleRowsInSection
            totalRows += numberOfRowsInSection
        }
        
        return totalRows > totalVisibleRows
    }
    
    func addElementNoScroll(to view: UIView) {
        guard let tableView = view as? UITableView else { return }
        addElement(to: view)
    }
    
    func addElement(to view: UIView) {
        let label = UIViewController.getInvisibleLabel()
        addLabelToBottom(label: label, lastSubview: view)
        isInvisibleElementAdded = true
    }

    func scrollViewScrolled(_ scrollView: UIScrollView) {
        if DefaultsHelper.isDebugMode {
            let scrollViewHeight = scrollView.frame.size.height
            let contentHeight = scrollView.contentSize.height
            let offset = scrollView.contentOffset.y
            
            if offset + scrollViewHeight >= contentHeight && !isInvisibleElementAdded {
                addElement(to: self.view)
            }
        }
    }
}
