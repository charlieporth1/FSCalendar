//
//  FSCalendarCalculator.m
//  FSCalendar
//
//  Created by dingwenchao on 30/10/2016.
//  Copyright © 2016 Wenchao Ding. All rights reserved.
//

//#import "FSCalendar.h"
//#import "FSCalendarCalculator.h"
//#import "FSCalendarDynamicHeader.h"
//#import "FSCalendarExtensions.h"


class FSCalendarCalculator : NSObject {

    var calendar:FSCalendar!
    private(set) var numberOfSections:Int
    private var numberOfMonths:Int
    private var months:NSMutableDictionary!
    private var monthHeads:NSMutableDictionary!
    private var numberOfWeeks:Int
    private var weeks:NSMutableDictionary!
    private var rowCounts:NSMutableDictionary!
    private(set) var gregorian:NSCalendar!
    private(set) var minimumDate:NSDate!
    private(set) var maximumDate:NSDate!

    $(PropertyDynamicImplementation)

    init(calendar:FSCalendar!) {
        self = super.init()
        if (self != nil) {
            self.calendar = calendar

            self.months = NSMutableDictionary.dictionary()
            self.monthHeads = NSMutableDictionary.dictionary()
            self.weeks = NSMutableDictionary.dictionary()
            self.rowCounts = NSMutableDictionary.dictionary()

            NSNotificationCenter.defaultCenter().addObserver(self, selector:Selector("didReceiveNotifications:"), name:UIApplicationDidReceiveMemoryWarningNotification, object:nil)
        }
        return self
    }

