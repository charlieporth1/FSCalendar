//
//  FSCalendarWeekdayView.m
//  FSCalendar
//
//  Created by dingwenchao on 03/11/2016.
//  Copyright © 2016 Wenchao Ding. All rights reserved.
//

//#import "FSCalendarWeekdayView.h"
//#import "FSCalendar.h"
//#import "FSCalendarDynamicHeader.h"
//#import "FSCalendarExtensions.h"


class FSCalendarWeekdayView : UIView {

    private(set) var weekdayLabels:[AnyObject]
    private var _calendar:FSCalendar!
    var calendar:FSCalendar! {
        get { return _calendar }
        set(calendar) { 
            _calendar = calendar
            self.configureAppearance()
        }
    }
    private var _weekdayPointers:NSPointerArray!
    private var weekdayPointers:NSPointerArray! {
        get { return _weekdayPointers }
        set { _weekdayPointers = newValue }
    }
    private var _contentView:UIView!
    private var contentView:UIView! {
        get { return _contentView }
        set { _contentView = newValue }
    }

    init(frame:CGRect) {
        self = super.init(frame:frame)
        if (self != nil) {
            self.commonInit()
        }
        return self
    }

    init(coder:NSCoder!) {
        self = super.init(coder:coder)
        if (self != nil) {
            self.commonInit()
        }
        return self
    }

    func commonInit() {
        let contentView:UIView! = UIView(frame:CGRectZero)
        self.addSubview(contentView)
        _contentView = contentView

        _weekdayPointers = NSPointerArray.weakObjectsPointerArray()
        for var i:Int=0 ; i < 7 ; i++ {  
            let weekdayLabel:UILabel! = UILabel(frame:CGRectZero)
            weekdayLabel.textAlignment = NSTextAlignmentCenter
            self.contentView.addSubview(weekdayLabel)
            _weekdayPointers.addPointer(((weekdayLabel) as! __bridge void))
         }
    }

    func layoutSubviews() {
        super.layoutSubviews()

        self.contentView.frame = self.bounds

        // Position Calculation
        let count:Int = self.weekdayPointers.count
        let size:size_t = sizeof($(TypeName))*count
        let widths:CGFloat! = malloc(size)
        let contentWidth:CGFloat = self.contentView.fs_width
        FSCalendarSliceCake(contentWidth, count, widths)

        var opposite:Bool = false
        if #available(iOS 9.0, *) {
            let direction:UIUserInterfaceLayoutDirection = UIView.userInterfaceLayoutDirectionForSemanticContentAttribute(self.calendar.semanticContentAttribute)
            opposite = (direction == UIUserInterfaceLayoutDirectionRightToLeft)
        }
        var x:CGFloat = 0
        for var i:Int=0 ; i < count ; i++ {  
            let width:CGFloat = widths[i]
            let labelIndex:Int = opposite ? count-1-i : i
            let label:UILabel! = self.weekdayPointers.pointerAtIndex(labelIndex)
            label.frame = CGRectMake(x, 0, width, self.contentView.fs_height)
            x = CGRectGetMaxX(label.frame)
         }
        free(widths)
    }

    // `setCalendar:` has moved as a setter.

    func weekdayLabels() -> [AnyObject]! {
        return self.weekdayPointers.allObjects
    }

    func configureAppearance() {
        let useVeryShortWeekdaySymbols:Bool = (self.calendar.appearance.caseOptions & (15<<4)) == FSCalendarCaseOptions.WeekdayUsesSingleUpperCase
        let weekdaySymbols:[AnyObject]! = useVeryShortWeekdaySymbols ? self.calendar.gregorian.veryShortStandaloneWeekdaySymbols : self.calendar.gregorian.shortStandaloneWeekdaySymbols
        let useDefaultWeekdayCase:Bool = (self.calendar.appearance.caseOptions & (15<<4)) == FSCalendarCaseOptions.WeekdayUsesDefaultCase

        for var i:Int=0 ; i < self.weekdayPointers.count ; i++ {  
            let index:Int = (i + self.calendar.firstWeekday-1) % 7
            let label:UILabel! = self.weekdayPointers.pointerAtIndex(i)
            label.font = self.calendar.appearance.weekdayFont
            label.textColor = self.calendar.appearance.weekdayTextColor
            label.text = useDefaultWeekdayCase ? weekdaySymbols[index] : weekdaySymbols[index].uppercaseString()
         }

    }
}
