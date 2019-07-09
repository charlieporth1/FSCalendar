//
//  FSCalendarAppearance.m
//  Pods
//
//  Created by DingWenchao on 6/29/15.
//  Copyright © 2016 Wenchao Ding. All rights reserved.
//
//  https://github.com/WenchaoD
//

//#import "FSCalendarAppearance.h"
//#import "FSCalendarDynamicHeader.h"
//#import "FSCalendarExtensions.h"


class FSCalendarAppearance : NSObject {

    var titleFont:UIFont!
    var subtitleFont:UIFont!
    var weekdayFont:UIFont!
    var headerTitleFont:UIFont!
    var titleOffset:CGPoint
    var subtitleOffset:CGPoint
    var eventOffset:CGPoint
    var imageOffset:CGPoint
    var eventDefaultColor:UIColor!
    var eventSelectionColor:UIColor!
    var weekdayTextColor:UIColor!
    var headerTitleColor:UIColor!
    var headerDateFormat:String!
    var headerMinimumDissolvedAlpha:CGFloat
    var titleDefaultColor:UIColor!
    var titleSelectionColor:UIColor!
    var titleTodayColor:UIColor!
    var titlePlaceholderColor:UIColor!
    var titleWeekendColor:UIColor!
    var subtitleDefaultColor:UIColor!
    var subtitleSelectionColor:UIColor!
    var subtitleTodayColor:UIColor!
    var subtitlePlaceholderColor:UIColor!
    var subtitleWeekendColor:UIColor!
    var selectionColor:UIColor!
    var todayColor:UIColor!
    var todaySelectionColor:UIColor!
    var borderDefaultColor:UIColor!
    var borderSelectionColor:UIColor!
    var borderRadius:CGFloat
    private var _caseOptions:FSCalendarCaseOptions
    var caseOptions:FSCalendarCaseOptions {
        get { return _caseOptions }
        set(caseOptions) { 
            if _caseOptions != caseOptions {
                _caseOptions = caseOptions
                self.calendar.configureAppearance()
            }
        }
    }
    var separators:FSCalendarSeparators
    var fakeSubtitles:Bool
    var fakeEventDots:Bool
    var fakedSelectedDay:Int
    var calendar:FSCalendar!
    private(set) var backgroundColors:NSDictionary!
    private(set) var titleColors:NSDictionary!
    private(set) var subtitleColors:NSDictionary!
    private(set) var borderColors:NSDictionary!

    init() {
        self = super.init()
        if (self != nil) {

            _titleFont = UIFont.systemFontOfSize(FSCalendarStandardTitleTextSize)
            _subtitleFont = UIFont.systemFontOfSize(FSCalendarStandardSubtitleTextSize)
            _weekdayFont = UIFont.systemFontOfSize(FSCalendarStandardWeekdayTextSize)
            _headerTitleFont = UIFont.systemFontOfSize(FSCalendarStandardHeaderTextSize)

            _headerTitleColor = FSCalendarStandardTitleTextColor
            _headerDateFormat = "MMMM yyyy"
            _headerMinimumDissolvedAlpha = 0.2
            _weekdayTextColor = FSCalendarStandardTitleTextColor
            _caseOptions = FSCalendarCaseOptions.HeaderUsesDefaultCase|FSCalendarCaseOptions.WeekdayUsesDefaultCase

            _backgroundColors = NSMutableDictionary.dictionaryWithCapacity(5)
            _backgroundColors[FSCalendarCellState.Normal]      = UIColor.clearColor
            _backgroundColors[FSCalendarCellState.Selected]    = FSCalendarStandardSelectionColor
            _backgroundColors[FSCalendarCellState.Disabled]    = UIColor.clearColor
            _backgroundColors[FSCalendarCellState.Placeholder] = UIColor.clearColor
            _backgroundColors[FSCalendarCellState.Today]       = FSCalendarStandardTodayColor

            _titleColors = NSMutableDictionary.dictionaryWithCapacity(5)
            _titleColors[FSCalendarCellState.Normal]      = UIColor.blackColor
            _titleColors[FSCalendarCellState.Selected]    = UIColor.whiteColor
            _titleColors[FSCalendarCellState.Disabled]    = UIColor.grayColor
            _titleColors[FSCalendarCellState.Placeholder] = UIColor.lightGrayColor
            _titleColors[FSCalendarCellState.Today]       = UIColor.whiteColor

            _subtitleColors = NSMutableDictionary.dictionaryWithCapacity(5)
            _subtitleColors[FSCalendarCellState.Normal]      = UIColor.darkGrayColor
            _subtitleColors[FSCalendarCellState.Selected]    = UIColor.whiteColor
            _subtitleColors[FSCalendarCellState.Disabled]    = UIColor.lightGrayColor
            _subtitleColors[FSCalendarCellState.Placeholder] = UIColor.lightGrayColor
            _subtitleColors[FSCalendarCellState.Today]       = UIColor.whiteColor

            _borderColors[FSCalendarCellState.Selected] = UIColor.clearColor
            _borderColors[FSCalendarCellState.Normal] = UIColor.clearColor

            _borderRadius = 1.0
            _eventDefaultColor = FSCalendarStandardEventDotColor
            _eventSelectionColor = FSCalendarStandardEventDotColor

            _borderColors = NSMutableDictionary.dictionaryWithCapacity(2)

#if TARGET_INTERFACE_BUILDER
            _fakeEventDots = true
#endif

        }
        return self
    }

