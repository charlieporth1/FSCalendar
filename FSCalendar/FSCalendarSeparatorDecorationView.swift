//
//  FSCalendarSeparatorDecorationView.m
//  FSCalendar
//
//  Created by 丁文超 on 2018/10/10.
//  Copyright © 2018 wenchaoios. All rights reserved.
//

//#import "FSCalendarSeparatorDecorationView.h"
//#import "FSCalendarConstants.h"

class FSCalendarSeparatorDecorationView : UICollectionReusableView {

    init(frame:CGRect) {
        self = super.init(frame:frame)
        if (self != nil) {
            self.backgroundColor = FSCalendarStandardSeparatorColor
        }
        return self
    }

    func applyLayoutAttributes(layoutAttributes:UICollectionViewLayoutAttributes!) {
        self.frame = layoutAttributes.frame
    }
}