    func dealloc() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationDidReceiveMemoryWarningNotification, object:nil)
    }

    func forwardingTargetForSelector(selector:SEL) -> AnyObject! {
        if self.calendar.respondsToSelector(selector) {
            return self.calendar
        }
        return super.forwardingTargetForSelector(selector)
    }

    // MARK: - Public functions

    func safeDateForDate(date:NSDate!) -> NSDate! {
        if self.gregorian.compareDate(date, toDate:self.minimumDate, toUnitGranularity:NSCalendarUnitDay) == NSOrderedAscending {
            date = self.minimumDate
        } else if self.gregorian.compareDate(date, toDate:self.maximumDate, toUnitGranularity:NSCalendarUnitDay) == NSOrderedDescending {
            date = self.maximumDate
        }
        return date
    }

    func dateForIndexPath(indexPath:NSIndexPath!, scope:FSCalendarScope) -> NSDate! {
        if (indexPath == nil) {return nil}
        switch (scope) { 
            case FSCalendarScopeMonth: 
                let head:NSDate! = self.monthHeadForSection(indexPath.section)
                let daysOffset:UInt = indexPath.item
                let date:NSDate! = self.gregorian.dateByAddingUnit(NSCalendarUnitDay, value:daysOffset, toDate:head, options:0)
                return date
                break

            case FSCalendarScopeWeek: 
                let currentPage:NSDate! = self.weekForSection(indexPath.section)
                let date:NSDate! = self.gregorian.dateByAddingUnit(NSCalendarUnitDay, value:indexPath.item, toDate:currentPage, options:0)
                return date

        }
        return nil
    }

    func dateForIndexPath(indexPath:NSIndexPath!) -> NSDate! {
        if (indexPath == nil) {return nil}
        return self.dateForIndexPath(indexPath, scope:self.calendar.transitionCoordinator.representingScope)
    }

    func indexPathForDate(date:NSDate!) -> NSIndexPath! {
        return self.indexPathForDate(date, atMonthPosition:FSCalendarMonthPositionCurrent, scope:self.calendar.transitionCoordinator.representingScope)
    }

    func indexPathForDate(date:NSDate!, scope:FSCalendarScope) -> NSIndexPath! {
        return self.indexPathForDate(date, atMonthPosition:FSCalendarMonthPositionCurrent, scope:scope)
    }

    func indexPathForDate(date:NSDate!, atMonthPosition position:FSCalendarMonthPosition, scope:FSCalendarScope) -> NSIndexPath! {
        if (date == nil) {return nil}
        var item:Int = 0
        var section:Int = 0
        switch (scope) { 
            case FSCalendarScopeMonth: 
                section = self.gregorian.components(NSCalendarUnitMonth, fromDate:self.gregorian.fs_firstDayOfMonth(self.minimumDate), toDate:self.gregorian.fs_firstDayOfMonth(date), options:0).month
                if position == FSCalendarMonthPositionPrevious {
                    section++
                } else if position == FSCalendarMonthPositionNext {
                    section--
                }
                let head:NSDate! = self.monthHeadForSection(section)
                item = self.gregorian.components(NSCalendarUnitDay, fromDate:head, toDate:date, options:0).day
                break

            case FSCalendarScopeWeek: 
                section = self.gregorian.components(NSCalendarUnitWeekOfYear, fromDate:self.gregorian.fs_firstDayOfWeek(self.minimumDate), toDate:self.gregorian.fs_firstDayOfWeek(date), options:0).weekOfYear
                item = ((self.gregorian.component(NSCalendarUnitWeekday, fromDate:date) - self.gregorian.firstWeekday) + 7) % 7
                break

        }
        if item < 0 || section < 0 {
            return nil
        }
        let indexPath:NSIndexPath! = NSIndexPath.indexPathForItem(item, inSection:section)
        return indexPath
    }

    func indexPathForDate(date:NSDate!, atMonthPosition position:FSCalendarMonthPosition) -> NSIndexPath! {
        return self.indexPathForDate(date, atMonthPosition:position, scope:self.calendar.transitionCoordinator.representingScope)
    }

    func pageForSection(section:Int) -> NSDate! {
        switch (self.calendar.transitionCoordinator.representingScope) { 
            case FSCalendarScopeWeek:
                return self.gregorian.fs_middleDayOfWeek(self.weekForSection(section))
            case FSCalendarScopeMonth:
                return self.monthForSection(section)
            default:
                break
        }
    }

    func monthForSection(section:Int) -> NSDate! {
        let key:NSNumber! = section
        var month:NSDate! = self.months[key]
        if (month == nil) {
            month = self.gregorian.dateByAddingUnit(NSCalendarUnitMonth, value:section, toDate:self.gregorian.fs_firstDayOfMonth(self.minimumDate), options:0)
            let numberOfHeadPlaceholders:Int = self.numberOfHeadPlaceholdersForMonth(month)
            let monthHead:NSDate! = self.gregorian.dateByAddingUnit(NSCalendarUnitDay, value:-numberOfHeadPlaceholders, toDate:month, options:0)
            self.months[key] = month
            self.monthHeads[key] = monthHead
        }
        return month
    }

    func monthHeadForSection(section:Int) -> NSDate! {
        let key:NSNumber! = section
        var monthHead:NSDate! = self.monthHeads[key]
        if (monthHead == nil) {
            let month:NSDate! = self.gregorian.dateByAddingUnit(NSCalendarUnitMonth, value:section, toDate:self.gregorian.fs_firstDayOfMonth(self.minimumDate), options:0)
            let numberOfHeadPlaceholders:Int = self.numberOfHeadPlaceholdersForMonth(month)
            monthHead = self.gregorian.dateByAddingUnit(NSCalendarUnitDay, value:-numberOfHeadPlaceholders, toDate:month, options:0)
            self.months[key] = month
            self.monthHeads[key] = monthHead
        }
        return monthHead
    }

    func weekForSection(section:Int) -> NSDate! {
        let key:NSNumber! = section
        var week:NSDate! = self.weeks[key]
        if (week == nil) {
            week = self.gregorian.dateByAddingUnit(NSCalendarUnitWeekOfYear, value:section, toDate:self.gregorian.fs_firstDayOfWeek(self.minimumDate), options:0)
            self.weeks[key] = week
        }
        return week
    }

    func numberOfSections() -> Int {
        switch (self.calendar.transitionCoordinator.representingScope) { 
            case FSCalendarScopeMonth: 
                return self.numberOfMonths

            case FSCalendarScopeWeek: 
                return self.numberOfWeeks

        }
    }

    func numberOfHeadPlaceholdersForMonth(month:NSDate!) -> Int {
        let currentWeekday:Int = self.gregorian.component(NSCalendarUnitWeekday, fromDate:month)
        let number:Int = ((currentWeekday- self.gregorian.firstWeekday) + 7) % 7 ?((currentWeekday- self.gregorian.firstWeekday) + 7) % 7: (7 * (!self.calendar.floatingMode&&(self.calendar.placeholderType == FSCalendarPlaceholderTypeFillSixRows)))
        return number
    }

    func numberOfRowsInMonth(month:NSDate!) -> Int {
        if (month == nil) {return 0}
        if self.calendar.placeholderType == FSCalendarPlaceholderTypeFillSixRows {return 6}

        var rowCount:NSNumber! = self.rowCounts[month]
        if (rowCount == nil) {
            let firstDayOfMonth:NSDate! = self.gregorian.fs_firstDayOfMonth(month)
            let weekdayOfFirstDay:Int = self.gregorian.component(NSCalendarUnitWeekday, fromDate:firstDayOfMonth)
            let numberOfDaysInMonth:Int = self.gregorian.fs_numberOfDaysInMonth(month)
            let numberOfPlaceholdersForPrev:Int = ((weekdayOfFirstDay - self.gregorian.firstWeekday) + 7) % 7
            let headDayCount:Int = numberOfDaysInMonth + numberOfPlaceholdersForPrev
            let numberOfRows:Int = (headDayCount/7) + (headDayCount%7>0)
            rowCount = numberOfRows
            self.rowCounts[month] = rowCount
        }
        return rowCount.integerValue
    }

    func numberOfRowsInSection(section:Int) -> Int {
        if self.calendar.transitionCoordinator.representingScope == FSCalendarScopeWeek {return 1}
        let month:NSDate! = self.monthForSection(section)
        return self.numberOfRowsInMonth(month)
    }

    func monthPositionForIndexPath(indexPath:NSIndexPath!) -> FSCalendarMonthPosition {
        if (indexPath == nil) {return FSCalendarMonthPositionNotFound}
        if self.calendar.transitionCoordinator.representingScope == FSCalendarScopeWeek {
            return FSCalendarMonthPositionCurrent
        }
        let date:NSDate! = self.dateForIndexPath(indexPath)
        let page:NSDate! = self.pageForSection(indexPath.section)
        let comparison:NSComparisonResult = self.gregorian.compareDate(date, toDate:page, toUnitGranularity:NSCalendarUnitMonth)
        switch (comparison) { 
            case NSOrderedAscending:
                return FSCalendarMonthPositionPrevious
            case NSOrderedSame:
                return FSCalendarMonthPositionCurrent
            case NSOrderedDescending:
                return FSCalendarMonthPositionNext
        }
    }

    func coordinateForIndexPath(indexPath:NSIndexPath!) -> FSCalendarCoordinate {
        var coordinate:FSCalendarCoordinate
        coordinate.row = indexPath.item / 7
        coordinate.column = indexPath.item % 7
        return coordinate
    }

    func reloadSections() {
        self.numberOfMonths = self.gregorian.components(NSCalendarUnitMonth, fromDate:self.gregorian.fs_firstDayOfMonth(self.minimumDate), toDate:self.maximumDate, options:0).month+1
        self.numberOfWeeks = self.gregorian.components(NSCalendarUnitWeekOfYear, fromDate:self.gregorian.fs_firstDayOfWeek(self.minimumDate), toDate:self.maximumDate, options:0).weekOfYear+1
        self.clearCaches()
    }

    func clearCaches() {
        self.months.removeAllObjects()
        self.monthHeads.removeAllObjects()
        self.weeks.removeAllObjects()
        self.rowCounts.removeAllObjects()
    }

    // MARK: - Private functinos

    func didReceiveNotifications(notification:NSNotification!) {
        if (notification.name == UIApplicationDidReceiveMemoryWarningNotification) {
            self.clearCaches()
        }
    }
}