    func setTitleFont(titleFont:UIFont!) {
        if !_titleFont.isEqual(titleFont) {
            _titleFont = titleFont
            self.calendar.configureAppearance()
        }
    }

    func setSubtitleFont(subtitleFont:UIFont!) {
        if !_subtitleFont.isEqual(subtitleFont) {
            _subtitleFont = subtitleFont
            self.calendar.configureAppearance()
        }
    }

    func setWeekdayFont(weekdayFont:UIFont!) {
        if !_weekdayFont.isEqual(weekdayFont) {
            _weekdayFont = weekdayFont
            self.calendar.configureAppearance()
        }
    }

    func setHeaderTitleFont(headerTitleFont:UIFont!) {
        if !_headerTitleFont.isEqual(headerTitleFont) {
            _headerTitleFont = headerTitleFont
            self.calendar.configureAppearance()
        }
    }

    func setTitleOffset(titleOffset:CGPoint) {
        if !CGPointEqualToPoint(_titleOffset, titleOffset) {
            _titleOffset = titleOffset
            _calendar.visibleCells.makeObjectsPerformSelector(Selector("setNeedsLayout"))
        }
    }

    func setSubtitleOffset(subtitleOffset:CGPoint) {
        if !CGPointEqualToPoint(_subtitleOffset, subtitleOffset) {
            _subtitleOffset = subtitleOffset
            _calendar.visibleCells.makeObjectsPerformSelector(Selector("setNeedsLayout"))
        }
    }

    func setImageOffset(imageOffset:CGPoint) {
        if !CGPointEqualToPoint(_imageOffset, imageOffset) {
            _imageOffset = imageOffset
            _calendar.visibleCells.makeObjectsPerformSelector(Selector("setNeedsLayout"))
        }
    }

    func setEventOffset(eventOffset:CGPoint) {
        if !CGPointEqualToPoint(_eventOffset, eventOffset) {
            _eventOffset = eventOffset
            _calendar.visibleCells.makeObjectsPerformSelector(Selector("setNeedsLayout"))
        }
    }

    func setTitleDefaultColor(color:UIColor!) {
        if (color != nil) {
            _titleColors[FSCalendarCellState.Normal] = color
        } else {
            _titleColors.removeObjectForKey(FSCalendarCellState.Normal)
        }
        self.calendar.configureAppearance()
    }

    func titleDefaultColor() -> UIColor! {
        return _titleColors[FSCalendarCellState.Normal]
    }

    func setTitleSelectionColor(color:UIColor!) {
        if (color != nil) {
            _titleColors[FSCalendarCellState.Selected] = color
        } else {
            _titleColors.removeObjectForKey(FSCalendarCellState.Selected)
        }
        self.calendar.configureAppearance()
    }

    func titleSelectionColor() -> UIColor! {
        return _titleColors[FSCalendarCellState.Selected]
    }

    func setTitleTodayColor(color:UIColor!) {
        if (color != nil) {
            _titleColors[FSCalendarCellState.Today] = color
        } else {
            _titleColors.removeObjectForKey(FSCalendarCellState.Today)
        }
        self.calendar.configureAppearance()
    }

    func titleTodayColor() -> UIColor! {
        return _titleColors[FSCalendarCellState.Today]
    }

    func setTitlePlaceholderColor(color:UIColor!) {
        if (color != nil) {
            _titleColors[FSCalendarCellState.Placeholder] = color
        } else {
            _titleColors.removeObjectForKey(FSCalendarCellState.Placeholder)
        }
        self.calendar.configureAppearance()
    }

