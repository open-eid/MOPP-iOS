//
//  MyeIDInfoViewControllerUI.swift
//  MoppApp
//
//  MyeIDInfoViewControllerUI's responsibility is to handle IBOutlets and IBActions
//  and delegate important events to MyeIDInfoViewController.
//  It also implements collapsible UITableView component using the concept Segments
//  where each Segment consists of two UITableView sections: header section and
//  content section. Header section is used for expanding and collapsing the content
//  section.
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
protocol MyeIDInfoViewControllerUIDelegate: class {
    func numberOfContentCells(in segment: Int) -> Int
    func numberOfSegments() -> Int
    func contentCell(at indexPath: IndexPath) -> UITableViewCell
    func segmentHeaderCell(for section: Int, at indexPath: IndexPath) -> UITableViewCell
    func didSelectContentCell(at index:Int, in segment:Int)
    func shouldShowSegmentHeader(in segment:Int) -> Bool
    func shouldAlwaysShowContent(in segment:Int) -> Bool
    func shouldScrollToTopWhenExpanding(segment:Int) -> Bool
    func willExpandContent(in segment:Int, segmentHeaderCell: UITableViewCell?)
    func willCollapseContent(in segment:Int, segmentHeaderCell: UITableViewCell?)
    func willDisplayContentCell(_ cell: UITableViewCell, in segment:Int, at row:Int)
}

class MyeIDInfoViewControllerUI: NSObject {
    typealias Segment = Int

    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: MyeIDInfoViewControllerUIDelegate? = nil
    
    func setupOnce() {
        tableView.estimatedRowHeight = 260
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.contentInset = UIEdgeInsetsMake(7, 0, 0, 0)
    }
    
    var expandedSegment: Int? = nil {
        didSet {
            var sectionsToReload = IndexSet()
            var expandingSection = false
            
            if let expandedSegment = expandedSegment {
                sectionsToReload.insert(contentSection(from: expandedSegment))
                expandingSection = true
                
                let headerCell = tableView.cellForRow(at: IndexPath(row: 0, section: headerSection(from: expandedSegment)))
                delegate?.willExpandContent(in: expandedSegment, segmentHeaderCell: headerCell)
            }
            
            if let oldExpandedSegment = oldValue {
                sectionsToReload.insert(contentSection(from: oldExpandedSegment))
                
                let headerCell = tableView.cellForRow(at: IndexPath(row: 0, section: headerSection(from: oldExpandedSegment)))
                delegate?.willCollapseContent(in: oldExpandedSegment, segmentHeaderCell: headerCell)
            }
            
            if sectionsToReload.isEmpty {
                return
            }
            
            tableView.reloadSections(sectionsToReload, with: .automatic)
            
            if expandingSection && delegate?.shouldScrollToTopWhenExpanding(segment: expandedSegment!) ?? false {
                tableView.scrollToRow(at: IndexPath(row: 0, section: headerSection(from: expandedSegment!)) , at: .top, animated: true)
            }
        }
    }
    
    func toggleExpandedState(for segment: Int) {
        if let expandedSegment = expandedSegment, expandedSegment == segment {
            self.expandedSegment = nil
        } else {
            expandedSegment = segment
        }
    }
}

extension MyeIDInfoViewControllerUI: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return (delegate?.numberOfSegments() ?? 0) * 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let segment_ = segment(from: section)
        
        if isSegmentHeaderSection(from: section) {
            return delegate?.shouldShowSegmentHeader(in: segment_) ?? false ? 1 : 0
        } else {
            let numberOfContentCells = delegate?.numberOfContentCells(in: segment_) ?? 0
            if delegate?.shouldAlwaysShowContent(in: segment_) ?? false {
                return numberOfContentCells
            }
            if let expandedSegment = expandedSegment, expandedSegment == segment_ {
                return numberOfContentCells
            }
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isSegmentHeaderSection(from: indexPath) {
            return delegate?.segmentHeaderCell(for: segment(from: indexPath), at: indexPath) ?? UITableViewCell()
        }
        return delegate?.contentCell(at: IndexPath(row: indexPath.row, section: segment(from: indexPath))) ?? UITableViewCell()
    }
}

extension MyeIDInfoViewControllerUI: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSegmentHeaderSection(from: indexPath) {
            if delegate?.shouldAlwaysShowContent(in: segment(from: indexPath)) ?? false {
                return
            }
            toggleExpandedState(for: segment(from: indexPath))
        } else {
            delegate?.didSelectContentCell(at: indexPath.row, in: segment(from: indexPath))
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !isSegmentHeaderSection(from: indexPath) {
            delegate?.willDisplayContentCell(cell, in: segment(from: indexPath), at: indexPath.row)
        }
    }
}

extension MyeIDInfoViewControllerUI {
    func segment(from section: Int) -> Segment {
        return section / 2
    }

    func isSegmentHeaderSection(from section: Int) -> Bool {
        return section % 2 == 0
    }

    func headerSection(from segment: Segment) -> Int {
        return segment * 2
    }
    
    func contentSection(from segment: Segment) -> Int {
        return segment * 2 + 1
    }
    
    func isSegmentHeaderSection(from indexPath: IndexPath) -> Bool {
        return isSegmentHeaderSection(from: indexPath.section)
    }
    
    func segment(from indexPath: IndexPath) -> Segment {
        return segment(from: indexPath.section)
    }
}
