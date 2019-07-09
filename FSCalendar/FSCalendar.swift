//
//  FSCalendar.m
//  FSCalendar
//
//  Created by Wenchao Ding on 29/1/15.
//  Copyright © 2016 Wenchao Ding. All rights reserved.
//

//#import "FSCalendar.h"
//#import "FSCalendarHeaderView.h"
//#import "FSCalendarWeekdayView.h"
//#import "FSCalendarStickyHeader.h"
//#import "FSCalendarCollectionViewLayout.h"

//#import "FSCalendarExtensions.h"
//#import "FSCalendarDynamicHeader.h"
//#import "FSCalendarCollectionView.h"
//#import "FSCalendarTransitionCoordinator.h"
//#import "FSCalendarCalculator.h"
//#import "FSCalendarDelegationFactory.h"


func FSCalendarAssertDateInBounds(date:NSDate, calendar:NSCalendar, minimumDate:NSDate, maximumDate:NSDate) {
    var valid:Bool = true
    let minOffset:Int = calendar.components(NSCalendarUnitDay, fromDate:minimumDate, toDate:date, options:0).day
    valid &= minOffset >= 0
    if valid {
        let maxOffset:Int = calendar.components(NSCalendarUnitDay, fromDate:maximumDate, toDate:date, options:0).day
        valid &= maxOffset <= 0
    }
    if !valid {
        let formatter:NSDateFormatter = NSDateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        NSException.raise("FSCalendar date out of bounds exception", format:"Target date %@ beyond bounds [%@ - %@]", formatter.stringFromDate(date), formatter.stringFromDate(minimumDate), formatter.stringFromDate(maximumDate))
    }
}


enum FSCalendarOrientation:UInt {
    case Landscape
    case Portrait
}


class FSCalendar : UICollectionViewDataSource, UICollectionViewDelegate, FSCalendarCollectionViewInternalDelegate, UIGestureRecognizerDelegate {

    private var _selectedDates:NSMutableArray!
    private var _collectionView:FSCalendarCollectionView!
    var collectionView:FSCalendarCollectionView! {
        get { return _collectionView }
    }
    private var _collectionViewLayout:FSCalendarCollectionViewLayout!
    var collectionViewLayout:FSCalendarCollectionViewLayout! {
        get { return _collectionViewLayout }
    }
    private var _transitionCoordinator:FSCalendarTransitionCoordinator!
    var transitionCoordinator:FSCalendarTransitionCoordinator! {
        get { return _transitionCoordinator }
    }
    private(set) var calculator:FSCalendarCalculator!
    private(set) var floatingMode:Bool
    private(set) var visibleStickyHeaders:[AnyObject]!
    private var _preferredHeaderHeight:CGFloat
    var preferredHeaderHeight:CGFloat {
        get { 
            if _headerHeight == FSCalendarAutomaticDimension {
                if _preferredWeekdayHeight == FSCalendarAutomaticDimension {
                    if !self.floatingMode {
                        let DIYider:CGFloat = FSCalendarStandardMonthlyPageHeight
                        let contentHeight:CGFloat = self.transitionCoordinator.cachedMonthSize.height
                        _preferredHeaderHeight = (FSCalendarStandardHeaderHeight/DIYider)*contentHeight
                        _preferredHeaderHeight -= (_preferredHeaderHeight-FSCalendarStandardHeaderHeight)*0.5
                    } else {
                        _preferredHeaderHeight = FSCalendarStandardHeaderHeight*max(1, FSCalendarDeviceIsIPad*1.5)
                    }
                }
                return _preferredHeaderHeight
            }
            return _headerHeight
        }
    }
    private var _preferredWeekdayHeight:CGFloat
    var preferredWeekdayHeight:CGFloat {
        get { 
            if _weekdayHeight == FSCalendarAutomaticDimension {
                if _preferredWeekdayHeight == FSCalendarAutomaticDimension {
                    if !self.floatingMode {
                        let DIYider:CGFloat = FSCalendarStandardMonthlyPageHeight
                        let contentHeight:CGFloat = self.transitionCoordinator.cachedMonthSize.height
                        _preferredWeekdayHeight = (FSCalendarStandardWeekdayHeight/DIYider)*contentHeight
                    } else {
                        _preferredWeekdayHeight = FSCalendarStandardWeekdayHeight*max(1, FSCalendarDeviceIsIPad*1.5)
                    }
                }
                return _preferredWeekdayHeight
            }
            return _weekdayHeight
        }
    }
    private(set) var bottomBorder:UIView!
    private var _gregorian:NSCalendar!
    var gregorian:NSCalendar! {
        get { return _gregorian }
    }
    private var _formatter:NSDateFormatter!
    var formatter:NSDateFormatter! {
        get { return _formatter }
    }
    private var _contentView:UIView!
    var contentView:UIView! {
        get { return _contentView }
    }
    private var _daysContainer:UIView!
    var daysContainer:UIView! {
        get { return _daysContainer }
    }
    private var _needsAdjustingViewFrame:Bool
    var needsAdjustingViewFrame:Bool {
        get { return _needsAdjustingViewFrame }
        set { _needsAdjustingViewFrame = newValue }
    }
    private var _timeZone:NSTimeZone!
    private var timeZone:NSTimeZone! {
        get { return _timeZone }
        set { _timeZone = newValue }
    }
    private var _deliver:FSCalendarHeaderTouchDeliver!
    private var deliver:FSCalendarHeaderTouchDeliver! {
        get { return _deliver }
        set { _deliver = newValue }
    }
    private var _needsRequestingBoundingDates:Bool
    private var needsRequestingBoundingDates:Bool {
        get { return _needsRequestingBoundingDates }
        set { _needsRequestingBoundingDates = newValue }
    }
    private var _preferredRowHeight:CGFloat
    private var preferredRowHeight:CGFloat {
        get { 
            if _preferredRowHeight == FSCalendarAutomaticDimension {
                let headerHeight:CGFloat = self.preferredHeaderHeight
                let weekdayHeight:CGFloat = self.preferredWeekdayHeight
                let contentHeight:CGFloat = self.transitionCoordinator.cachedMonthSize.height-headerHeight-weekdayHeight
                let padding:CGFloat = 5
                if !self.floatingMode {
                    _preferredRowHeight = (contentHeight-padding*2)/6.0
                } else {
                    _preferredRowHeight = _rowHeight
                }
            }
            return _preferredRowHeight
        }
        set { _preferredRowHeight = newValue }
    }
    private var _orientation:FSCalendarOrientation
    private var orientation:FSCalendarOrientation {
        get { return _orientation }
        set(orientation) { 
            if _orientation != orientation {
                _orientation = orientation

                _needsAdjustingViewFrame = true
                _preferredWeekdayHeight = FSCalendarAutomaticDimension
                _preferredRowHeight = FSCalendarAutomaticDimension
                _preferredHeaderHeight = FSCalendarAutomaticDimension
                self.setNeedsLayout()
            }
        }
    }
    private var didLayoutOperations:NSMutableArray!
    private(set) var hasValidateVisibleLayout:Bool
    private(set) var currentCalendarOrientation:FSCalendarOrientation
    private var _dataSourceProxy:FSCalendarDelegationProxy!
    private var dataSourceProxy:FSCalendarDelegationProxy! {
        get { return _dataSourceProxy }
        set { _dataSourceProxy = newValue }
    }
    private var _delegateProxy:FSCalendarDelegationProxy!
    private var delegateProxy:FSCalendarDelegationProxy! {
        get { return _delegateProxy }
        set { _delegateProxy = newValue }
    }
    private var lastPressedIndexPath:NSIndexPath!
    private var _visibleSectionHeaders:NSMapTable!
    private var visibleSectionHeaders:NSMapTable! {
        get { return _visibleSectionHeaders }
        set { _visibleSectionHeaders = newValue }
    }

    $(PropertyDynamicImplementation)


    // MARK: - Life Cycle && Initialize

    init(frame:CGRect) {
        self = super.init(frame:frame)
        if (self != nil) {
            self.initialize()
        }
        return self
    }

    init(aDecoder:NSCoder!) {
        self = super.init(coder:aDecoder)
        if (self != nil) {
            self.initialize()
        }
        return self
    }