    func titlePlaceholderColor() -> UIColor! {
        return _titleColors[FSCalendarCellState.Placeholder]
    }

    func setTitleWeekendColor(color:UIColor!) {
        if (color != nil) {
            _titleColors[FSCalendarCellState.Weekend] = color
        } else {
            _titleColors.removeObjectForKey(FSCalendarCellState.Weekend)
        }
        self.calendar.configureAppearance()
    }

    func titleWeekendColor() -> UIColor! {
        return _titleColors[FSCalendarCellState.Weekend]
    }

    func setSubtitleDefaultColor(color:UIColor!) {
        if (color != nil) {
            _subtitleColors[FSCalendarCellState.Normal] = color
        } else {
            _subtitleColors.removeObjectForKey(FSCalendarCellState.Normal)
        }
        self.calendar.configureAppearance()
    }

    func subtitleDefaultColor() -> UIColor! {
        return _subtitleColors[FSCalendarCellState.Normal]
    }

    func setSubtitleSelectionColor(color:UIColor!) {
        if (color != nil) {
            _subtitleColors[FSCalendarCellState.Selected] = color
        } else {
            _subtitleColors.removeObjectForKey(FSCalendarCellState.Selected)
        }
        self.calendar.configureAppearance()
    }

    func subtitleSelectionColor() -> UIColor! {
        return _subtitleColors[FSCalendarCellState.Selected]
    }

    func setSubtitleTodayColor(color:UIColor!) {
        if (color != nil) {
            _subtitleColors[FSCalendarCellState.Today] = color
        } else {
            _subtitleColors.removeObjectForKey(FSCalendarCellState.Today)
        }
        self.calendar.configureAppearance()
    }

    func subtitleTodayColor() -> UIColor! {
        return _subtitleColors[FSCalendarCellState.Today]
    }

    func setSubtitlePlaceholderColor(color:UIColor!) {
        if (color != nil) {
            _subtitleColors[FSCalendarCellState.Placeholder] = color
        } else {
            _subtitleColors.removeObjectForKey(FSCalendarCellState.Placeholder)
        }
        self.calendar.configureAppearance()
    }

    func subtitlePlaceholderColor() -> UIColor! {
        return _subtitleColors[FSCalendarCellState.Placeholder]
    }

    func setSubtitleWeekendColor(color:UIColor!) {
        if (color != nil) {
            _subtitleColors[FSCalendarCellState.Weekend] = color
        } else {
            _subtitleColors.removeObjectForKey(FSCalendarCellState.Weekend)
        }
        self.calendar.configureAppearance()
    }

    func subtitleWeekendColor() -> UIColor! {
        return _subtitleColors[FSCalendarCellState.Weekend]
    }

    func setSelectionColor(color:UIColor!) {
        if (color != nil) {
            _backgroundColors[FSCalendarCellState.Selected] = color
        } else {
            _backgroundColors.removeObjectForKey(FSCalendarCellState.Selected)
        }
        self.calendar.configureAppearance()
    }

    func selectionColor() -> UIColor! {
        return _backgroundColors[FSCalendarCellState.Selected]
    }

    func setTodayColor(todayColor:UIColor!) {
        if (todayColor != nil) {
            _backgroundColors[FSCalendarCellState.Today] = todayColor
        } else {
            _backgroundColors.removeObjectForKey(FSCalendarCellState.Today)
        }
        self.calendar.configureAppearance()
    }

    func todayColor() -> UIColor! {
        return _backgroundColors[FSCalendarCellState.Today]
    }

    func setTodaySelectionColor(todaySelectionColor:UIColor!) {
        if (todaySelectionColor != nil) {
            _backgroundColors[FSCalendarCellState.Today|FSCalendarCellState.Selected] = todaySelectionColor
        } else {
            _backgroundColors.removeObjectForKey(FSCalendarCellState.Today|FSCalendarCellState.Selected)
        }
        self.calendar.configureAppearance()
    }

    func todaySelectionColor() -> UIColor! {
        return _backgroundColors[FSCalendarCellState.Today|FSCalendarCellState.Selected]
    }

    func setEventDefaultColor(eventDefaultColor:UIColor!) {
        if !_eventDefaultColor.isEqual(eventDefaultColor) {
            _eventDefaultColor = eventDefaultColor
            self.calendar.configureAppearance()
        }
    }

