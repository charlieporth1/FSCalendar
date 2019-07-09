//
//  FSCalendarConstane.m
//  FSCalendar
//
//  Created by dingwenchao on 8/28/15.
//  Copyright © 2016 Wenchao Ding. All rights reserved.
//
//  https://github.com/WenchaoD
//

//#import "FSCalendarConstants.h"

let FSCalendarStandardHeaderHeight:CGFloat = 40
let FSCalendarStandardWeekdayHeight:CGFloat = 25
let FSCalendarStandardMonthlyPageHeight:CGFloat = 300.0
let FSCalendarStandardWeeklyPageHeight:CGFloat = 108+1/3.0
let FSCalendarStandardCellDiameter:CGFloat = 100/3.0
let FSCalendarStandardSeparatorThickness:CGFloat = 0.5
let FSCalendarAutomaticDimension:CGFloat = -1
let FSCalendarDefaultBounceAnimationDuration:CGFloat = 0.15
let FSCalendarStandardRowHeight:CGFloat = 38
let FSCalendarStandardTitleTextSize:CGFloat = 13.5
let FSCalendarStandardSubtitleTextSize:CGFloat = 10
let FSCalendarStandardWeekdayTextSize:CGFloat = 14
let FSCalendarStandardHeaderTextSize:CGFloat = 16.5
let FSCalendarMaximumEventDotDiameter:CGFloat = 4.8

let FSCalendarDefaultHourComponent:Int = 0

let FSCalendarDefaultCellReuseIdentifier:String! = "_FSCalendarDefaultCellReuseIdentifier"
let FSCalendarBlankCellReuseIdentifier:String! = "_FSCalendarBlankCellReuseIdentifier"
let FSCalendarInvalidArgumentsExceptionName:String! = "Invalid argument exception"

let CGPointInfinity:CGPoint = {
    .x =  CGFLOAT_MAX,
    .y =  CGFLOAT_MAX
}

let CGSizeAutomatic:CGSize = {
    .width =  FSCalendarAutomaticDimension,
    .height =  FSCalendarAutomaticDimension
}


