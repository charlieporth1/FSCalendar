//
//  FSCalendarAnimationLayout.m
//  FSCalendar
//
//  Created by dingwenchao on 1/3/16.
//  Copyright © 2016 Wenchao Ding. All rights reserved.
//

//#import "FSCalendarCollectionViewLayout.h"
//#import "FSCalendar.h"
//#import "FSCalendarDynamicHeader.h"
//#import "FSCalendarCollectionView.h"
//#import "FSCalendarExtensions.h"
//#import "FSCalendarConstants.h"
//#import "FSCalendarSeparatorDecorationView.h"

// define kFSCalendarSeparatorInterRows @"FSCalendarSeparatorInterRows"
// define kFSCalendarSeparatorInterColumns @"FSCalendarSeparatorInterColumns"


class FSCalendarCollectionViewLayout : UICollectionViewLayout {

    var calendar:FSCalendar!
    var sectionInsets:UIEdgeInsets
    private var _scrollDirection:UICollectionViewScrollDirection
    var scrollDirection:UICollectionViewScrollDirection {
        get { return _scrollDirection }
        set(scrollDirection) { 
            if _scrollDirection != scrollDirection {
                _scrollDirection = scrollDirection
                self.collectionViewSize = CGSizeAutomatic
            }
        }
    }
    private(set) var estimatedItemSize:CGSize
    private var widths:CGFloat!
    private var heights:CGFloat!
    private var lefts:CGFloat!
    private var tops:CGFloat!
    private var sectionHeights:CGFloat!
    private var sectionTops:CGFloat!
    private var sectionBottoms:CGFloat!
    private var sectionRowCounts:CGFloat!
    private var contentSize:CGSize
    private var collectionViewSize:CGSize
    private var headerReferenceSize:CGSize
    private var numberOfSections:Int
    private var separators:FSCalendarSeparators
    private var itemAttributes:NSMutableDictionary!
    private var headerAttributes:NSMutableDictionary!
    private var rowSeparatorAttributes:NSMutableDictionary!

    override init() {
        self = super.init()
        if (self != nil) {
            self.estimatedItemSize = CGSizeZero
            self.widths = nil
            self.heights = nil
            self.tops = nil
            self.lefts = nil

            self.sectionHeights = nil
            self.sectionTops = nil
            self.sectionBottoms = nil
            self.sectionRowCounts = nil

            self.scrollDirection = UICollectionViewScrollDirectionHorizontal
            self.sectionInsets = UIEdgeInsetsMake(5, 0, 5, 0)

            self.itemAttributes = NSMutableDictionary.dictionary
            self.headerAttributes = NSMutableDictionary.dictionary
            self.rowSeparatorAttributes = NSMutableDictionary.dictionary

            NSNotificationCenter.defaultCenter().addObserver(self, selector:Selector("didReceiveNotifications:"), name:UIDeviceOrientationDidChangeNotification, object:nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector:Selector("didReceiveNotifications:"), name:UIApplicationDidReceiveMemoryWarningNotification, object:nil)

            self.registerClass(FSCalendarSeparatorDecorationView.self, forDecorationViewOfKind:kFSCalendarSeparatorInterRows)
        }
        return self
    }

