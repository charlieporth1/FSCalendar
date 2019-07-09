//
//  FSCalendarHeader.m
//  Pods
//
//  Created by Wenchao Ding on 29/1/15.
//
//

//#import "FSCalendar.h"
//#import "FSCalendarExtensions.h"
//#import "FSCalendarHeaderView.h"
//#import "FSCalendarCollectionView.h"
//#import "FSCalendarDynamicHeader.h"


class FSCalendarHeaderView : UIView, UICollectionViewDataSource, UICollectionViewDelegate, FSCalendarCollectionViewInternalDelegate {

    // MARK: - Life cycle

    private var _collectionView:FSCalendarCollectionView!
    var collectionView:FSCalendarCollectionView! {
        get { return _collectionView }
        set { _collectionView = newValue }
    }
    private var _collectionViewLayout:FSCalendarHeaderLayout!
    var collectionViewLayout:FSCalendarHeaderLayout! {
        get { return _collectionViewLayout }
        set { _collectionViewLayout = newValue }
    }
    private var _calendar:FSCalendar!
    var calendar:FSCalendar! {
        get { return _calendar }
        set(calendar) { 
            _calendar = calendar
            self.configureAppearance()
        }
    }
    private var _scrollDirection:UICollectionViewScrollDirection
    var scrollDirection:UICollectionViewScrollDirection {
        get { return _scrollDirection }
        set(scrollDirection) { 
            if _scrollDirection != scrollDirection {
                _scrollDirection = scrollDirection
                _collectionViewLayout.scrollDirection = scrollDirection
                self.setNeedsLayout()
            }
        }
    }
    private var _scrollEnabled:Bool
    var scrollEnabled:Bool {
        get { return _scrollEnabled }
        set(scrollEnabled) { 
            if _scrollEnabled != scrollEnabled {
                _scrollEnabled = scrollEnabled
                _collectionView.visibleCells.makeObjectsPerformSelector(Selector("setNeedsLayout"))
            }
        }
    }

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
        _scrollDirection = UICollectionViewScrollDirectionHorizontal
        _scrollEnabled = true

        let collectionViewLayout:FSCalendarHeaderLayout! = FSCalendarHeaderLayout()
        self.collectionViewLayout = collectionViewLayout

        let collectionView:FSCalendarCollectionView! = FSCalendarCollectionView(frame:CGRectZero, collectionViewLayout:collectionViewLayout)
        collectionView.scrollEnabled = false
        collectionView.userInteractionEnabled = false
        collectionView.backgroundColor = UIColor.clearColor
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        self.addSubview(collectionView)
        collectionView.registerClass(FSCalendarHeaderCell.self, forCellWithReuseIdentifier:"cell")
        self.collectionView = collectionView
    }

    func layoutSubviews() {
        super.layoutSubviews()
        self.collectionView.frame = CGRectMake(0, self.fs_height*0.1, self.fs_width, self.fs_height*0.9)
    }

    func dealloc() {
        self.collectionView.dataSource = nil
        self.collectionView.delegate = nil
    }

    // MARK: - <UICollectionViewDataSource>

    func collectionView(collectionView:UICollectionView!, numberOfItemsInSection section:Int) -> Int {
        let numberOfSections:Int = self.calendar.collectionView.numberOfSections
        if self.scrollDirection == UICollectionViewScrollDirectionVertical {
            return numberOfSections
        }
        return numberOfSections + 2
    }

    func collectionView(collectionView:UICollectionView!, cellForItemAtIndexPath indexPath:NSIndexPath!) -> UICollectionViewCell! {
        let cell:FSCalendarHeaderCell! = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath:indexPath)
        cell.header = self
        self.configureCell(cell, atIndexPath:indexPath)
        return cell
    }

    func scrollViewDidScroll(scrollView:UIScrollView!) {
        _collectionView.visibleCells.makeObjectsPerformSelector(Selector("setNeedsLayout"))
    }

    // MARK: - Properties

    // `setCalendar:` has moved as a setter.

    func setScrollOffset(scrollOffset:CGFloat) {
        self.setScrollOffset(scrollOffset, animated:false)
    }

    func setScrollOffset(scrollOffset:CGFloat, animated:Bool) {
        self.scrollToOffset(scrollOffset, animated:false)
    }

    func scrollToOffset(scrollOffset:CGFloat, animated:Bool) {
        if self.scrollDirection == UICollectionViewScrollDirectionHorizontal {
            let step:CGFloat = self.collectionView.fs_width*((self.scrollDirection==UICollectionViewScrollDirectionHorizontal)?0.5:1)
            _collectionView.setContentOffset(CGPointMake((scrollOffset+0.5)*step, 0), animated:animated)
        } else {
            let step:CGFloat = self.collectionView.fs_height
            _collectionView.setContentOffset(CGPointMake(0, scrollOffset*step), animated:animated)
        }
    }

    // `setScrollDirection:` has moved as a setter.

    // `setScrollEnabled:` has moved as a setter.

    // MARK: - Public

    func reloadData() {
        _collectionView.reloadData()
    }

    func configureCell(cell:FSCalendarHeaderCell!, atIndexPath indexPath:NSIndexPath!) {
        let appearance:FSCalendarAppearance! = self.calendar.appearance
        cell.titleLabel.font = appearance.headerTitleFont
        cell.titleLabel.textColor = appearance.headerTitleColor
        _calendar.formatter.dateFormat = appearance.headerDateFormat
        let usesUpperCase:Bool = (appearance.caseOptions & 15) == FSCalendarCaseOptions.HeaderUsesUpperCase
        var text:String! = nil
        switch (self.calendar.transitionCoordinator.representingScope) { 
            case FSCalendarScopeMonth: 
                if _scrollDirection == UICollectionViewScrollDirectionHorizontal {
                    // 多出的两项需要制空
                    if (indexPath.item == 0 || indexPath.item == self.collectionView.numberOfItemsInSection(0) - 1) {
                        text = nil
                    } else {
                        let date:NSDate! = self.calendar.gregorian.dateByAddingUnit(NSCalendarUnitMonth, value:indexPath.item-1, toDate:self.calendar.minimumDate, options:0)
                        text = _calendar.formatter.stringFromDate(date)
                    }
                } else {
                    let date:NSDate! = self.calendar.gregorian.dateByAddingUnit(NSCalendarUnitMonth, value:indexPath.item, toDate:self.calendar.minimumDate, options:0)
                    text = _calendar.formatter.stringFromDate(date)
                }
                break

            case FSCalendarScopeWeek: 
                if (indexPath.item == 0 || indexPath.item == self.collectionView.numberOfItemsInSection(0) - 1) {
                    text = nil
                } else {
                    let firstPage:NSDate! = self.calendar.gregorian.fs_middleDayOfWeek(self.calendar.minimumDate)
                    let date:NSDate! = self.calendar.gregorian.dateByAddingUnit(NSCalendarUnitWeekOfYear, value:indexPath.item-1, toDate:firstPage, options:0)
                    text = _calendar.formatter.stringFromDate(date)
                }
                break

            default: 
                break

        }
        text = usesUpperCase ? text.uppercaseString : text
        cell.titleLabel.text = text
        cell.setNeedsLayout()
    }

    func configureAppearance() {
        self.collectionView.visibleCells.enumerateObjectsUsingBlock({ (cell:FSCalendarHeaderCell,idx:UInt,stop:Bool) in 
            self.configureCell(cell, atIndexPath:self.collectionView.indexPathForCell(cell))
        })
    }
}


