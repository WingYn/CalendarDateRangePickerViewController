//
//  CalendarDateRangePickerViewController.swift
//  CalendarDateRangePickerViewController
//
//  Created by Miraan on 15/10/2017.
//  Copyright © 2017 Miraan. All rights reserved.
//

import UIKit

public protocol CalendarDateRangePickerViewControllerDelegate {
    func didCancelPickingDateRange()
    func didPickDateRange(startDate: Date!, endDate: Date!)
}

public class CalendarDateRangePickerViewController: UICollectionViewController {
    
    let cellReuseIdentifier = "CalendarDateRangePickerCell"
    let headerReuseIdentifier = "CalendarDateRangePickerHeaderView"
    
    public var delegate: CalendarDateRangePickerViewControllerDelegate!
    
    let itemsPerRow = 6
    let itemHeight: CGFloat = 60
    let collectionViewInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    
    public var minimumDate: Date!
    public var maximumDate: Date!
    
    public var selectedStartDate: Date?
    public var selectedEndDate: Date?
    
    public var selectedColor = UIColor(red: 66/255.0, green: 150/255.0, blue: 240/255.0, alpha: 1.0)
    public var titleText = "Select Dates"

    var calendar = Calendar.current
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.titleText
        
        collectionView?.dataSource = self
        collectionView?.delegate = self
        collectionView?.backgroundColor = UIColor.white

        collectionView?.register(CalendarDateRangePickerCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        collectionView?.register(CalendarDateRangePickerHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
        collectionView?.contentInset = collectionViewInsets
        
        if let timeZone = TimeZone(identifier: "UTC") {
            calendar.timeZone = timeZone
        }

        if minimumDate == nil {
            minimumDate = calendar.date(byAdding: .year, value: -1, to: Date())
        }
        
        if maximumDate == nil {
            maximumDate = calendar.date(byAdding: .year, value: 2, to: minimumDate)
        }
        
        self.navigationItem.rightBarButtonItem?.isEnabled = selectedStartDate != nil && selectedEndDate != nil
    }
    
    public func didTapCancel() {
        delegate.didCancelPickingDateRange()
    }
    
    public func didTapDone() {
        if let selectedEndDate = selectedEndDate {
            self.selectedEndDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: selectedEndDate)
        }
        
        delegate.didPickDateRange(startDate: selectedStartDate, endDate: selectedEndDate)
    }
    
}

extension CalendarDateRangePickerViewController {
    
    // UICollectionViewDataSource
    
    override public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    override public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12
    }
    
    override public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! CalendarDateRangePickerCell
        cell.selectedColor = self.selectedColor
        cell.reset()

        let dayOfMonth = indexPath.item

        let date = getDate(month: dayOfMonth + 1, section: indexPath.section)
    
        cell.date = date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "LLL"
        let nameOfMonth = dateFormatter.string(from: date)
        
        cell.label.text = nameOfMonth
        
        if selectedStartDate != nil && selectedEndDate != nil && isBefore(dateA: selectedStartDate!, dateB: date) && isBefore(dateA: date, dateB: selectedEndDate!) {
            // Cell falls within selected range
            if dayOfMonth == getNumberOfDaysInMonth(date: date) {
                cell.highlightLeft()
            } else {
                cell.highlight()
            }
        } else if selectedStartDate != nil && areSameDay(dateA: date, dateB: selectedStartDate!) {
            // Cell is selected start date
            cell.select()
            if selectedEndDate != nil {
                cell.highlightRight()
            }
        } else if selectedEndDate != nil && areSameDay(dateA: date, dateB: selectedEndDate!) {
            cell.select()
            cell.highlightLeft()
        }
        return cell
    }
    
    override public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! CalendarDateRangePickerHeaderView
            headerView.label.text = getMonthLabel(date: getFirstDateForSection(section: indexPath.section))
            return headerView
        default:
            fatalError("Unexpected element kind")
        }
    }
    
}

extension CalendarDateRangePickerViewController : UICollectionViewDelegateFlowLayout {
    
    override public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! CalendarDateRangePickerCell
        if cell.date == nil {
            return
        }

        if selectedStartDate == nil {
            selectedStartDate = cell.date
        } else if selectedEndDate == nil {
            if isBefore(dateA: selectedStartDate!, dateB: cell.date!) {
                selectedEndDate = cell.date
                self.navigationItem.rightBarButtonItem?.isEnabled = true
            } else {
                // If a cell before the currently selected start date is selected then just set it as the new start date
                selectedStartDate = cell.date
            }
        } else {
            selectedStartDate = cell.date
            selectedEndDate = nil
        }
        collectionView.reloadData()
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding = collectionViewInsets.left + collectionViewInsets.right
        let availableWidth = view.frame.width - padding
        let itemWidth = availableWidth / CGFloat(itemsPerRow)
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.size.width, height: 50)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}

extension CalendarDateRangePickerViewController {
    
    // Helper functions
    
    func getFirstDate() -> Date {
        var components = calendar.dateComponents([.day, .month, .year], from: minimumDate)
        components.day = 1
        return calendar.date(from: components)!
    }
    
    func getFirstDateForSection(section: Int) -> Date {
        return calendar.date(byAdding: .year, value: section, to: getFirstDate())!
    }
    
    func getMonthLabel(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter.string(from: date)
    }
    
    func getWeekdayLabel(weekday: Int) -> String {
        var components = DateComponents()
        components.calendar = calendar
        components.weekday = weekday
        let date = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .strict)
        if date == nil {
            return "E"
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEEE"
        return dateFormatter.string(from: date!)
    }
    
    func getNumberOfDaysInMonth(date: Date) -> Int {
        return calendar.range(of: .day, in: .month, for: date)!.count
    }
    
    func getDate(month: Int, section: Int) -> Date {
        var components = calendar.dateComponents([.month, .year], from: getFirstDateForSection(section: section))
        components.month = month
        return calendar.date(from: components)!
    }
    
    func areSameDay(dateA: Date, dateB: Date) -> Bool {
        return calendar.compare(dateA, to: dateB, toGranularity: .day) == .orderedSame
    }
    
    func isBefore(dateA: Date, dateB: Date) -> Bool {
        return calendar.compare(dateA, to: dateB, toGranularity: .month) == .orderedAscending
    }
    
}
