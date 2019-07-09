//
//  FSCalendarCollectionView.m
//  FSCalendar
//
//  Created by Wenchao Ding on 10/25/15.
//  Copyright (c) 2015 Wenchao Ding. All rights reserved.
//
//  Reject -[UIScrollView(UIScrollViewInternal) _adjustContentOffsetIfNecessary]


//#import "FSCalendarCollectionView.h"
//#import "FSCalendarExtensions.h"
//#import "FSCalendarConstants.h"


class FSCalendarCollectionView : UICollectionView {

    var internalDelegate:FSCalendarCollectionViewInternalDelegate!


    init(frame:CGRect, collectionViewLayout layout:UICollectionViewLayout!) {
        self = super.init(frame:frame, collectionViewLayout:layout)
        if (self != nil) {
            self.commonInit()
        }
        return self
    }

    init(frame:CGRect) {
        self = super.init(frame:frame)
        if (self != nil) {
            self.commonInit()
        }
        return self
    }

    func commonInit() {
        self.scrollsToTop = false
        self.contentInset = UIEdgeInsetsZero
        if #available(iOS 10.0, *) {self.prefetchingEnabled = false}
        if #available(iOS 11.0, *) {self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever}
    }

    func layoutSubviews() {
        super.layoutSubviews()
        if (self.internalDelegate != nil) && self.internalDelegate.respondsToSelector(Selector("collectionViewDidFinishLayoutSubviews:")) {
            self.internalDelegate.collectionViewDidFinishLayoutSubviews(self)
        }
    }

    func setContentInset(contentInset:UIEdgeInsets) {
        super.contentInset = UIEdgeInsetsZero
        if contentInset.top {
            self.contentOffset = CGPointMake(self.contentOffset.x, self.contentOffset.y+contentInset.top)
        }
    }

    func setScrollsToTop(scrollsToTop:Bool) {
        super.scrollsToTop = false
    }
}