class FSCalendarHeaderCell : UICollectionViewCell {

    var titleLabel:UILabel!
    var header:FSCalendarHeaderView!

    init(frame:CGRect) {
        self = super.init(frame:frame)
        if (self != nil) {
            let titleLabel:UILabel! = UILabel(frame:CGRectZero)
            titleLabel.textAlignment = NSTextAlignmentCenter
            titleLabel.lineBreakMode = NSLineBreakByWordWrapping
            titleLabel.numberOfLines = 0
            self.contentView.addSubview(titleLabel)
            self.titleLabel = titleLabel
        }
        return self
    }

    func setBounds(bounds:CGRect) {
        super.bounds = bounds
        self.titleLabel.frame = bounds
    }

    func layoutSubviews() {
        super.layoutSubviews()

        self.titleLabel.frame = self.contentView.bounds

        if self.header.scrollDirection == UICollectionViewScrollDirectionHorizontal {
            let position:CGFloat = self.contentView.convertPoint(CGPointMake(CGRectGetMidX(self.contentView.bounds), CGRectGetMidY(self.contentView.bounds)), toView:self.header).x
            let center:CGFloat = CGRectGetMidX(self.header.bounds)
            if self.header.scrollEnabled {
                self.contentView.alpha = 1.0 - (1.0-self.header.calendar.appearance.headerMinimumDissolvedAlpha)*ABS(center-position)/self.fs_width
            } else {
                self.contentView.alpha = (position > self.header.fs_width*0.25 && position < self.header.fs_width*0.75)
            }
        } else if self.header.scrollDirection == UICollectionViewScrollDirectionVertical {
            let position:CGFloat = self.contentView.convertPoint(CGPointMake(CGRectGetMidX(self.contentView.bounds), CGRectGetMidY(self.contentView.bounds)), toView:self.header).y
            let center:CGFloat = CGRectGetMidY(self.header.bounds)
            self.contentView.alpha = 1.0 - (1.0-self.header.calendar.appearance.headerMinimumDissolvedAlpha)*ABS(center-position)/self.fs_height
        }
    }
}


class FSCalendarHeaderLayout : UICollectionViewFlowLayout {

    init() {
        self = super.init()
        if (self != nil) {
            self.scrollDirection = UICollectionViewScrollDirectionHorizontal
            self.minimumInteritemSpacing = 0
            self.minimumLineSpacing = 0
            self.sectionInset = UIEdgeInsetsZero
            self.itemSize = CGSizeMake(1, 1)
            NSNotificationCenter.defaultCenter.addObserver(self, selector:Selector("didReceiveOrientationChangeNotification:"), name:UIDeviceOrientationDidChangeNotification, object:nil)
        }
        return self
    }

    func dealloc() {
        NSNotificationCenter.defaultCenter.removeObserver(self, name:UIDeviceOrientationDidChangeNotification, object:nil)
    }

    func prepareLayout() {
        super.prepareLayout()

        self.itemSize = CGSizeMake(self.collectionView.fs_width*((self.scrollDirection==UICollectionViewScrollDirectionHorizontal)?0.5:1),
                                   self.collectionView.fs_height)

    }

    func didReceiveOrientationChangeNotification(notificatino:NSNotification!) {
        self.invalidateLayout()
    }

    func flipsHorizontallyInOppositeLayoutDirection() -> Bool {
        return true
    }
}

class FSCalendarHeaderTouchDeliver : UIView {

    private var _calendar:FSCalendar!
    var calendar:FSCalendar! {
        get { return _calendar }
        set { _calendar = newValue }
    }
    var header:FSCalendarHeaderView!

    func hitTest(point:CGPoint, withEvent event:UIEvent!) -> UIView! {
        let hitView:UIView! = super.hitTest(point, withEvent:event)
        if hitView == self {
            return _calendar.collectionView ?_calendar.collectionView: hitView
        }
        return hitView
    }
}