    func initialize() {   
        _appearance = FSCalendarAppearance()
        _appearance.calendar = self

        _gregorian = NSCalendar(calendarIdentifier:NSCalendarIdentifierGregorian)
        _formatter = NSDateFormatter()
        _formatter.dateFormat = "yyyy-MM-dd"
        _locale = NSLocale.currentLocale()
        _timeZone = NSTimeZone.localTimeZone()
        _firstWeekday = 1
        self.invalidateDateTools()

        _today = self.gregorian.dateBySettingHour(0, minute:0, second:0, ofDate:NSDate.date(), options:0)
        _currentPage = self.gregorian.fs_firstDayOfMonth(_today)


        _minimumDate = self.formatter.dateFromString("1970-01-01")
        _maximumDate = self.formatter.dateFromString("2099-12-31")

        _headerHeight     = FSCalendarAutomaticDimension
        _weekdayHeight    = FSCalendarAutomaticDimension
        _rowHeight        = FSCalendarStandardRowHeight*max(1, FSCalendarDeviceIsIPad*1.5)

        _preferredHeaderHeight  = FSCalendarAutomaticDimension
        _preferredWeekdayHeight = FSCalendarAutomaticDimension
        _preferredRowHeight     = FSCalendarAutomaticDimension

        _scrollDirection = FSCalendarScrollDirectionHorizontal
        _scope = FSCalendarScopeMonth
        _selectedDates = NSMutableArray.arrayWithCapacity(1)
        _visibleSectionHeaders = NSMapTable.weakToWeakObjectsMapTable()

        _pagingEnabled = true
        _scrollEnabled = true
        _needsAdjustingViewFrame = true
        _needsRequestingBoundingDates = true
        _orientation = self.currentCalendarOrientation
        _placeholderType = FSCalendarPlaceholderTypeFillSixRows

        _dataSourceProxy = FSCalendarDelegationFactory.dataSourceProxy()
        _delegateProxy = FSCalendarDelegationFactory.delegateProxy()

        self.didLayoutOperations = NSMutableArray.array

        let contentView:UIView! = UIView(frame:CGRectZero)
        contentView.backgroundColor = UIColor.clearColor
        contentView.clipsToBounds = true
        self.addSubview(contentView)
        self.contentView = contentView

        let daysContainer:UIView! = UIView(frame:CGRectZero)
        daysContainer.backgroundColor = UIColor.clearColor
        daysContainer.clipsToBounds = true
        contentView.addSubview(daysContainer)
        self.daysContainer = daysContainer

        let collectionViewLayout:FSCalendarCollectionViewLayout! = FSCalendarCollectionViewLayout()
        collectionViewLayout.calendar = self

        let collectionView:FSCalendarCollectionView! = FSCalendarCollectionView(frame:CGRectZero,
                                                                              collectionViewLayout:collectionViewLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.internalDelegate = self
        collectionView.backgroundColor = UIColor.clearColor
        collectionView.pagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.allowsMultipleSelection = false
        collectionView.clipsToBounds = true
        collectionView.registerClass(FSCalendarCell.self, forCellWithReuseIdentifier:FSCalendarDefaultCellReuseIdentifier)
        collectionView.registerClass(FSCalendarBlankCell.self, forCellWithReuseIdentifier:FSCalendarBlankCellReuseIdentifier)
        collectionView.registerClass(FSCalendarStickyHeader.self, forSupplementaryViewOfKind:UICollectionElementKindSectionHeader, withReuseIdentifier:"header")
        collectionView.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind:UICollectionElementKindSectionHeader, withReuseIdentifier:"placeholderHeader")
        daysContainer.addSubview(collectionView)
        self.collectionView = collectionView
        self.collectionViewLayout = collectionViewLayout

        self.invalidateLayout()

        // Assistants
        self.transitionCoordinator = FSCalendarTransitionCoordinator(calendar:self)
        self.calculator = FSCalendarCalculator(calendar:self)

        NSNotificationCenter.defaultCenter().addObserver(self, selector:Selector("orientationDidChange:"), name:UIDeviceOrientationDidChangeNotification, object:nil)

    }

    func dealloc() {
        self.collectionView.delegate = nil
        self.collectionView.dataSource = nil

        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIDeviceOrientationDidChangeNotification, object:nil)
    }

    // MARK: - Overriden methods

    func setBounds(bounds:CGRect) {
        super.bounds = bounds
        if !CGRectIsEmpty(bounds) && self.transitionCoordinator.state == FSCalendarTransitionState.Idle {
            self.invalidateViewFrames()
        }
    }

    func setFrame(frame:CGRect) {
        super.frame = frame
        if !CGRectIsEmpty(frame) && self.transitionCoordinator.state == FSCalendarTransitionState.Idle {
            self.invalidateViewFrames()
        }
    }

    func setValue(value:AnyObject!, forUndefinedKey key:String!) {
#if !TARGET_INTERFACE_BUILDER
        if key.hasPrefix("fake") {
            return
        }
#endif
        if key.length {
            let setter:String! = String(format:"set%@%@:",key.substringToIndex(1).uppercaseString,key.substringFromIndex(1))
            let selector:SEL = NSSelectorFromString(setter)
            if self.appearance.respondsToSelector(selector) {
                return self.appearance.setValue(value, forKey:key)
            } else if self.collectionViewLayout.respondsToSelector(selector) {
                return self.collectionViewLayout.setValue(value, forKey:key)
            }
        }

        return super.setValue(value, forUndefinedKey:key)

    }

    func layoutSubviews() {
        super.layoutSubviews()

        if _needsAdjustingViewFrame {
            _needsAdjustingViewFrame = false

            if CGSizeEqualToSize(_transitionCoordinator.cachedMonthSize, CGSizeZero) {
                _transitionCoordinator.cachedMonthSize = self.frame.size
            }

            _contentView.frame = self.bounds
            let headerHeight:CGFloat = self.preferredHeaderHeight
            let weekdayHeight:CGFloat = self.preferredWeekdayHeight
            var rowHeight:CGFloat = self.preferredRowHeight
            let padding:CGFloat = 5
            if self.scrollDirection == UICollectionViewScrollDirectionHorizontal {
                rowHeight = FSCalendarFloor(rowHeight*2)*0.5 // Round to nearest multiple of 0.5. e.g. (16.8->16.5),(16.2->16.0)
            }

            self.calendarHeaderView.frame = CGRectMake(0, 0, self.fs_width, headerHeight)
            self.calendarWeekdayView.frame = CGRectMake(0, self.calendarHeaderView.fs_bottom, self.contentView.fs_width, weekdayHeight)

            _deliver.frame = CGRectMake(self.calendarHeaderView.fs_left, self.calendarHeaderView.fs_top, self.calendarHeaderView.fs_width, headerHeight+weekdayHeight)
            _deliver.hidden = self.calendarHeaderView.hidden
            if !self.floatingMode {
                switch (self.transitionCoordinator.representingScope) { 
                    case FSCalendarScopeMonth: 
                        let contentHeight:CGFloat = rowHeight*6 + padding*2
                        _daysContainer.frame = CGRectMake(0, headerHeight+weekdayHeight, self.fs_width, contentHeight)
                        _collectionView.frame = CGRectMake(0, 0, _daysContainer.fs_width, contentHeight)
                        break

                    case FSCalendarScopeWeek: 
                        let contentHeight:CGFloat = rowHeight + padding*2
                        _daysContainer.frame = CGRectMake(0, headerHeight+weekdayHeight, self.fs_width, contentHeight)
                        _collectionView.frame = CGRectMake(0, 0, _daysContainer.fs_width, contentHeight)
                        break

                }
            } else {

                let contentHeight:CGFloat = _contentView.fs_height
                _daysContainer.frame = CGRectMake(0, 0, self.fs_width, contentHeight)
                _collectionView.frame = _daysContainer.bounds

            }
            _collectionView.fs_height = FSCalendarHalfFloor(_collectionView.fs_height)
        }

    }

#if TARGET_INTERFACE_BUILDER
    func prepareForInterfaceBuilder() {
        let date:NSDate! = NSDate.date()
        let components:NSDateComponents! = self.gregorian.components(NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay, fromDate:date)
        components.day = _appearance.fakedSelectedDay?_appearance.fakedSelectedDay:1
        _selectedDates.addObject(self.gregorian.dateFromComponents(components))
        self.collectionView.reloadData()
    }
