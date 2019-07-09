//
//  FSCalendarDelegationFactory.m
//  FSCalendar
//
//  Created by dingwenchao on 19/12/2016.
//  Copyright © 2016 wenchaoios. All rights reserved.
//

//#import "FSCalendarDelegationFactory.h"

class FSCalendarDelegationFactory : NSObject {

    class func dataSourceProxy() -> FSCalendarDelegationProxy! {
        let delegation:FSCalendarDelegationProxy! = FSCalendarDelegationProxy()
        delegation.protocol = FSCalendarDataSource
        return delegation
    }

    class func delegateProxy() -> FSCalendarDelegationProxy! {
        let delegation:FSCalendarDelegationProxy! = FSCalendarDelegationProxy()
        delegation.protocol = FSCalendarDelegateAppearance
        return delegation
    }
}

#undef FSCalendarSelectorEntry

