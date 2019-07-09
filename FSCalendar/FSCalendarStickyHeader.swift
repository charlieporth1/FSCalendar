//
//  FSCalendarStaticHeader.m
//  FSCalendar
//
//  Created by dingwenchao on 9/17/15.
//  Copyright (c) 2015 Wenchao Ding. All rights reserved.
//

//#import "FSCalendarStickyHeader.h"
//#import "FSCalendar.h"
//#import "FSCalendarWeekdayView.h"
//#import "FSCalendarExtensions.h"
//#import "FSCalendarConstants.h"
//#import "FSCalendarDynamicHeader.h"


class FSCalendarStickyHeader : UICollectionReusableView {

    private var _calendar:FSCalendar!
    var calendar:FSCalendar! {
        get { return _calendar }
        set(calendar) { 
            if !_calendar.isEqual(calendar) {
                _calendar = calendar
                _weekdayView.calendar = calendar
                self.configureAppearance()
            }
        }
    }
    private var _titleLabel:UILabel!
    var titleLabel:UILabel! {
        get { return _titleLabel }
        set { _titleLabel = newValue }
    }
    private var _month:NSDate!
    var month:NSDate! {
        get { return _month }
        set(month) { 
            _month = month
            _calendar.formatter.dateFormat = self.calendar.appearance.headerDateFormat
            let usesUpperCase:Bool = (self.calendar.appearance.caseOptions & 15) == FSCalendarCaseOptions.HeaderUsesUpperCase
            var text:String! = _calendar.formatter.stringFromDate(_month)
            text = usesUpperCase ? text.uppercaseString : text
            self.titleLabel.text = text
        }
    }
    private var _contentView:UIView!
    private var contentView:UIView! {
        get { return _contentView }
        set { _contentView = newValue }
    }
    private var _bottomBorder:UIView!
    private var bottomBorder:UIView! {
        get { return _bottomBorder }
        set { _bottomBorder = newValue }
    }
    private var _weekdayView:FSCalendarWeekdayView!
    private var weekdayView:FSCalendarWeekdayView! {
        get { return _weekdayView }
        set { _weekdayView = newValue }
    }

    init(frame:CGRect) {
        self = super.init(frame:frame)
        if (self != nil) {

            var view:UIView!
            var label:UILabel!

            view = UIView(frame:CGRectZero)
            view.backgroundColor = UIColor.clearColor
            self.addSubview(view)
            self.contentView = view

            label = UILabel(frame:CGRectZero)
            label.textAlignment = NSTextAlignmentCenter
            label.numberOfLines = 0
            _contentView.addSubview(label)
            self.titleLabel = label

            view = UIView(frame:CGRectZero)
            view.backgroundColor = FSCalendarStandardLineColor
            _contentView.addSubview(view)
            self.bottomBorder = view

            let weekdayView:FSCalendarWeekdayView! = FSCalendarWeekdayView()
            self.contentView.addSubview(weekdayView)
            self.weekdayView = weekdayView
        }
        return self
    }

    func layoutSubviews() {
        super.layoutSubviews()

        _contentView.frame = self.bounds

        let weekdayHeight:CGFloat = _calendar.preferredWeekdayHeight
        let weekdayMargin:CGFloat = weekdayHeight * 0.1
        let titleWidth:CGFloat = _contentView.fs_width

        self.weekdayView.frame = CGRectMake(0, _contentView.fs_height-weekdayHeight-weekdayMargin, self.contentView.fs_width, weekdayHeight)

        let titleHeight:CGFloat = "1".sizeWithAttributes([NSFontAttributeName:self.calendar.appearance.headerTitleFont]).height*1.5 + weekdayMargin*3

        _bottomBorder.frame = CGRectMake(0, _contentView.fs_height-weekdayHeight-weekdayMargin*2, _contentView.fs_width, 1.0)
        _titleLabel.frame = CGRectMake(0, _bottomBorder.fs_bottom-titleHeight-weekdayMargin, titleWidth,titleHeight)

    }

    // MARK: - Properties

    // `setCalendar:` has moved as a setter.

    // MARK: - Private methods

    func configureAppearance() {
        _titleLabel.font = self.calendar.appearance.headerTitleFont
        _titleLabel.textColor = self.calendar.appearance.headerTitleColor
        self.weekdayView.configureAppearance()
    }

    // `setMonth:` has moved as a setter.
}