#endif

    func sizeThatFits(size:CGSize) -> CGSize {
        return self.sizeThatFits(size, scope:self.transitionCoordinator.representingScope)
    }

    func sizeThatFits(size:CGSize, scope:FSCalendarScope) -> CGSize {
        let headerHeight:CGFloat = self.preferredHeaderHeight
        let weekdayHeight:CGFloat = self.preferredWeekdayHeight
        let rowHeight:CGFloat = self.preferredRowHeight
        let paddings:CGFloat = self.collectionViewLayout.sectionInsets.top + self.collectionViewLayout.sectionInsets.bottom

        if !self.floatingMode {
            switch (scope) { 
                case FSCalendarScopeMonth: 
                    let height:CGFloat = weekdayHeight + headerHeight + self.calculator.numberOfRowsInMonth(_currentPage)*rowHeight + paddings
                    return CGSizeMake(size.width, height)

                case FSCalendarScopeWeek: 
                    let height:CGFloat = weekdayHeight + headerHeight + rowHeight + paddings
                    return CGSizeMake(size.width, height)

            }
        } else {
            return CGSizeMake(size.width, self.fs_height)
        }
        return size
    }

    // MARK: - <UICollectionViewDataSource>

    func numberOfSectionsInCollectionView(collectionView:UICollectionView!) -> Int {
        self.requestBoundingDatesIfNecessary()
        return self.calculator.numberOfSections
    }

    func collectionView(collectionView:UICollectionView!, numberOfItemsInSection section:Int) -> Int {
        if self.floatingMode {
            let numberOfRows:Int = self.calculator.numberOfRowsInSection(section)
            return numberOfRows * 7
        }
        switch (self.transitionCoordinator.representingScope) { 
            case FSCalendarScopeMonth: 
                return 42

            case FSCalendarScopeWeek: 
                return 7

        }
        return 7
    }

    func collectionView(collectionView:UICollectionView!, cellForItemAtIndexPath indexPath:NSIndexPath!) -> UICollectionViewCell! {
        let monthPosition:FSCalendarMonthPosition = self.calculator.monthPositionForIndexPath(indexPath)

        switch (self.placeholderType) { 
            case FSCalendarPlaceholderTypeNone: 
                if self.transitionCoordinator.representingScope == FSCalendarScopeMonth && monthPosition != FSCalendarMonthPositionCurrent {
                    return collectionView.dequeueReusableCellWithReuseIdentifier(FSCalendarBlankCellReuseIdentifier, forIndexPath:indexPath)
                }
                break

            case FSCalendarPlaceholderTypeFillHeadTail: 
                if self.transitionCoordinator.representingScope == FSCalendarScopeMonth {
                    if indexPath.item >= 7 * self.calculator.numberOfRowsInSection(indexPath.section) {
                        return collectionView.dequeueReusableCellWithReuseIdentifier(FSCalendarBlankCellReuseIdentifier, forIndexPath:indexPath)
                    }
                }
                break

            case FSCalendarPlaceholderTypeFillSixRows: 
                break

        }

        let date:NSDate! = self.calculator.dateForIndexPath(indexPath)
        var cell:FSCalendarCell! = self.dataSourceProxy.calendar(self, cellForDate:date, atMonthPosition:monthPosition)
        if (cell == nil) {
            cell = self.collectionView.dequeueReusableCellWithReuseIdentifier(FSCalendarDefaultCellReuseIdentifier, forIndexPath:indexPath)
        }
        self.reloadDataForCell(cell, atIndexPath:indexPath)
        return cell
    }

    func collectionView(collectionView:UICollectionView!, viewForSupplementaryElementOfKind kind:String!, atIndexPath indexPath:NSIndexPath!) -> UICollectionReusableView! {
        if self.floatingMode {
            if (kind == UICollectionElementKindSectionHeader) {
                let stickyHeader:FSCalendarStickyHeader! = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier:"header", forIndexPath:indexPath)
                stickyHeader.calendar = self
                stickyHeader.month = self.gregorian.dateByAddingUnit(NSCalendarUnitMonth, value:indexPath.section, toDate:self.gregorian.fs_firstDayOfMonth(_minimumDate), options:0)
                self.visibleSectionHeaders[indexPath] = stickyHeader
                stickyHeader.setNeedsLayout()
                return stickyHeader
            }
        }
        return collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier:"placeholderHeader", forIndexPath:indexPath)
    }

    func collectionView(collectionView:UICollectionView!, didEndDisplayingSupplementaryView view:UICollectionReusableView!, forElementOfKind elementKind:String!, atIndexPath indexPath:NSIndexPath!) {
        if self.floatingMode {
            if (elementKind == UICollectionElementKindSectionHeader) {
                self.visibleSectionHeaders[indexPath] = nil
            }
        }
    }

    // MARK: - <UICollectionViewDelegate>

    func collectionView(collectionView:UICollectionView!, shouldSelectItemAtIndexPath indexPath:NSIndexPath!) -> Bool {
        let monthPosition:FSCalendarMonthPosition = self.calculator.monthPositionForIndexPath(indexPath)
        if self.placeholderType == FSCalendarPlaceholderTypeNone && monthPosition != FSCalendarMonthPositionCurrent {
            return false
        }
        let date:NSDate! = self.calculator.dateForIndexPath(indexPath)
        return self.isDateInRange(date) && (!self.delegateProxy.respondsToSelector(Selector("calendar:shouldSelectDate:atMonthPosition:")) || self.delegateProxy.calendar(self, shouldSelectDate:date, atMonthPosition:monthPosition))
    }

    func collectionView(collectionView:UICollectionView!, didSelectItemAtIndexPath indexPath:NSIndexPath!) {
        let selectedDate:NSDate! = self.calculator.dateForIndexPath(indexPath)
        let monthPosition:FSCalendarMonthPosition = self.calculator.monthPositionForIndexPath(indexPath)
        var cell:FSCalendarCell!
        if monthPosition == FSCalendarMonthPositionCurrent {
            cell = (collectionView.cellForItemAtIndexPath(indexPath) as! FSCalendarCell)
        } else {
            cell = self.cellForDate(selectedDate, atMonthPosition:FSCalendarMonthPositionCurrent)
            let indexPath:NSIndexPath! = collectionView.indexPathForCell(cell)
            if (indexPath != nil) {
                collectionView.selectItemAtIndexPath(indexPath, animated:false, scrollPosition:UICollectionViewScrollPositionNone)
            }
        }
        if !_selectedDates.containsObject(selectedDate) {
            cell.selected = true
            cell.performSelecting()
        }
        self.enqueueSelectedDate(selectedDate)
        self.delegateProxy.calendar(self, didSelectDate:selectedDate, atMonthPosition:monthPosition)
        self.selectCounterpartDate(selectedDate)
    }

    func collectionView(collectionView:UICollectionView!, shouldDeselectItemAtIndexPath indexPath:NSIndexPath!) -> Bool {
        let monthPosition:FSCalendarMonthPosition = self.calculator.monthPositionForIndexPath(indexPath)
        if self.placeholderType == FSCalendarPlaceholderTypeNone && monthPosition != FSCalendarMonthPositionCurrent {
            return false
        }
        let date:NSDate! = self.calculator.dateForIndexPath(indexPath)
        return self.isDateInRange(date) && (!self.delegateProxy.respondsToSelector(Selector("calendar:shouldDeselectDate:atMonthPosition:"))||self.delegateProxy.calendar(self, shouldDeselectDate:date, atMonthPosition:monthPosition))
    }

    func collectionView(collectionView:UICollectionView!, didDeselectItemAtIndexPath indexPath:NSIndexPath!) {
        let selectedDate:NSDate! = self.calculator.dateForIndexPath(indexPath)
        let monthPosition:FSCalendarMonthPosition = self.calculator.monthPositionForIndexPath(indexPath)
        var cell:FSCalendarCell!
        if monthPosition == FSCalendarMonthPositionCurrent {
            cell = (collectionView.cellForItemAtIndexPath(indexPath) as! FSCalendarCell)
        } else {
            cell = self.cellForDate(selectedDate, atMonthPosition:FSCalendarMonthPositionCurrent)
            let indexPath:NSIndexPath! = collectionView.indexPathForCell(cell)
            if (indexPath != nil) {
                collectionView.deselectItemAtIndexPath(indexPath, animated:false)
            }
        }
        cell.selected = false
        cell.configureAppearance()

        _selectedDates.removeObject(selectedDate)
        self.delegateProxy.calendar(self, didDeselectDate:selectedDate, atMonthPosition:monthPosition)
        self.deselectCounterpartDate(selectedDate)

    }

    func collectionView(collectionView:UICollectionView!, willDisplayCell cell:UICollectionViewCell!, forItemAtIndexPath indexPath:NSIndexPath!) {
        if !(cell is FSCalendarCell) {
            return
        }
        let date:NSDate! = self.calculator.dateForIndexPath(indexPath)
        let monthPosition:FSCalendarMonthPosition = self.calculator.monthPositionForIndexPath(indexPath)
        self.delegateProxy.calendar(self, willDisplayCell:(cell as! FSCalendarCell), forDate:date, atMonthPosition:monthPosition)
    }

    func collectionViewDidFinishLayoutSubviews(collectionView:FSCalendarCollectionView!) {
        self.executePendingOperationsIfNeeded()
    }

    // MARK: - <UIScrollViewDelegate>

    func scrollViewDidScroll(scrollView:UIScrollView!) {
        if !self.window {return}
        if self.floatingMode && _collectionView.indexPathsForVisibleItems.count {
            // Do nothing on bouncing
            if _collectionView.contentOffset.y < 0 || _collectionView.contentOffset.y > _collectionView.contentSize.height-_collectionView.fs_height {
                return
            }
            var currentPage:NSDate! = _currentPage
            let significantPoint:CGPoint = CGPointMake(_collectionView.fs_width*0.5,min(self.collectionViewLayout.estimatedItemSize.height*2.75, _collectionView.fs_height*0.5)+_collectionView.contentOffset.y)
            let significantIndexPath:NSIndexPath! = _collectionView.indexPathForItemAtPoint(significantPoint)
            if (significantIndexPath != nil) {
                currentPage = self.gregorian.dateByAddingUnit(NSCalendarUnitMonth, value:significantIndexPath.section, toDate:self.gregorian.fs_firstDayOfMonth(_minimumDate), options:0)
            } else {
                let significantHeader:FSCalendarStickyHeader! = self.visibleStickyHeaders.filteredArrayUsingPredicate(NSPredicate.predicateWithBlock({ (evaluatedObject:FSCalendarStickyHeader,bindings:NSDictionary?) in 
                    return CGRectContainsPoint(evaluatedObject.frame, significantPoint)
                })).firstObject
                if (significantHeader != nil) {
                    currentPage = significantHeader.month
                }
            }

            if !self.gregorian.isDate(currentPage, equalToDate:_currentPage, toUnitGranularity:NSCalendarUnitMonth) {
                self.willChangeValueForKey("currentPage")
                _currentPage = currentPage
                self.delegateProxy.calendarCurrentPageDidChange(self)
                self.didChangeValueForKey("currentPage")
            }

        } else if self.hasValidateVisibleLayout {
            var scrollOffset:CGFloat = 0
            switch (_collectionViewLayout.scrollDirection) { 
                case UICollectionViewScrollDirectionHorizontal: 
                    scrollOffset = scrollView.contentOffset.x/scrollView.fs_width
                    break

                case UICollectionViewScrollDirectionVertical: 
                    scrollOffset = scrollView.contentOffset.y/scrollView.fs_height
                    break

            }
            _calendarHeaderView.scrollOffset = scrollOffset
        }
    }

    func scrollViewWillEndDragging(scrollView:UIScrollView!, withVelocity velocity:CGPoint, targetContentOffset:inout CGPoint!) {
        if !_pagingEnabled || !_scrollEnabled {
            return
        }
        var targetOffset:CGFloat = 0, contentSize:CGFloat = 0
        switch (_collectionViewLayout.scrollDirection) { 
            case UICollectionViewScrollDirectionHorizontal: 
                targetOffset = targetContentOffset->x
                contentSize = scrollView.fs_width
                break

            case UICollectionViewScrollDirectionVertical: 
                targetOffset = targetContentOffset->y
                contentSize = scrollView.fs_height
                break

        }

        let sections:Int = lrint(targetOffset/contentSize)
        var targetPage:NSDate! = nil
        switch (_scope) { 
            case FSCalendarScopeMonth: 
                let minimumPage:NSDate! = self.gregorian.fs_firstDayOfMonth(_minimumDate)
                targetPage = self.gregorian.dateByAddingUnit(NSCalendarUnitMonth, value:sections, toDate:minimumPage, options:0)
                break

            case FSCalendarScopeWeek: 
                let minimumPage:NSDate! = self.gregorian.fs_firstDayOfWeek(_minimumDate)
                targetPage = self.gregorian.dateByAddingUnit(NSCalendarUnitWeekOfYear, value:sections, toDate:minimumPage, options:0)
                break

        }
        let shouldTriggerPageChange:Bool = self.isDateInDifferentPage(targetPage)
        if shouldTriggerPageChange {
            let lastPage:NSDate! = _currentPage
            self.willChangeValueForKey("currentPage")
            _currentPage = targetPage
            self.delegateProxy.calendarCurrentPageDidChange(self)
            if _placeholderType != FSCalendarPlaceholderTypeFillSixRows {
                self.transitionCoordinator.performBoundingRectTransitionFromMonth(lastPage, toMonth:_currentPage, duration:0.25)
            }
            self.didChangeValueForKey("currentPage")
        }

    }

    // MARK: - <UIGestureRecognizerDelegate>

    func gestureRecognizer(gestureRecognizer:UIGestureRecognizer!, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer:UIGestureRecognizer!) -> Bool {
        return true
    }

    // MARK: - Notification

    func orientationDidChange(notification:NSNotification!) {
        self.orientation = self.currentCalendarOrientation
    }

    // MARK: - Properties

    func setScrollDirection(scrollDirection:FSCalendarScrollDirection) {
        if _scrollDirection != scrollDirection {
            _scrollDirection = scrollDirection

            if self.floatingMode {return}

            switch (_scope) { 
                case FSCalendarScopeMonth: 
                    _collectionViewLayout.scrollDirection = (scrollDirection as! UICollectionViewScrollDirection)
                    _calendarHeaderView.scrollDirection = _collectionViewLayout.scrollDirection
                    if self.hasValidateVisibleLayout {
                        _collectionView.reloadData()
                        _calendarHeaderView.reloadData()
                    }
                    _needsAdjustingViewFrame = true
                    self.setNeedsLayout()
                    break

                case FSCalendarScopeWeek: 
                    break

            }
        }
    }

    class func automaticallyNotifiesObserversOfScope() -> Bool {
        return false
    }

    func setScope(scope:FSCalendarScope) {
        self.setScope(scope, animated:false)
    }

    func setFirstWeekday(firstWeekday:UInt) {
        if _firstWeekday != firstWeekday {
            _firstWeekday = firstWeekday
            _needsRequestingBoundingDates = true
            self.invalidateDateTools()
            self.invalidateHeaders()
            self.collectionView.reloadData()
            self.configureAppearance()
        }
    }

    func setToday(today:NSDate!) {
        if (today == nil) {
            _today = nil
        } else {
            FSCalendarAssertDateInBounds(today,self.gregorian,self.minimumDate,self.maximumDate)
            _today = self.gregorian.dateBySettingHour(0, minute:0, second:0, ofDate:today, options:0)
        }
        if self.hasValidateVisibleLayout {
            self.visibleCells().makeObjectsPerformSelector(Selector("setDateIsToday:"), withObject:nil)
            if (today != nil) {_collectionView.cellForItemAtIndexPath(self.calculator.indexPathForDate(today)).setValue(true, forKey:"dateIsToday")}
            self.visibleCells().makeObjectsPerformSelector(Selector("configureAppearance"))
        }
    }

    func setCurrentPage(currentPage:NSDate!) {
        self.setCurrentPage(currentPage, animated:false)
    }

    func setCurrentPage(currentPage:NSDate!, animated:Bool) {
        self.requestBoundingDatesIfNecessary()
        if self.floatingMode || self.isDateInDifferentPage(currentPage) {
            currentPage = self.gregorian.dateBySettingHour(0, minute:0, second:0, ofDate:currentPage, options:0)
            if self.isPageInRange(currentPage) {
                self.scrollToPageForDate(currentPage, animated:animated)
            }
        }
    }

    func registerClass(cellClass:AnyClass, forCellReuseIdentifier identifier:String!) {
        if !identifier.length {
            NSException.raise(FSCalendarInvalidArgumentsExceptionName, format:"This identifier must not be nil and must not be an empty string.")
        }
        if !cellClass.isSubclassOfClass(FSCalendarCell.self) {
            NSException.raise("The cell class must be a subclass of FSCalendarCell.", format:"")
        }
        if (identifier == FSCalendarBlankCellReuseIdentifier) {
            NSException.raise(FSCalendarInvalidArgumentsExceptionName, format:"Do not use %@ as the cell reuse identifier.", identifier)
        }
        self.collectionView.registerClass(cellClass, forCellWithReuseIdentifier:identifier)

    }

    func dequeueReusableCellWithIdentifier(identifier:String!, forDate date:NSDate!, atMonthPosition position:FSCalendarMonthPosition) -> FSCalendarCell! {
        if !identifier.length {
            NSException.raise(FSCalendarInvalidArgumentsExceptionName, format:"This identifier must not be nil and must not be an empty string.")
        }
        let indexPath:NSIndexPath! = self.calculator.indexPathForDate(date, atMonthPosition:position)
        if (indexPath == nil) {
            NSException.raise(FSCalendarInvalidArgumentsExceptionName, format:"Attempting to dequeue a cell with invalid date.")
        }
        let cell:FSCalendarCell! = self.collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath:indexPath)
        return cell
    }

    func cellForDate(date:NSDate!, atMonthPosition position:FSCalendarMonthPosition) -> FSCalendarCell? {
        let indexPath:NSIndexPath! = self.calculator.indexPathForDate(date, atMonthPosition:position)
        return (self.collectionView.cellForItemAtIndexPath(indexPath) as! FSCalendarCell)
    }

    func dateForCell(cell:FSCalendarCell!) -> NSDate! {
        let indexPath:NSIndexPath! = self.collectionView.indexPathForCell(cell)
        return self.calculator.dateForIndexPath(indexPath)
    }

    func monthPositionForCell(cell:FSCalendarCell!) -> FSCalendarMonthPosition {
        let indexPath:NSIndexPath! = self.collectionView.indexPathForCell(cell)
        return self.calculator.monthPositionForIndexPath(indexPath)
    }

    func visibleCells() -> [AnyObject]! {
        return self.collectionView.visibleCells.filteredArrayUsingPredicate(NSPredicate.predicateWithBlock({ (evaluatedObject:AnyObject!,bindings:NSDictionary?) in 
            return (evaluatedObject is FSCalendarCell)
        }))
    }

    func frameForDate(date:NSDate!) -> CGRect {
        if !self.superview {
            return CGRectZero
        }
        var frame:CGRect = _collectionViewLayout.layoutAttributesForItemAtIndexPath(self.calculator.indexPathForDate(date)).frame
        frame = self.superview.convertRect(frame, fromView:_collectionView)
        return frame
    }

    func setHeaderHeight(headerHeight:CGFloat) {
        if _headerHeight != headerHeight {
            _headerHeight = headerHeight
            _needsAdjustingViewFrame = true
            self.setNeedsLayout()
        }
    }

    func setWeekdayHeight(weekdayHeight:CGFloat) {
        if _weekdayHeight != weekdayHeight {
            _weekdayHeight = weekdayHeight
            _needsAdjustingViewFrame = true
            self.setNeedsLayout()
        }
    }

    func setLocale(locale:NSLocale!) {
        if !_locale.isEqual(locale) {
            _locale = locale.copy
            self.invalidateDateTools()
            self.configureAppearance()
            if self.hasValidateVisibleLayout {
                self.invalidateHeaders()
            }
        }
    }

    func setAllowsMultipleSelection(allowsMultipleSelection:Bool) {
        _collectionView.allowsMultipleSelection = allowsMultipleSelection
    }

    func allowsMultipleSelection() -> Bool {
        return _collectionView.allowsMultipleSelection
    }

    func setAllowsSelection(allowsSelection:Bool) {
        _collectionView.allowsSelection = allowsSelection
    }

    func allowsSelection() -> Bool {
        return _collectionView.allowsSelection
    }

    func setPagingEnabled(pagingEnabled:Bool) {
        if _pagingEnabled != pagingEnabled {
            _pagingEnabled = pagingEnabled

            self.invalidateLayout()
        }
    }

    func setScrollEnabled(scrollEnabled:Bool) {
        if _scrollEnabled != scrollEnabled {
            _scrollEnabled = scrollEnabled

            _collectionView.scrollEnabled = scrollEnabled
            _calendarHeaderView.scrollEnabled = scrollEnabled

            self.invalidateLayout()
        }
    }

    // `setOrientation:` has moved as a setter.

    func selectedDate() -> NSDate! {
        return _selectedDates.lastObject
    }

    func selectedDates() -> [AnyObject]! {
        return [AnyObject].arrayWithArray(_selectedDates)
    }

    // `preferredHeaderHeight` has moved as a getter.

    // `preferredWeekdayHeight` has moved as a getter.

    // `preferredRowHeight` has moved as a getter.

    func floatingMode() -> Bool {
        return _scope == FSCalendarScopeMonth && _scrollEnabled && !_pagingEnabled
    }

    func scopeGesture() -> UIPanGestureRecognizer! {
        if !_scopeGesture {
            let panGesture:UIPanGestureRecognizer! = UIPanGestureRecognizer(target:self.transitionCoordinator, action:Selector("handleScopeGesture:"))
            panGesture.delegate = self.transitionCoordinator
            panGesture.minimumNumberOfTouches = 1
            panGesture.maximumNumberOfTouches = 2
            panGesture.enabled = false
            self.daysContainer.addGestureRecognizer(panGesture)
            _scopeGesture = panGesture
        }
        return _scopeGesture
    }

    func swipeToChooseGesture() -> UILongPressGestureRecognizer! {
        if !_swipeToChooseGesture {
            let pressGesture:UILongPressGestureRecognizer! = UILongPressGestureRecognizer(target:self, action:Selector("handleSwipeToChoose:"))
            pressGesture.enabled = false
            pressGesture.numberOfTapsRequired = 0
            pressGesture.numberOfTouchesRequired = 1
            pressGesture.minimumPressDuration = 0.7
            self.daysContainer.addGestureRecognizer(pressGesture)
            self.collectionView.panGestureRecognizer.requireGestureRecognizerToFail(pressGesture)
            _swipeToChooseGesture = pressGesture
        }
        return _swipeToChooseGesture
    }

    func setDataSource(dataSource:FSCalendarDataSource!) {
        self.dataSourceProxy.delegation = dataSource
    }

    func dataSource() -> FSCalendarDataSource! {
        return self.dataSourceProxy.delegation
    }

    func setDelegate(delegate:FSCalendarDelegate!) {
        self.delegateProxy.delegation = delegate
    }

    func delegate() -> FSCalendarDelegate! {
        return self.delegateProxy.delegation
    }

    // MARK: - Public methods

    func reloadData() {
        _needsRequestingBoundingDates = true
        if self.requestBoundingDatesIfNecessary() || !self.collectionView.indexPathsForVisibleItems.count {
            self.invalidateHeaders()
        }
        self.collectionView.reloadData()
    }

    func setScope(scope:FSCalendarScope, animated:Bool) {
        if self.floatingMode {return}
        if self.transitionCoordinator.state != FSCalendarTransitionState.Idle {return}

        self.performEnsuringValidLayout({ 
            self.transitionCoordinator.performScopeTransitionFromScope(self.scope, toScope:scope, animated:animated)
        })
    }

    func setPlaceholderType(placeholderType:FSCalendarPlaceholderType) {
        _placeholderType = placeholderType
        if self.hasValidateVisibleLayout {
            _preferredRowHeight = FSCalendarAutomaticDimension
            _collectionView.reloadData()
        }
        self.adjustBoundingRectIfNecessary()
    }

    func setAdjustsBoundingRectWhenChangingMonths(adjustsBoundingRectWhenChangingMonths:Bool) {
        _adjustsBoundingRectWhenChangingMonths = adjustsBoundingRectWhenChangingMonths
        self.adjustBoundingRectIfNecessary()
    }

    func selectDate(date:NSDate!) {
        self.selectDate(date, scrollToDate:true)
    }

    func selectDate(date:NSDate!, scrollToDate:Bool) {
        self.selectDate(date, scrollToDate:scrollToDate, atMonthPosition:FSCalendarMonthPositionCurrent)
    }

    func deselectDate(date:NSDate!) {
        date = self.gregorian.dateBySettingHour(0, minute:0, second:0, ofDate:date, options:0)
        if !_selectedDates.containsObject(date) {
            return
        }
        _selectedDates.removeObject(date)
        self.deselectCounterpartDate(date)
        let indexPath:NSIndexPath! = self.calculator.indexPathForDate(date)
        if _collectionView.indexPathsForSelectedItems.containsObject(indexPath) {
            _collectionView.deselectItemAtIndexPath(indexPath, animated:true)
            let cell:FSCalendarCell! = _collectionView.cellForItemAtIndexPath(indexPath)
            cell.selected = false
            cell.configureAppearance()
        }
    }

    func selectDate(date:NSDate!, scrollToDate:Bool, atMonthPosition monthPosition:FSCalendarMonthPosition) {
        if !self.allowsSelection() || (date == nil) {return}

        self.requestBoundingDatesIfNecessary()

        FSCalendarAssertDateInBounds(date,self.gregorian,self.minimumDate,self.maximumDate)

        let targetDate:NSDate! = self.gregorian.dateBySettingHour(0, minute:0, second:0, ofDate:date, options:0)
        let targetIndexPath:NSIndexPath! = self.calculator.indexPathForDate(targetDate)

        var shouldSelect:Bool = true
        // 跨月份点击
        if monthPosition==FSCalendarMonthPositionPrevious||monthPosition==FSCalendarMonthPositionNext {
            if self.allowsMultipleSelection() {
                if self.isDateSelected(targetDate) {
                    let shouldDeselect:Bool = !self.delegateProxy.respondsToSelector(Selector("calendar:shouldDeselectDate:atMonthPosition:")) || self.delegateProxy.calendar(self, shouldDeselectDate:targetDate, atMonthPosition:monthPosition)
                    if !shouldDeselect {
                        return
                    }
                } else {
                    shouldSelect &= (!self.delegateProxy.respondsToSelector(Selector("calendar:shouldSelectDate:atMonthPosition:")) || self.delegateProxy.calendar(self, shouldSelectDate:targetDate, atMonthPosition:monthPosition))
                    if !shouldSelect {
                        return
                    }
                    _collectionView.selectItemAtIndexPath(targetIndexPath, animated:true, scrollPosition:UICollectionViewScrollPositionNone)
                    self.collectionView(_collectionView, didSelectItemAtIndexPath:targetIndexPath)
                }
            } else {
                shouldSelect &= (!self.delegateProxy.respondsToSelector(Selector("calendar:shouldSelectDate:atMonthPosition:")) || self.delegateProxy.calendar(self, shouldSelectDate:targetDate, atMonthPosition:monthPosition))
                if shouldSelect {
                    if self.isDateSelected(targetDate) {
                        self.delegateProxy.calendar(self, didSelectDate:targetDate, atMonthPosition:monthPosition)
                    } else {
                        let selectedDate:NSDate! = self.selectedDate()
                        if (selectedDate != nil) {
                            self.deselectDate(selectedDate)
                        }
                        _collectionView.selectItemAtIndexPath(targetIndexPath, animated:true, scrollPosition:UICollectionViewScrollPositionNone)
                        self.collectionView(_collectionView, didSelectItemAtIndexPath:targetIndexPath)
                    }
                } else {
                    return
                }
            }

        } else if !self.isDateSelected(targetDate) {
            if (self.selectedDate() != nil) && !self.allowsMultipleSelection() {
                self.deselectDate(self.selectedDate())
            }
            _collectionView.selectItemAtIndexPath(targetIndexPath, animated:false, scrollPosition:UICollectionViewScrollPositionNone)
            let cell:FSCalendarCell! = _collectionView.cellForItemAtIndexPath(targetIndexPath)
            cell.performSelecting()
            self.enqueueSelectedDate(targetDate)
            self.selectCounterpartDate(targetDate)

        } else if !_collectionView.indexPathsForSelectedItems.containsObject(targetIndexPath) {
            _collectionView.selectItemAtIndexPath(targetIndexPath, animated:false, scrollPosition:UICollectionViewScrollPositionNone)
        }

        if scrollToDate {
            if !shouldSelect {
                return
            }
            self.scrollToPageForDate(targetDate, animated:true)
        }
    }

    func handleScopeGesture(sender:UIPanGestureRecognizer!) {
        if self.floatingMode {return}
        self.transitionCoordinator.handleScopeGesture(sender)
    }

    // MARK: - Private methods

    func scrollToDate(date:NSDate!) {
        self.scrollToDate(date, animated:false)
    }

    func scrollToDate(date:NSDate!, animated:Bool) {
        if !_minimumDate || !_maximumDate {
            return
        }
        animated &= _scrollEnabled // No animation if _scrollEnabled == NO;

        date = self.calculator.safeDateForDate(date)
        let scrollOffset:Int = self.calculator.indexPathForDate(date, atMonthPosition:FSCalendarMonthPositionCurrent).section

        if !self.floatingMode {
            switch (_collectionViewLayout.scrollDirection) { 
                case UICollectionViewScrollDirectionVertical: 
                    _collectionView.setContentOffset(CGPointMake(0, scrollOffset * _collectionView.fs_height), animated:animated)
                    break

                case UICollectionViewScrollDirectionHorizontal: 
                    _collectionView.setContentOffset(CGPointMake(scrollOffset * _collectionView.fs_width, 0), animated:animated)
                    break

            }

        } else if self.hasValidateVisibleLayout {
            _collectionViewLayout.layoutAttributesForElementsInRect(_collectionView.bounds)
            let headerFrame:CGRect = _collectionViewLayout.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, atIndexPath:NSIndexPath.indexPathForItem(0, inSection:scrollOffset)).frame
            let targetOffset:CGPoint = CGPointMake(0, min(headerFrame.origin.y,max(0,_collectionViewLayout.collectionViewContentSize.height-_collectionView.fs_bottom)))
            _collectionView.setContentOffset(targetOffset, animated:animated)
        }
        if !animated {
            self.calendarHeaderView.scrollOffset = scrollOffset
        }
    }

    func scrollToPageForDate(date:NSDate!, animated:Bool) {
        if (date == nil) {return}
        if !self.isDateInRange(date) {
            date = self.calculator.safeDateForDate(date)
            if (date == nil) {return}
        }

        if !self.floatingMode {
            if self.isDateInDifferentPage(date) {
                self.willChangeValueForKey("currentPage")
                let lastPage:NSDate! = _currentPage
                switch (self.transitionCoordinator.representingScope) { 
                    case FSCalendarScopeMonth: 
                        _currentPage = self.gregorian.fs_firstDayOfMonth(date)
                        break

                    case FSCalendarScopeWeek: 
                        _currentPage = self.gregorian.fs_firstDayOfWeek(date)
                        break

                }
                if self.hasValidateVisibleLayout {
                    self.delegateProxy.calendarCurrentPageDidChange(self)
                    if _placeholderType != FSCalendarPlaceholderTypeFillSixRows && self.transitionCoordinator.state == FSCalendarTransitionState.Idle {
                        self.transitionCoordinator.performBoundingRectTransitionFromMonth(lastPage, toMonth:_currentPage, duration:0.33)
                    }
                }
                self.didChangeValueForKey("currentPage")
            }
            self.scrollToDate(_currentPage, animated:animated)
        } else {
            self.scrollToDate(self.gregorian.fs_firstDayOfMonth(date), animated:animated)
        }
    }


    func isDateInRange(date:NSDate!) -> Bool {
        var flag:Bool = true
        flag &= self.gregorian.components(NSCalendarUnitDay, fromDate:date, toDate:self.minimumDate, options:0).day <= 0
        flag &= self.gregorian.components(NSCalendarUnitDay, fromDate:date, toDate:self.maximumDate, options:0).day >= 0;;
        return flag
    }

    func isPageInRange(page:NSDate!) -> Bool {
        var flag:Bool = true
        switch (self.transitionCoordinator.representingScope) { 
            case FSCalendarScopeMonth: 
                let c1:NSDateComponents! = self.gregorian.components(NSCalendarUnitDay, fromDate:self.gregorian.fs_firstDayOfMonth(self.minimumDate), toDate:page, options:0)
                flag &= (c1.day>=0)
                if !flag {break}
                let c2:NSDateComponents! = self.gregorian.components(NSCalendarUnitDay, fromDate:page, toDate:self.gregorian.fs_lastDayOfMonth(self.maximumDate), options:0)
                flag &= (c2.day>=0)
                break

            case FSCalendarScopeWeek: 
                let c1:NSDateComponents! = self.gregorian.components(NSCalendarUnitDay, fromDate:self.gregorian.fs_firstDayOfWeek(self.minimumDate), toDate:page, options:0)
                flag &= (c1.day>=0)
                if !flag {break}
                let c2:NSDateComponents! = self.gregorian.components(NSCalendarUnitDay, fromDate:page, toDate:self.gregorian.fs_lastDayOfWeek(self.maximumDate), options:0)
                flag &= (c2.day>=0)
                break

            default:
                break
        }
        return flag
    }

    func isDateSelected(date:NSDate!) -> Bool {
        return _selectedDates.containsObject(date) || _collectionView.indexPathsForSelectedItems.containsObject(self.calculator.indexPathForDate(date))
    }

    func isDateInDifferentPage(date:NSDate!) -> Bool {
        if self.floatingMode {
            return !self.gregorian.isDate(date, equalToDate:_currentPage, toUnitGranularity:NSCalendarUnitMonth)
        }
        switch (_scope) { 
            case FSCalendarScopeMonth:
                return !self.gregorian.isDate(date, equalToDate:_currentPage, toUnitGranularity:NSCalendarUnitMonth)
            case FSCalendarScopeWeek:
                return !self.gregorian.isDate(date, equalToDate:_currentPage, toUnitGranularity:NSCalendarUnitWeekOfYear)
        }
    }

    func hasValidateVisibleLayout() -> Bool {
#if TARGET_INTERFACE_BUILDER
        return true
#else
        return self.superview  && !CGRectIsEmpty(_collectionView.frame) && !CGSizeEqualToSize(_collectionViewLayout.collectionViewContentSize, CGSizeZero)
#endif
    }

    func invalidateDateTools() {
        _gregorian.locale = _locale
        _gregorian.timeZone = _timeZone
        _gregorian.firstWeekday = _firstWeekday
        _formatter.calendar = _gregorian
        _formatter.timeZone = _timeZone
        _formatter.locale = _locale
    }

    func invalidateLayout() {
        if !self.floatingMode {

            if !_calendarHeaderView {

                let headerView:FSCalendarHeaderView! = FSCalendarHeaderView(frame:CGRectZero)
                headerView.calendar = self
                headerView.scrollEnabled = _scrollEnabled
                _contentView.addSubview(headerView)
                self.calendarHeaderView = headerView

            }

            if !_calendarWeekdayView {
                let calendarWeekdayView:FSCalendarWeekdayView! = FSCalendarWeekdayView(frame:CGRectZero)
                calendarWeekdayView.calendar = self
                _contentView.addSubview(calendarWeekdayView)
                _calendarWeekdayView = calendarWeekdayView
            }

            if _scrollEnabled {
                if (_deliver == nil) {
                    let deliver:FSCalendarHeaderTouchDeliver! = FSCalendarHeaderTouchDeliver(frame:CGRectZero)
                    deliver.header = _calendarHeaderView
                    deliver.calendar = self
                    _contentView.addSubview(deliver)
                    self.deliver = deliver
                }
            } else if (_deliver != nil) {
                _deliver.removeFromSuperview()
            }

            _collectionView.pagingEnabled = true
            _collectionViewLayout.scrollDirection = (self.scrollDirection as! UICollectionViewScrollDirection)

        } else {

            self.calendarHeaderView.removeFromSuperview()
            self.deliver.removeFromSuperview()
            self.calendarWeekdayView.removeFromSuperview()

            _collectionView.pagingEnabled = false
            _collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical

        }

        _preferredHeaderHeight = FSCalendarAutomaticDimension
        _preferredWeekdayHeight = FSCalendarAutomaticDimension
        _preferredRowHeight = FSCalendarAutomaticDimension
        _needsAdjustingViewFrame = true
        self.setNeedsLayout()
    }

    func invalidateHeaders() {
        self.calendarHeaderView.collectionView.reloadData()
        self.visibleStickyHeaders.makeObjectsPerformSelector(Selector("configureAppearance"))
    }

    func invalidateAppearanceForCell(cell:FSCalendarCell!, forDate date:NSDate!) {
// define FSCalendarInvalidateCellAppearance(SEL1,SEL2) \
        cell.SEL1 = [self.delegateProxy calendar:self appearance:self.appearance SEL2:date];

// define FSCalendarInvalidateCellAppearanceWithDefault(SEL1,SEL2,DEFAULT) \
        if ([self.delegateProxy respondsToSelector:@selector(calendar:appearance:SEL2:)]) { \
            cell.SEL1 = [self.delegateProxy calendar:self appearance:self.appearance SEL2:date]; \
        } else { \
            cell.SEL1 = DEFAULT; \
        }

        FSCalendarInvalidateCellAppearance(preferredFillDefaultColor,fillDefaultColorForDate)
        FSCalendarInvalidateCellAppearance(preferredFillSelectionColor,fillSelectionColorForDate)
        FSCalendarInvalidateCellAppearance(preferredTitleDefaultColor,titleDefaultColorForDate)
        FSCalendarInvalidateCellAppearance(preferredTitleSelectionColor,titleSelectionColorForDate)

        FSCalendarInvalidateCellAppearanceWithDefault(preferredTitleOffset,titleOffsetForDate,CGPointInfinity)
        if (cell.subtitle != nil) {
            FSCalendarInvalidateCellAppearance(preferredSubtitleDefaultColor,subtitleDefaultColorForDate)
            FSCalendarInvalidateCellAppearance(preferredSubtitleSelectionColor,subtitleSelectionColorForDate)
            FSCalendarInvalidateCellAppearanceWithDefault(preferredSubtitleOffset,subtitleOffsetForDate,CGPointInfinity)
        }
        if (cell.numberOfEvents != 0) {
            FSCalendarInvalidateCellAppearance(preferredEventDefaultColors,eventDefaultColorsForDate)
            FSCalendarInvalidateCellAppearance(preferredEventSelectionColors,eventSelectionColorsForDate)
            FSCalendarInvalidateCellAppearanceWithDefault(preferredEventOffset,eventOffsetForDate,CGPointInfinity)
        }
        FSCalendarInvalidateCellAppearance(preferredBorderDefaultColor,borderDefaultColorForDate)
        FSCalendarInvalidateCellAppearance(preferredBorderSelectionColor,borderSelectionColorForDate)
        FSCalendarInvalidateCellAppearanceWithDefault(preferredBorderRadius,borderRadiusForDate,-1)

        if (cell.image != nil) {
            FSCalendarInvalidateCellAppearanceWithDefault(preferredImageOffset,imageOffsetForDate,CGPointInfinity)
        }

#undef FSCalendarInvalidateCellAppearance
#undef FSCalendarInvalidateCellAppearanceWithDefault

    }

    func reloadDataForCell(cell:FSCalendarCell!, atIndexPath indexPath:NSIndexPath!) {
        cell.calendar = self
        let date:NSDate! = self.calculator.dateForIndexPath(indexPath)
        cell.image = self.dataSourceProxy.calendar(self, imageForDate:date)
        cell.numberOfEvents = self.dataSourceProxy.calendar(self, numberOfEventsForDate:date)
        cell.titleLabel.text = self.dataSourceProxy.calendar(self, titleForDate:date) ?self.dataSourceProxy.calendar(self, titleForDate:date): self.gregorian.component(NSCalendarUnitDay, fromDate:date).stringValue
        cell.subtitle  = self.dataSourceProxy.calendar(self, subtitleForDate:date)
        cell.selected = _selectedDates.containsObject(date)
        cell.dateIsToday = self.today?self.gregorian.isDate(date, inSameDayAsDate:self.today):false
        cell.weekend = self.gregorian.isDateInWeekend(date)
        cell.monthPosition = self.calculator.monthPositionForIndexPath(indexPath)
        switch (self.transitionCoordinator.representingScope) { 
            case FSCalendarScopeMonth: 
                cell.placeholder = (cell.monthPosition == FSCalendarMonthPositionPrevious || cell.monthPosition == FSCalendarMonthPositionNext) || !self.isDateInRange(date)
                if cell.placeholder {
                    cell.selected &= _pagingEnabled
                    cell.dateIsToday &= _pagingEnabled
                }
                break

            case FSCalendarScopeWeek: 
                cell.placeholder = !self.isDateInRange(date)
                break

        }
        // Synchronize selecion state to the collection view, otherwise delegate methods would not be triggered.
        if cell.selected {
            self.collectionView.selectItemAtIndexPath(indexPath, animated:false, scrollPosition:UICollectionViewScrollPositionNone)
        } else {
            self.collectionView.deselectItemAtIndexPath(indexPath, animated:false)
        }
        self.invalidateAppearanceForCell(cell, forDate:date)
        cell.configureAppearance()
    }


    func handleSwipeToChoose(pressGesture:UILongPressGestureRecognizer!) {
        switch (pressGesture.state) { 
            case UIGestureRecognizerStateBegan,
                 UIGestureRecognizerStateChanged: 
                let indexPath:NSIndexPath! = self.collectionView.indexPathForItemAtPoint(pressGesture.locationInView(self.collectionView))
                if (indexPath != nil) && !indexPath.isEqual(self.lastPressedIndexPath) {
                    let date:NSDate! = self.calculator.dateForIndexPath(indexPath)
                    let monthPosition:FSCalendarMonthPosition = self.calculator.monthPositionForIndexPath(indexPath)
                    if !self.selectedDates().containsObject(date) && self.collectionView(self.collectionView, shouldSelectItemAtIndexPath:indexPath) {
                        self.selectDate(date, scrollToDate:false, atMonthPosition:monthPosition)
                        self.collectionView(self.collectionView, didSelectItemAtIndexPath:indexPath)
                    } else if self.collectionView.allowsMultipleSelection && self.collectionView(self.collectionView, shouldDeselectItemAtIndexPath:indexPath) {
                        self.deselectDate(date)
                        self.collectionView(self.collectionView, didDeselectItemAtIndexPath:indexPath)
                    }
                }
                self.lastPressedIndexPath = indexPath
                break

            case UIGestureRecognizerStateEnded,
                 UIGestureRecognizerStateCancelled: 
                self.lastPressedIndexPath = nil
                break

            default:
                break
        }

    }

    func selectCounterpartDate(date:NSDate!) {
        if _placeholderType == FSCalendarPlaceholderTypeNone {return}
        if self.scope == FSCalendarScopeWeek {return}
        let numberOfDays:Int = self.gregorian.fs_numberOfDaysInMonth(date)
        let day:Int = self.gregorian.component(NSCalendarUnitDay, fromDate:date)
        var cell:FSCalendarCell!
        if day < numberOfDays/2+1 {
            cell = self.cellForDate(date, atMonthPosition:FSCalendarMonthPositionNext)
        } else {
            cell = self.cellForDate(date, atMonthPosition:FSCalendarMonthPositionPrevious)
        }
        if (cell != nil) {
            cell.selected = true
            if self.collectionView.allowsMultipleSelection {   
                self.collectionView.selectItemAtIndexPath(self.collectionView.indexPathForCell(cell), animated:false, scrollPosition:UICollectionViewScrollPositionNone)
            }
        }
        cell.configureAppearance()
    }

    func deselectCounterpartDate(date:NSDate!) {
        if _placeholderType == FSCalendarPlaceholderTypeNone {return}
        if self.scope == FSCalendarScopeWeek {return}
        let numberOfDays:Int = self.gregorian.fs_numberOfDaysInMonth(date)
        let day:Int = self.gregorian.component(NSCalendarUnitDay, fromDate:date)
        var cell:FSCalendarCell!
        if day < numberOfDays/2+1 {
            cell = self.cellForDate(date, atMonthPosition:FSCalendarMonthPositionNext)
        } else {
            cell = self.cellForDate(date, atMonthPosition:FSCalendarMonthPositionPrevious)
        }
        if (cell != nil) {
            cell.selected = false
            self.collectionView.deselectItemAtIndexPath(self.collectionView.indexPathForCell(cell), animated:false)
        }
        cell.configureAppearance()
    }

    func enqueueSelectedDate(date:NSDate!) {
        if !self.allowsMultipleSelection() {
            _selectedDates.removeAllObjects()
        }
        if !_selectedDates.containsObject(date) {
            _selectedDates.addObject(date)
        }
    }

    func visibleStickyHeaders() -> [AnyObject]! {
        return self.visibleSectionHeaders.dictionaryRepresentation.allValues()
    }

    func invalidateViewFrames() {
        _needsAdjustingViewFrame = true

        _preferredHeaderHeight  = FSCalendarAutomaticDimension
        _preferredWeekdayHeight = FSCalendarAutomaticDimension
        _preferredRowHeight     = FSCalendarAutomaticDimension

        self.setNeedsLayout()

    }

    // The best way to detect orientation
    // http://stackoverflow.com/questions/25830448/what-is-the-best-way-to-detect-orientation-in-an-app-extension/26023538#26023538
    func currentCalendarOrientation() -> FSCalendarOrientation {
        let scale:CGFloat = UIScreen.mainScreen.scale
        let nativeSize:CGSize = UIScreen.mainScreen.currentMode!.size
        let sizeInPoints:CGSize = UIScreen.mainScreen.bounds.size
        let orientation:FSCalendarOrientation = scale * sizeInPoints.width == nativeSize.width ? FSCalendarOrientation.Portrait : FSCalendarOrientation.Landscape
        return orientation
    }

    func adjustMonthPosition() {
        self.requestBoundingDatesIfNecessary()
        let targetPage:NSDate! = self.pagingEnabled?self.currentPage:(self.currentPage?self.currentPage:self.selectedDate())
        self.scrollToPageForDate(targetPage, animated:false)
    }

    func requestBoundingDatesIfNecessary() -> Bool {
        if _needsRequestingBoundingDates {
            _needsRequestingBoundingDates = false
            self.formatter.dateFormat = "yyyy-MM-dd"
            var newMin:NSDate! = self.dataSourceProxy.minimumDateForCalendar(self)?self.dataSourceProxy.minimumDateForCalendar(self):self.formatter.dateFromString("1970-01-01")
            newMin = self.gregorian.dateBySettingHour(0, minute:0, second:0, ofDate:newMin, options:0)
            var newMax:NSDate! = self.dataSourceProxy.maximumDateForCalendar(self)?self.dataSourceProxy.maximumDateForCalendar(self):self.formatter.dateFromString("2099-12-31")
            newMax = self.gregorian.dateBySettingHour(0, minute:0, second:0, ofDate:newMax, options:0)

            NSAssert(self.gregorian.compareDate(newMin, toDate:newMax, toUnitGranularity:NSCalendarUnitDay) != NSOrderedDescending, "The minimum date of calendar should be earlier than the maximum.")

            let res:Bool = !self.gregorian.isDate(newMin, inSameDayAsDate:_minimumDate) || !self.gregorian.isDate(newMax, inSameDayAsDate:_maximumDate)
            _minimumDate = newMin
            _maximumDate = newMax
            self.calculator.reloadSections()

            return res
        }
        return false
    }

    func configureAppearance() {
        self.visibleCells().makeObjectsPerformSelector(Selector("configureAppearance"))
        self.visibleStickyHeaders.makeObjectsPerformSelector(Selector("configureAppearance"))
        self.calendarHeaderView.configureAppearance()
        self.calendarWeekdayView.configureAppearance()
    }

    func adjustBoundingRectIfNecessary() {
        if self.placeholderType == FSCalendarPlaceholderTypeFillSixRows {
            return
        }
        if !self.adjustsBoundingRectWhenChangingMonths {
            return
        }
        self.performEnsuringValidLayout({ 
            self.transitionCoordinator.performBoundingRectTransitionFromMonth(nil, toMonth:self.currentPage, duration:0)
        })
    }

    func performEnsuringValidLayout(block:(Void)->Void) {
        if self.collectionView.visibleCells.count {
            block()
        } else {
            self.setNeedsLayout()
            self.didLayoutOperations.addObject(NSBlockOperation.blockOperationWithBlock(block))
        }
    }

    func executePendingOperationsIfNeeded() {
        var operations:[AnyObject]! = nil
        if self.didLayoutOperations.count {
            operations = self.didLayoutOperations.copy
            self.didLayoutOperations.removeAllObjects()
        }
        operations.makeObjectsPerformSelector(Selector("start"))
    }
}