    func dealloc() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationDidReceiveMemoryWarningNotification, object:nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIDeviceOrientationDidChangeNotification, object:nil)

        free(self.widths)
        free(self.heights)
        free(self.tops)
        free(self.lefts)

        free(self.sectionHeights)
        free(self.sectionTops)
        free(self.sectionRowCounts)
        free(self.sectionBottoms)
    }

    override func prepareLayout() {
        if CGSizeEqualToSize(self.collectionViewSize, self.collectionView!.frame.size) && self.numberOfSections == self.collectionView!.numberOfSections && self.separators == self.calendar.appearance.separators {
            return
        }
        self.collectionViewSize = self.collectionView!.frame.size
        self.separators = self.calendar.appearance.separators

        self.itemAttributes.removeAllObjects()
        self.headerAttributes.removeAllObjects()
        self.rowSeparatorAttributes.removeAllObjects()

        self.headerReferenceSize = (
            var headerSize:CGSize = CGSizeZero
            if self.calendar.floatingMode {
                let headerHeight:CGFloat = self.calendar.preferredWeekdayHeight*1.5+self.calendar.preferredHeaderHeight
                headerSize = CGSizeMake(self.collectionView!.fs_width, headerHeight)
            }
            headerSize
        )
        self.estimatedItemSize = (
            let width:CGFloat = (self.collectionView!.fs_width-self.sectionInsets.left-self.sectionInsets.right)/7.0
            let height:CGFloat = (
                var height:CGFloat = FSCalendarStandardRowHeight
                if !self.calendar.floatingMode {
                    switch (self.calendar.transitionCoordinator.representingScope) { 
                        case FSCalendarScopeMonth: 
                            height = (self.collectionView!.fs_height-self.sectionInsets.top-self.sectionInsets.bottom)/6.0
                            break

                        case FSCalendarScopeWeek: 
                            height = (self.collectionView!.fs_height-self.sectionInsets.top-self.sectionInsets.bottom)
                            break

                        default:
                            break
                    }
                } else {
                    height = self.calendar.rowHeight
                }
                height
            )
            let size:CGSize = CGSizeMake(width, height)
            size
        )

        // Calculate item widths and lefts
        free(self.widths)
        self.widths = (
            let columnCount:Int = 7
            let columnSize:size_t = sizeof($(TypeName))*columnCount
            let widths:CGFloat! = malloc(columnSize)
            let contentWidth:CGFloat = self.collectionView!.fs_width - self.sectionInsets.left - self.sectionInsets.right
            FSCalendarSliceCake(contentWidth, columnCount, widths)
            widths
        )

        free(self.lefts)
        self.lefts = (
            let columnCount:Int = 7
            let columnSize:size_t = sizeof($(TypeName))*columnCount
            let lefts:CGFloat! = malloc(columnSize)
            lefts[0] = self.sectionInsets.left
            for var i:Int=1 ; i < columnCount ; i++ {  
                lefts[i] = lefts[i-1] + self.widths[i-1]
             }
            lefts
        )

        // Calculate item heights and tops
        free(self.heights)
        self.heights = (
            let rowCount:Int = self.calendar.transitionCoordinator.representingScope == FSCalendarScopeWeek ? 1 : 6
            let rowSize:size_t = sizeof($(TypeName))*rowCount
            let heights:CGFloat! = malloc(rowSize)
            if !self.calendar.floatingMode {
                let contentHeight:CGFloat = self.collectionView!.fs_height - self.sectionInsets.top - self.sectionInsets.bottom
                FSCalendarSliceCake(contentHeight, rowCount, heights)
            } else {
                for var i:Int=0 ; i < rowCount ; i++ {  
                    heights[i] = self.estimatedItemSize.height
                 }
            }
            heights
        )

        free(self.tops)
        self.tops = (
            let rowCount:Int = self.calendar.transitionCoordinator.representingScope == FSCalendarScopeWeek ? 1 : 6
            let rowSize:size_t = sizeof($(TypeName))*rowCount
            let tops:CGFloat! = malloc(rowSize)
            tops[0] = self.sectionInsets.top
            for var i:Int=1 ; i < rowCount ; i++ {  
                tops[i] = tops[i-1] + self.heights[i-1]
             }
            tops
        )

        // Calculate content size
        self.numberOfSections = self.collectionView!.numberOfSections
        self.contentSize = (
            var contentSize:CGSize = CGSizeZero
            if !self.calendar.floatingMode {
                var width:CGFloat = self.collectionView!.fs_width
                var height:CGFloat = self.collectionView!.fs_height
                switch (self.scrollDirection) { 
                    case UICollectionViewScrollDirectionHorizontal: 
                        width *= self.numberOfSections
                        break

                    case UICollectionViewScrollDirectionVertical: 
                        height *= self.numberOfSections
                        break

                    default:
                        break
                }
                contentSize = CGSizeMake(width, height)
            } else {
                free(self.sectionHeights)
                self.sectionHeights = malloc(sizeof($(TypeName))*self.numberOfSections)
                free(self.sectionRowCounts)
                self.sectionRowCounts = malloc(sizeof($(TypeName))*self.numberOfSections)
                let width:CGFloat = self.collectionView!.fs_width
                var height:CGFloat = 0
                for var i:Int=0 ; i < self.numberOfSections ; i++ {  
                    let rowCount:Int = self.calendar.calculator.numberOfRowsInSection(i)
                    self.sectionRowCounts[i] = rowCount
                    var sectionHeight:CGFloat = self.headerReferenceSize.height
                    for var j:Int=0 ; j < rowCount ; j++ {  
                        sectionHeight += self.heights[j]
                     }
                    self.sectionHeights[i] = sectionHeight
                    height += sectionHeight
                 }
                free(self.sectionTops)
                self.sectionTops = malloc(sizeof($(TypeName))*self.numberOfSections)
                free(self.sectionBottoms)
                self.sectionBottoms = malloc(sizeof($(TypeName))*self.numberOfSections)
                self.sectionTops[0] = 0
                self.sectionBottoms[0] = self.sectionHeights[0]
                for var i:Int=1 ; i < self.numberOfSections ; i++ {  
                    self.sectionTops[i] = self.sectionTops[i-1] + self.sectionHeights[i-1]
                    self.sectionBottoms[i] = self.sectionTops[i] + self.sectionHeights[i]
                 }
                contentSize = CGSizeMake(width, height)
            }
            contentSize
        )

        self.calendar.adjustMonthPosition()
    }

    override func collectionViewContentSize() -> CGSize {
        return self.contentSize
    }

    override func layoutAttributesForElementsInRect(rect:CGRect) -> [AnyObject]? {
        // Clipping
        rect = CGRectIntersection(rect, CGRectMake(0, 0, self.contentSize.width, self.contentSize.height))
        if CGRectIsEmpty(rect) {return nil}

        // Calculating attributes
        let layoutAttributes:NSMutableArray! = NSMutableArray.array()

        if !self.calendar.floatingMode {

            switch (self.scrollDirection) { 
                case UICollectionViewScrollDirectionHorizontal: 

                    let startColumn:Int = (
                        let startSection:Int = rect.origin.x/self.collectionView!.fs_width
                        var widthDelta:CGFloat = FSCalendarMod(CGRectGetMinX(rect), self.collectionView!.fs_width)-self.sectionInsets.left
                        widthDelta = min(max(0, widthDelta), self.collectionView!.fs_width-self.sectionInsets.left)
                        let countDelta:Int = FSCalendarFloor(widthDelta/self.estimatedItemSize.width)
                        let startColumn:Int = startSection*7 + countDelta
                        startColumn
                    )

                    let endColumn:Int = (
                        var endColumn:Int
                        let section:CGFloat = CGRectGetMaxX(rect)/self.collectionView!.fs_width
                        let remainder:CGFloat = FSCalendarMod(section, 1)
                        // https://stackoverflow.com/a/10335601/2398107
                        if remainder <= max(100*FLT_EPSILON*ABS(remainder), FLT_MIN) {
                            endColumn = FSCalendarFloor(section)*7 - 1
                        } else {
                            var widthDelta:CGFloat = FSCalendarMod(CGRectGetMaxX(rect), self.collectionView!.fs_width)-self.sectionInsets.left
                            widthDelta = min(max(0, widthDelta), self.collectionView!.fs_width - self.sectionInsets.left)
                            let countDelta:Int = FSCalendarCeil(widthDelta/self.estimatedItemSize.width)
                            endColumn = FSCalendarFloor(section)*7 + countDelta - 1
                        }
                        endColumn
                    )

                    let numberOfRows:Int = self.calendar.transitionCoordinator.representingScope == FSCalendarScopeMonth ? 6 : 1

                    for var column:Int=startColumn ; column <= endColumn ; column++ {  
                        for var row:Int=0 ; row < numberOfRows ; row++ {  
                            let section:Int = column / 7
                            let item:Int = column % 7 + row * 7
                            let indexPath:NSIndexPath! = NSIndexPath.indexPathForItem(item, inSection:section)
                            let itemAttributes:UICollectionViewLayoutAttributes! = self.layoutAttributesForItemAtIndexPath(indexPath)
                            layoutAttributes.addObject(itemAttributes)

                            let rowSeparatorAttributes:UICollectionViewLayoutAttributes! = self.layoutAttributesForDecorationViewOfKind(kFSCalendarSeparatorInterRows, atIndexPath:indexPath)
                            if (rowSeparatorAttributes != nil) {
                                layoutAttributes.addObject(rowSeparatorAttributes)
                            }
                         }
                     }

                    break

                case UICollectionViewScrollDirectionVertical: 

                    let startRow:Int = (
                        let startSection:Int = rect.origin.y/self.collectionView!.fs_height
                        var heightDelta:CGFloat = FSCalendarMod(CGRectGetMinY(rect), self.collectionView!.fs_height)-self.sectionInsets.top
                        heightDelta = min(max(0, heightDelta), self.collectionView!.fs_height-self.sectionInsets.top)
                        let countDelta:Int = FSCalendarFloor(heightDelta/self.estimatedItemSize.height)
                        let startRow:Int = startSection*6 + countDelta
                        startRow
                    )

                    let endRow:Int = (
                        var endRow:Int
                        let section:CGFloat = CGRectGetMaxY(rect)/self.collectionView!.fs_height
                        let remainder:CGFloat = FSCalendarMod(section, 1)
                        // https://stackoverflow.com/a/10335601/2398107
                        if remainder <= max(100*FLT_EPSILON*ABS(remainder), FLT_MIN) {
                            endRow = FSCalendarFloor(section)*6 - 1
                        } else {
                            var heightDelta:CGFloat = FSCalendarMod(CGRectGetMaxY(rect), self.collectionView!.fs_height)-self.sectionInsets.top
                            heightDelta = min(max(0, heightDelta), self.collectionView!.fs_height-self.sectionInsets.top)
                            let countDelta:Int = FSCalendarCeil(heightDelta/self.estimatedItemSize.height)
                            endRow = FSCalendarFloor(section)*6 + countDelta-1
                        }
                        endRow
                    )

                    for var row:Int=startRow ; row <= endRow ; row++ {  
                        for var column:Int=0 ; column < 7 ; column++ {  
                            let section:Int = row / 6
                            let item:Int = column + (row % 6) * 7
                            let indexPath:NSIndexPath! = NSIndexPath.indexPathForItem(item, inSection:section)
                            let itemAttributes:UICollectionViewLayoutAttributes! = self.layoutAttributesForItemAtIndexPath(indexPath)
                            layoutAttributes.addObject(itemAttributes)

                            let rowSeparatorAttributes:UICollectionViewLayoutAttributes! = self.layoutAttributesForDecorationViewOfKind(kFSCalendarSeparatorInterRows, atIndexPath:indexPath)
                            if (rowSeparatorAttributes != nil) {
                                layoutAttributes.addObject(rowSeparatorAttributes)
                            }

                         }
                     }

                    break

                default:
                    break
            }

        } else {

            let startSection:Int = self.searchStartSection(rect, :0, :self.numberOfSections-1)
            let startRowIndex:Int = (
                let heightDelta1:CGFloat = min(self.sectionBottoms[startSection]-CGRectGetMinY(rect)-self.sectionInsets.bottom, self.sectionRowCounts[startSection]*self.estimatedItemSize.height)
                let startRowCount:Int = FSCalendarCeil(heightDelta1/self.estimatedItemSize.height)
                let startRowIndex:Int = self.sectionRowCounts[startSection]-startRowCount
                startRowIndex
            )

            let endSection:Int = self.searchEndSection(rect, :startSection, :self.numberOfSections-1)
            let endRowIndex:Int = (
                let heightDelta2:CGFloat = max(CGRectGetMaxY(rect) - self.sectionTops[endSection]- self.headerReferenceSize.height - self.sectionInsets.top, 0)
                let endRowCount:Int = FSCalendarCeil(heightDelta2/self.estimatedItemSize.height)
                let endRowIndex:Int = endRowCount - 1
                endRowIndex
            )
            for var section:Int=startSection ; section <= endSection ; section++ {  
                let startRow:Int = (section == startSection) ? startRowIndex : 0
                let endRow:Int = (section == endSection) ? endRowIndex : self.sectionRowCounts[section]-1
                let headerAttributes:UICollectionViewLayoutAttributes! = self.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, atIndexPath:NSIndexPath.indexPathForItem(0, inSection:section))
                layoutAttributes.addObject(headerAttributes)
                for var row:Int=startRow ; row <= endRow ; row++ {  
                    for var column:Int=0 ; column < 7 ; column++ {  
                        let item:Int = row * 7 + column
                        let indexPath:NSIndexPath! = NSIndexPath.indexPathForItem(item, inSection:section)
                        let itemAttributes:UICollectionViewLayoutAttributes! = self.layoutAttributesForItemAtIndexPath(indexPath)
                        layoutAttributes.addObject(itemAttributes)
                        let rowSeparatorAttributes:UICollectionViewLayoutAttributes! = self.layoutAttributesForDecorationViewOfKind(kFSCalendarSeparatorInterRows, atIndexPath:indexPath)
                        if (rowSeparatorAttributes != nil) {
                            layoutAttributes.addObject(rowSeparatorAttributes)
                        }
                     }
                 }
             }

        }
        return [AnyObject].arrayWithArray(layoutAttributes)

    }

    // Items
    override func layoutAttributesForItemAtIndexPath(indexPath:NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let coordinate:FSCalendarCoordinate = self.calendar.calculator.coordinateForIndexPath(indexPath)
        let column:Int = coordinate.column
        let row:Int = coordinate.row
        let numberOfRows:Int = self.calendar.calculator.numberOfRowsInSection(indexPath.section)
        var attributes:UICollectionViewLayoutAttributes! = self.itemAttributes[indexPath]
        if (attributes == nil) {
            attributes = UICollectionViewLayoutAttributes.layoutAttributesForCellWithIndexPath(indexPath)
            let frame:CGRect = (
                let width:CGFloat = self.widths[column]
                let height:CGFloat = self.heights[row]
                var x:CGFloat, y:CGFloat
                switch (self.scrollDirection) { 
                    case UICollectionViewScrollDirectionHorizontal: 
                        x = self.lefts[column] + indexPath.section * self.collectionView!.fs_width
                        y = self.calculateRowOffset(row, totalRows:numberOfRows)
                        break

                    case UICollectionViewScrollDirectionVertical: 
                        x = self.lefts[column]
                        if !self.calendar.floatingMode {
                            let sectionTop:CGFloat = indexPath.section * self.collectionView!.fs_height
                            let rowOffset:CGFloat = self.calculateRowOffset(row, totalRows:numberOfRows)
                            y = sectionTop + rowOffset
                        } else {
                            y = self.sectionTops[indexPath.section] + self.headerReferenceSize.height + self.tops[row]
                        }
                        break

                    default:
                        break
                }
                let frame:CGRect = CGRectMake(x, y, width, height)
                frame
            )
            attributes.frame = frame
            self.itemAttributes[indexPath] = attributes
        }
        return attributes
    }

    // Section headers
    override func layoutAttributesForSupplementaryViewOfKind(elementKind:String, atIndexPath indexPath:NSIndexPath) -> UICollectionViewLayoutAttributes? {
        if (elementKind == UICollectionElementKindSectionHeader) {
            var attributes:UICollectionViewLayoutAttributes! = self.headerAttributes[indexPath]
            if (attributes == nil) {
                attributes = UICollectionViewLayoutAttributes.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withIndexPath:indexPath)
                attributes.frame = CGRectMake(0, self.sectionTops[indexPath.section], self.collectionView!.fs_width, self.headerReferenceSize.height)
                self.headerAttributes[indexPath] = attributes
            }
            return attributes
        }
        return nil
    }

    // Separators
    override func layoutAttributesForDecorationViewOfKind(elementKind:String, atIndexPath indexPath:NSIndexPath) -> UICollectionViewLayoutAttributes? {
        if (elementKind == kFSCalendarSeparatorInterRows) && (self.separators & FSCalendarSeparators.InterRows) {
            var attributes:UICollectionViewLayoutAttributes! = self.rowSeparatorAttributes[indexPath]
            if (attributes == nil) {
                let coordinate:FSCalendarCoordinate = self.calendar.calculator.coordinateForIndexPath(indexPath)
                if coordinate.row >= self.calendar.calculator.numberOfRowsInSection(indexPath.section)-1 {
                    return nil
                }
                attributes = UICollectionViewLayoutAttributes.layoutAttributesForDecorationViewOfKind(kFSCalendarSeparatorInterRows, withIndexPath:indexPath)
                var x:CGFloat, y:CGFloat
                if !self.calendar.floatingMode {
                    let rowOffset:CGFloat = self.calculateRowOffset(coordinate.row, totalRows:self.calendar.calculator.numberOfRowsInSection(indexPath.section)) + self.heights[coordinate.row]
                    switch (self.scrollDirection) { 
                        case UICollectionViewScrollDirectionHorizontal: 
                            x = self.lefts[coordinate.column] + indexPath.section * self.collectionView!.fs_width
                            y = rowOffset
                            break

                        case UICollectionViewScrollDirectionVertical: 
                            x = 0
                            y = indexPath.section * self.collectionView!.fs_height + rowOffset
                            break

                        default:
                            break
                    }
                } else {
                    x = 0
                    y = self.sectionTops[indexPath.section] + self.headerReferenceSize.height + self.tops[coordinate.row] + self.heights[coordinate.row]
                }
                let width:CGFloat = self.collectionView!.fs_width
                let height:CGFloat = FSCalendarStandardSeparatorThickness
                attributes.frame = CGRectMake(x, y, width, height)
                attributes.zIndex = NSIntegerMax
                self.rowSeparatorAttributes[indexPath] = attributes
            }
            return attributes
        }
        return nil
    }

    func flipsHorizontallyInOppositeLayoutDirection() -> Bool {
        return true
    }

    // MARK: - Notifications

    func didReceiveNotifications(notification:NSNotification!) {
        if (notification.name == UIDeviceOrientationDidChangeNotification) {
            self.invalidateLayout()
        }
        if (notification.name == UIApplicationDidReceiveMemoryWarningNotification) {
            self.itemAttributes.removeAllObjects()
            self.headerAttributes.removeAllObjects()
            self.rowSeparatorAttributes.removeAllObjects()
        }
    }

    // MARK: - Private properties

    // `setScrollDirection:` has moved as a setter.

    // MARK: - Private functions

    func calculateRowOffset(row:Int, totalRows:Int) -> CGFloat {
        if self.calendar.adjustsBoundingRectWhenChangingMonths {
            return self.tops[row]
        }
        let height:CGFloat = self.heights[row]
        switch (totalRows) { 
            case 4,
                 5: 
                let contentHeight:CGFloat = self.collectionView!.fs_height - self.sectionInsets.top - self.sectionInsets.bottom
                let rowSpan:CGFloat = contentHeight/totalRows
                return (row + 0.5) * rowSpan - height * 0.5 + self.sectionInsets.top

            case 6:
            default:
                return self.tops[row]
        }
    }

    func searchStartSection(rect:CGRect, left:Int, right:Int) -> Int {
        let mid:Int = left + (right-left)/2
        let y:CGFloat = rect.origin.y
        let minY:CGFloat = self.sectionTops[mid]
        let maxY:CGFloat = self.sectionBottoms[mid]
        if y >= minY && y < maxY {
            return mid
        } else if y < minY {
            return self.searchStartSection(rect, :left, :mid)
        } else {
            return self.searchStartSection(rect, :mid+1, :right)
        }
    }

    func searchEndSection(rect:CGRect, left:Int, right:Int) -> Int {
        let mid:Int = left + (right-left)/2
        let y:CGFloat = CGRectGetMaxY(rect)
        let minY:CGFloat = self.sectionTops[mid]
        let maxY:CGFloat = self.sectionBottoms[mid]
        if y > minY && y <= maxY {
            return mid
        } else if y <= minY {
            return self.searchEndSection(rect, :left, :mid)
        } else {
            return self.searchEndSection(rect, :mid+1, :right)
        }
    }
}


#undef kFSCalendarSeparatorInterColumns
#undef kFSCalendarSeparatorInterRows