    func setBorderDefaultColor(color:UIColor!) {
        if (color != nil) {
            _borderColors[FSCalendarCellState.Normal] = color
        } else {
            _borderColors.removeObjectForKey(FSCalendarCellState.Normal)
        }
        self.calendar.configureAppearance()
    }

    func borderDefaultColor() -> UIColor! {
        return _borderColors[FSCalendarCellState.Normal]
    }

    func setBorderSelectionColor(color:UIColor!) {
        if (color != nil) {
            _borderColors[FSCalendarCellState.Selected] = color
        } else {
            _borderColors.removeObjectForKey(FSCalendarCellState.Selected)
        }
        self.calendar.configureAppearance()
    }

    func borderSelectionColor() -> UIColor! {
        return _borderColors[FSCalendarCellState.Selected]
    }

    func setBorderRadius(borderRadius:CGFloat) {
        borderRadius = max(0.0, borderRadius)
        borderRadius = min(1.0, borderRadius)
        if _borderRadius != borderRadius {
            _borderRadius = borderRadius
            self.calendar.configureAppearance()
        }
    }

    func setWeekdayTextColor(weekdayTextColor:UIColor!) {
        if !_weekdayTextColor.isEqual(weekdayTextColor) {
            _weekdayTextColor = weekdayTextColor
            self.calendar.configureAppearance()
        }
    }

    func setHeaderTitleColor(color:UIColor!) {
        if !_headerTitleColor.isEqual(color) {
            _headerTitleColor = color
            self.calendar.configureAppearance()
        }
    }

    func setHeaderMinimumDissolvedAlpha(headerMinimumDissolvedAlpha:CGFloat) {
        if _headerMinimumDissolvedAlpha != headerMinimumDissolvedAlpha {
            _headerMinimumDissolvedAlpha = headerMinimumDissolvedAlpha
            self.calendar.configureAppearance()
        }
    }

    func setHeaderDateFormat(headerDateFormat:String!) {
        if !_headerDateFormat.isEqual(headerDateFormat) {
            _headerDateFormat = headerDateFormat
            self.calendar.configureAppearance()
        }
    }

    // `setCaseOptions:` has moved as a setter.

    func setSeparators(separators:FSCalendarSeparators) {
        if _separators != separators {
            _separators = separators
            _calendar.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
}


extension FSCalendarAppearance {

    func setUseVeryShortWeekdaySymbols(useVeryShortWeekdaySymbols:Bool) {
        _caseOptions &= 15
        self.caseOptions |= (useVeryShortWeekdaySymbols*FSCalendarCaseOptions.WeekdayUsesSingleUpperCase)
    }

    func useVeryShortWeekdaySymbols() -> Bool {
        return (_caseOptions & (15<<4)) == FSCalendarCaseOptions.WeekdayUsesSingleUpperCase
    }

    func setTitleVerticalOffset(titleVerticalOffset:CGFloat) {
        self.titleOffset = CGPointMake(0, titleVerticalOffset)
    }

    func titleVerticalOffset() -> CGFloat {
        return self.titleOffset.y
    }

    func setSubtitleVerticalOffset(subtitleVerticalOffset:CGFloat) {
        self.subtitleOffset = CGPointMake(0, subtitleVerticalOffset)
    }

    func subtitleVerticalOffset() -> CGFloat {
        return self.subtitleOffset.y
    }

    func setEventColor(eventColor:UIColor!) {
        self.eventDefaultColor = eventColor
    }

    func eventColor() -> UIColor! {
        return self.eventDefaultColor
    }

    func setTitleTextSize(titleTextSize:CGFloat) {
        self.titleFont = UIFont.fontWithName(self.titleFont.fontName, size:titleTextSize)
    }

    func setSubtitleTextSize(subtitleTextSize:CGFloat) {
        self.subtitleFont = UIFont.fontWithName(self.subtitleFont.fontName, size:subtitleTextSize)
    }

    func setWeekdayTextSize(weekdayTextSize:CGFloat) {
        self.weekdayFont = UIFont.fontWithName(self.weekdayFont.fontName, size:weekdayTextSize)
    }

    func setHeaderTitleTextSize(headerTitleTextSize:CGFloat) {
        self.headerTitleFont = UIFont.fontWithName(self.headerTitleFont.fontName, size:headerTitleTextSize)
    }

    func invalidateAppearance() {
        self.calendar.configureAppearance()
    }
}

