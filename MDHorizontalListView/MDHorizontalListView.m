//
//  MDHorizontalListView.m
//  MDHorizontalListView
//
//  Created by Jave on 2018/8/24.
//  Copyright © 2018年 markejave. All rights reserved.
//

#import "MDHorizontalListView.h"

const CGFloat MDHorizontalListViewIndicatorWidthDynamic = CGFLOAT_MAX;

@interface MDHorizontalListTapGestureRecognizer : UITapGestureRecognizer
@end

@implementation MDHorizontalListTapGestureRecognizer
@end

// Cell class extension to access properties setter
@interface MDHorizontalListViewCell ()

@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) NSString *reusableIdentifier;
@property (nonatomic, assign) UITapGestureRecognizer *tapGestureRecognizer;

@end

@interface MDHorizontalListView () {
    __weak id<MDHorizontalListViewDelegate> _delegate;

    NSRecursiveLock *_mainLock;
    NSMutableArray<MDHorizontalListViewCell *> *_queueCells;
    NSMutableDictionary<NSString *, MDHorizontalListViewCell *> *_visibleCells;

    NSMutableArray<NSString *> *_cellFrames;
    NSMutableIndexSet *_selectedIndexes;
    NSMutableIndexSet *_highlightedIndexes;

    NSUInteger _numberOfCells;
    CALayer *_indicatorLayer;
}

@end

@implementation MDHorizontalListView
@dynamic delegate;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initiliase];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self initiliase];
}

- (void)dealloc {
    _mainLock = nil;
    _queueCells = nil;
}

- (void)initiliase {
    _mainLock = [[NSRecursiveLock alloc] init];
    _cellFrames = [NSMutableArray<NSString *> array];
    _queueCells = [NSMutableArray<MDHorizontalListViewCell *> array];
    _visibleCells = [NSMutableDictionary<NSString *, MDHorizontalListViewCell *> dictionary];

    _selectedIndexes = [NSMutableIndexSet indexSet];
    _highlightedIndexes = [NSMutableIndexSet indexSet];

    _allowsNoneSelection = YES;
    _allowsMultipleSelection = YES;

    _indicatorHeight = 2.f;
    _indicatorWidth = MDHorizontalListViewIndicatorWidthDynamic;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (_numberOfCells != [self _numberOfCell]) {
        [self reloadData];
    } else {
        [self _updateVisibleCells];
    }
}

#pragma mark - accessor

- (void)setDelegate:(id<MDHorizontalListViewDelegate>)delegate {
    [super setDelegate:self];

    _delegate = delegate;
}

- (id<MDHorizontalListViewDelegate>)delegate {
    return _delegate;
}

- (NSIndexSet *)selectedIndexes {
    return [_selectedIndexes copy];
}

- (NSUInteger)selectedIndex {
    return [_selectedIndexes firstIndex];
}

- (NSIndexSet *)highlightedIndexes {
    return [_highlightedIndexes copy];
}

- (void)setSelectionStyle:(MDHorizontalListViewCellSelectionStyle)selectionStyle {
    if (_selectionStyle != selectionStyle) {
        _selectionStyle = selectionStyle;

        [self _updateSelectedCells];
    }
}

- (void)setIndicatorEnabled:(BOOL)indicatorEnabled {
    if (_indicatorEnabled != indicatorEnabled) {
        _indicatorEnabled = indicatorEnabled;

        if (!_indicatorEnabled) [self _removeIndicator];
    }
}

- (void)setIndicatorBackgroundColor:(UIColor *)indicatorBackgroundColor {
    if (_indicatorBackgroundColor != indicatorBackgroundColor) {
        _indicatorBackgroundColor = indicatorBackgroundColor;

        _indicatorLayer.backgroundColor = [indicatorBackgroundColor CGColor];
    }
}

- (void)setIndicatorHeight:(CGFloat)indicatorHeight {
    if (_indicatorHeight != indicatorHeight) {
        _indicatorHeight = indicatorHeight;

        [self _updateIndicator];
    }
}

- (void)setIndicatorWidth:(CGFloat)indicatorWidth {
    if (_indicatorWidth != indicatorWidth) {
        _indicatorWidth = indicatorWidth;

        [self _updateIndicator];
    }
}

#pragma mark - public

- (void)reloadData {
    [_mainLock lock];

    // clean up old cells
    for (UIView *view in [_visibleCells allValues]) {
        [view removeFromSuperview];
    }
    [_cellFrames removeAllObjects];
    [_visibleCells removeAllObjects];

    [_selectedIndexes removeAllIndexes];
    [_highlightedIndexes removeAllIndexes];

    // calculate the scrollview content size and setUp the cell destination frame list
    _numberOfCells = [self _numberOfCell];

    CGFloat contentWidth = 0.0;
    for (int i=0; i < _numberOfCells; i++) {
        CGFloat cellWidth = [_dataSource horizontalListView:self widthForCellAtIndex:i];
        CGRect cellDestinationFrame = CGRectMake(contentWidth, 0.0, cellWidth, self.frame.size.height);

        contentWidth += cellWidth;
        contentWidth += ((_numberOfCells > 1 && i < _numberOfCells - 1) ? _cellSpacing : 0.0);

        [_cellFrames addObject:NSStringFromCGRect(cellDestinationFrame)];
    }
    self.contentSize = CGSizeMake(contentWidth, self.frame.size.height);
    // add the visible cells
    [self _updateVisibleCells];

    if (!_allowsNoneSelection && _cellFrames.count) [self selectCellAtIndex:0 animated:YES];

    [_mainLock unlock];
}

- (MDHorizontalListViewCell *)dequeueCellWithReusableIdentifier:(NSString *)identifier {
    MDHorizontalListViewCell *reusableCell = nil;

    [_mainLock lock];

    reusableCell = [self _dequeueCellWithReusableIdentifier:identifier];

    [_mainLock unlock];
    return reusableCell;
}

- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated {
    [self scrollToIndex:index animated:animated nearestPosition:MDHorizontalListViewPositionNone];
}

- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated nearestPosition:(MDHorizontalListViewPosition)position {
    [_mainLock lock];
    [self _scrollToIndex:index animated:animated nearestPosition:position];
    [_mainLock unlock];
}

- (void)selectIndexProgress:(CGFloat)progress animated:(BOOL)animated {
    [self selectIndexProgress:progress animated:animated nearestPosition:MDHorizontalListViewPositionNone];
}

- (void)selectIndexProgress:(CGFloat)progress animated:(BOOL)animated nearestPosition:(MDHorizontalListViewPosition)position {
    [_mainLock lock];
    [self _selectIndexProgress:progress animated:animated nearestPosition:position];
    [_mainLock unlock];
}

- (void)selectCellAtIndex:(NSInteger)index animated:(BOOL)animated {
    [self selectCellAtIndex:index animated:animated nearestPosition:MDHorizontalListViewPositionNone];
}

- (void)selectCellAtIndex:(NSInteger)index animated:(BOOL)animated nearestPosition:(MDHorizontalListViewPosition)position {
    [_mainLock lock];
    if (!_allowsMultipleSelection && [_selectedIndexes count] == 1 && _selectedIndexes.firstIndex != index) {
        [self _deselectCellAtIndex:_selectedIndexes.firstIndex animated:animated];
    }
    [self _selectCellAtIndex:index animated:animated nearestPosition:position];
    [_mainLock unlock];
}

- (void)deselectCellAtIndex:(NSInteger)index animated:(BOOL)animated {
    [_mainLock lock];
    if (_selectedIndexes.count > 1 || _allowsNoneSelection) {
        [self _deselectCellAtIndex:index animated:animated];
    }
    [_mainLock unlock];
}

#pragma mark - private

- (void)_removeIndicator {
    if (_indicatorLayer) [_indicatorLayer removeFromSuperlayer];
    _indicatorLayer = nil;
}

- (void)_loadIndicatorIfNeeds {
    if (!_indicatorEnabled) return;
    if (_indicatorLayer) return;

    _indicatorLayer = [CALayer layer];
    _indicatorLayer.backgroundColor = _indicatorBackgroundColor.CGColor;

    [self.layer addSublayer:_indicatorLayer];
}

- (void)_updateIndicator {
    [self _loadIndicatorIfNeeds];

    _indicatorLayer.hidden = [_selectedIndexes count] <= 0;
    if (![_selectedIndexes count]) return;

    CGFloat progress = _indexProgress;
    NSUInteger index = floor(progress);
    NSUInteger nextIndex = index + 1;

    CGFloat offset = progress - index;

    CGRect frame = CGRectFromString(_cellFrames[index]);
    if (nextIndex < _numberOfCells) {
        CGRect nextFrame = CGRectFromString(_cellFrames[nextIndex]);

        frame.size.width = CGRectGetWidth(frame) + (CGRectGetWidth(nextFrame) - CGRectGetWidth(frame)) * offset;
        frame.origin.x = CGRectGetMinX(frame) + (CGRectGetMinX(nextFrame) - CGRectGetMinX(frame)) * offset;
    }

    CGFloat height = _indicatorHeight;
    CGFloat width = _indicatorWidth != MDHorizontalListViewIndicatorWidthDynamic ? _indicatorWidth : frame.size.width;
    frame = CGRectMake(CGRectGetMinX(frame) - (CGRectGetWidth(frame) - width) / 2, CGRectGetHeight(self.bounds) - height, width, height);

    _indicatorLayer.frame = frame;
}

- (NSUInteger)_numberOfCell {
    return [_dataSource horizontalListViewNumberOfCells:self];
}

- (void)_addCellAtIndex:(NSInteger)index {
    MDHorizontalListViewCell *cell = [_dataSource horizontalListView:self cellAtIndex:index];
    cell.index = index;
    cell.selectedColor = [self _selectionColor];

    NSString *frameString = _cellFrames[index];
    [_visibleCells setObject:cell forKey:frameString];

    UITapGestureRecognizer *tapGestureRecognizer = [[MDHorizontalListTapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapCell:)];
    tapGestureRecognizer.delegate = self;

    cell.tapGestureRecognizer = tapGestureRecognizer;
    [cell addGestureRecognizer:tapGestureRecognizer];

    [self insertSubview:cell atIndex:0];
}

- (NSIndexSet *)_visibleIndexes {
    NSMutableIndexSet *visibleIndexes = [NSMutableIndexSet indexSet];
    [_mainLock lock];

    CGRect visibleRect = [self _visibleRect];
    BOOL canBreak = NO;  // for a shorter loop... after the first match the next fail mean no more visible cells
    for (int i = 0; i < [_cellFrames count]; i++) {
        NSString *frameString = _cellFrames[i];
        CGRect cellDestinationFrame = CGRectFromString(frameString);

        if (CGRectIntersectsRect(visibleRect, cellDestinationFrame)) {
            canBreak = YES;
            [visibleIndexes addIndex:i];
        } else if (canBreak) {
            break;
        }
    }
    [_mainLock unlock];

    return [visibleIndexes copy];
}

- (CGRect)_visibleRect {
    CGRect visibleRect;
    
    visibleRect.origin = self.contentOffset;
    visibleRect.size = self.frame.size;
    
    return visibleRect;
}

- (void)_updateVisibleCells {
    [_mainLock lock];

    NSIndexSet *visibleIndexes = [self _visibleIndexes];

    NSArray *cellFrames = [_cellFrames copy];
    NSIndexSet *selectedIndexes = [_selectedIndexes copy];
    NSDictionary<NSString *, MDHorizontalListViewCell *> *visibleCell = [_visibleCells copy];
    NSMutableArray<NSString *> *nonVisibleCellKeys = [NSMutableArray arrayWithArray:[visibleCell allKeys]];

    [visibleIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        NSString *frameString = cellFrames[index];

        // already on view
        if ([nonVisibleCellKeys containsObject:frameString]) {
            [nonVisibleCellKeys removeObject:frameString];
        } else {
            [self _addCellAtIndex:index];
        }
        // handle selection
        BOOL selected = [selectedIndexes containsIndex:index];
        MDHorizontalListViewCell *cell = visibleCell[frameString];

        cell.frame = CGRectFromString(frameString);

        [cell setSelected:selected animated:NO];
    }];
    // enqueue unused cells
    for (NSString *unusedCellKey in nonVisibleCellKeys) {
        MDHorizontalListViewCell *cell = visibleCell[unusedCellKey];

        [self _enqueueCell:cell forKey:unusedCellKey];
    }

    [self _updateSelectIndexProgress:_indexProgress animated:NO];

    [_mainLock unlock];
}

- (void)_updateSelectedCells {
    NSArray *cellFrames = [_cellFrames copy];
    NSIndexSet *selectedIndexes = [_selectedIndexes copy];
    NSDictionary<NSString *, MDHorizontalListViewCell *> *visibleCell = [_visibleCells copy];

    [selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        NSString *frameString = cellFrames[index];
        MDHorizontalListViewCell *cell = visibleCell[frameString];

        cell.selectedColor = [self _selectionColor];
    }];
}

- (UIColor *)_selectionColor {
    switch (_selectionStyle) {
        case MDHorizontalListViewCellSelectionStyleGray: return [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:0.7];
        case MDHorizontalListViewCellSelectionStyleBlue: return [UIColor colorWithRed:0 green:0 blue:1 alpha:0.7];
        default: return nil;
    }
}

- (void)_enqueueCell:(MDHorizontalListViewCell *)cell forKey:(NSString *)frameKey {
    [_mainLock lock];
    [_queueCells addObject:cell];

    [cell removeFromSuperview];
    [cell removeGestureRecognizer:cell.tapGestureRecognizer];

    cell.index = -1;
    
    [_visibleCells removeObjectForKey:frameKey];
    [_mainLock unlock];
}

- (MDHorizontalListViewCell *)_dequeueCellWithReusableIdentifier:(NSString *)identifier {
    NSUInteger index = [_queueCells indexOfObjectPassingTest:^BOOL(MDHorizontalListViewCell *cell, NSUInteger idx, BOOL *stop) {
        return [cell.reusableIdentifier isEqualToString:identifier];
    }];
    if (index == NSNotFound) return nil;

    MDHorizontalListViewCell *cell = _queueCells[index];
    [_queueCells removeObjectAtIndex:index];

    [cell prepareForReuse];

    return cell;
}

- (void)_scrollToIndex:(NSInteger)index animated:(BOOL)animated nearestPosition:(MDHorizontalListViewPosition)position {
    NSString *frameString = _cellFrames[index];
    CGRect cellVisibleFrame = CGRectFromString(frameString);

    switch (position) {
        case MDHorizontalListViewPositionLeft:
            cellVisibleFrame.size = self.frame.size; break;
        case MDHorizontalListViewPositionRight:
            cellVisibleFrame.origin.x += cellVisibleFrame.size.width - self.frame.size.width;
            cellVisibleFrame.size = self.frame.size;
            break;
        case MDHorizontalListViewPositionCenter:
            cellVisibleFrame.origin.x -= (self.frame.size.width - cellVisibleFrame.size.width)/2;
            cellVisibleFrame.size = self.frame.size;
            break;
        case MDHorizontalListViewPositionNone:
        default: break;
    }

    if (cellVisibleFrame.origin.x < 0.0) {
        cellVisibleFrame.origin.x = 0.0;
    } else if (cellVisibleFrame.origin.x > self.contentSize.width - self.frame.size.width) {
        cellVisibleFrame.origin.x = self.contentSize.width - self.frame.size.width;
    }

    [self scrollRectToVisible:cellVisibleFrame animated:animated];
}

- (void)_selectIndexProgress:(CGFloat)progress animated:(BOOL)animated nearestPosition:(MDHorizontalListViewPosition)position {
    if (_allowsMultipleSelection || !_selectedIndexes.count) return;
    if (progress < 0 || progress >= _numberOfCells) return;

    [self _updateSelectIndexProgress:progress animated:animated];

    NSUInteger index = floor(progress);
    NSUInteger nextIndex = index + 1;

    CGRect frame = CGRectFromString(_cellFrames[index]);
    if (nextIndex < _numberOfCells) {
        CGRect nextFrame = CGRectFromString(_cellFrames[nextIndex]);

        frame.size.width = CGRectGetMaxX(nextFrame) - CGRectGetMinX(frame);
    }

    switch (position) {
        case MDHorizontalListViewPositionLeft:
            frame.size = self.frame.size; break;
        case MDHorizontalListViewPositionRight:
            frame.origin.x += frame.size.width - self.frame.size.width;
            frame.size = self.frame.size;
            break;
        case MDHorizontalListViewPositionCenter:
            frame.origin.x -= (self.frame.size.width - frame.size.width)/2;
            frame.size = self.frame.size;
            break;
        case MDHorizontalListViewPositionNone:
        default: break;
    }

    if (frame.origin.x < 0.0) {
        frame.origin.x = 0.0;
    } else if (frame.origin.x > self.contentSize.width - self.frame.size.width) {
        frame.origin.x = self.contentSize.width - self.frame.size.width;
    }

    [self scrollRectToVisible:frame animated:animated];
}

- (void)_updateSelectIndexProgress:(CGFloat)progress animated:(BOOL)animated {
    _indexProgress = progress;

    NSUInteger index = floor(progress);
    NSUInteger nextIndex = index + 1;

    NSString *frameString = _cellFrames[index];
    [self _selectIndexProgress:progress forCell:_visibleCells[frameString] animated:animated];

    NSString *nextFrameString = nil;
    if (nextIndex < _numberOfCells) {
        nextFrameString = _cellFrames[nextIndex];
        [self _selectIndexProgress:progress forCell:_visibleCells[nextFrameString] animated:animated];
    }

    [_visibleCells enumerateKeysAndObjectsUsingBlock:^(NSString *key, MDHorizontalListViewCell *cell, BOOL *stop) {
        if ([key isEqualToString:frameString] || [key isEqualToString:nextFrameString]) return;

        [cell setSelectedProgress:0 animated:animated];
    }];
    [self _updateIndicator];
}

- (void)_selectIndexProgress:(CGFloat)progress forCell:(MDHorizontalListViewCell *)cell animated:(BOOL)animated {
    progress = cell.index - progress;
    progress = MAX(progress, -1);
    progress = MIN(progress, 1);
    if (progress == 1) progress = 0;

    [cell setSelectedProgress:progress animated:animated];
}

- (void)_selectCellAtIndex:(NSInteger)index animated:(BOOL)animated nearestPosition:(MDHorizontalListViewPosition)position {
    [_selectedIndexes addIndex:index];

    NSString *frameString = _cellFrames[index];
    MDHorizontalListViewCell *cell = _visibleCells[frameString];

    if (cell) [cell setSelected:YES animated:animated];
    [self _updateIndicator];

    if (position != MDHorizontalListViewPositionNone) {
        [self scrollToIndex:index animated:animated nearestPosition:position];
    }
    if (!_allowsMultipleSelection) {
        [self _updateSelectIndexProgress:index animated:animated];
    }
}

- (void)_deselectCellAtIndex:(NSInteger)index animated:(BOOL)animated {
    [_selectedIndexes removeIndex:index];

    NSString *frameString = _cellFrames[index];
    MDHorizontalListViewCell *cell = _visibleCells[frameString];

    if (cell) [cell setSelected:NO animated:animated];
    [self _updateIndicator];
}

- (void)_highlightCellAtIndex:(NSInteger)index animated:(BOOL)animated {
    [_mainLock lock];
    [_highlightedIndexes addIndex:index];

    NSString *frameString = _cellFrames[index];

    MDHorizontalListViewCell *cell = _visibleCells[frameString];
    if (cell) [cell setHighlighted:YES animated:animated];
    
    [_mainLock unlock];
}

- (void)_unhighlightCellAtIndex:(NSInteger)index animated:(BOOL)animated {
    [_mainLock lock];
    [_highlightedIndexes removeIndex:index];

    NSString *frameString = _cellFrames[index];
    MDHorizontalListViewCell *cell = _visibleCells[frameString];
    if (cell) [cell setHighlighted:NO animated:animated];
    
    [_mainLock unlock];
}

- (BOOL)_shouldSelectCellAtIndex:(NSInteger)index {
    return _allowsMultipleSelection || ![_selectedIndexes count] || ([_selectedIndexes count] == 1 && _selectedIndexes.firstIndex != index);
}

- (BOOL)_shouldDeselectCellAtIndex:(NSInteger)index {
    return _allowsNoneSelection || [_selectedIndexes count] > 1;
}

#pragma mark - actions

- (void)didTapCell:(UITapGestureRecognizer *)tapGestureRecognizer {
    MDHorizontalListViewCell *cell = (MDHorizontalListViewCell *)tapGestureRecognizer.view;
    [self _unhighlightCellAtIndex:cell.index animated:NO];

    BOOL select = !cell.selected;
    if (select) {
        BOOL shouldSelect = [self _shouldSelectCellAtIndex:cell.index];
        if (!shouldSelect) return;

        [self selectCellAtIndex:cell.index animated:YES];
        if ([_delegate respondsToSelector:@selector(horizontalListView:didSelectCellAtIndex:)]) {
            [_delegate horizontalListView:self didSelectCellAtIndex:cell.index];
        }
    } else {
        BOOL shouldDeselect = [self _shouldDeselectCellAtIndex:cell.index];
        if (!shouldDeselect) return;

        [self deselectCellAtIndex:cell.index animated:YES];
        if (!select && [_delegate respondsToSelector:@selector(horizontalListView:didDeselectCellAtIndex:)]) {
            [_delegate horizontalListView:self didDeselectCellAtIndex:cell.index];
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(MDHorizontalListTapGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([gestureRecognizer isKindOfClass:[MDHorizontalListTapGestureRecognizer class]]) {
        MDHorizontalListViewCell *cell = (MDHorizontalListViewCell *)gestureRecognizer.view;
        [self _highlightCellAtIndex:cell.index animated:YES];
    }
    return YES;
}

- (BOOL)gestureRecognizer:(MDHorizontalListTapGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[MDHorizontalListTapGestureRecognizer class]]) {
        MDHorizontalListViewCell *cell = (MDHorizontalListViewCell *)gestureRecognizer.view;
        [self _unhighlightCellAtIndex:cell.index animated:YES];
        return NO;
    }
    return YES;
}

#pragma mark - UIScrollViewDelegste

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self _updateVisibleCells];
        
    if ([_delegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [_delegate scrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(scrollViewDidZoom:)]) {
        [_delegate scrollViewDidZoom:scrollView];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
        [_delegate scrollViewWillBeginDragging:scrollView];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if ([_delegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) {
        [_delegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if ([_delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [_delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)]) {
        [_delegate scrollViewWillBeginDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [_delegate scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
        [_delegate scrollViewDidEndScrollingAnimation:scrollView];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
        return [_delegate viewForZoomingInScrollView:scrollView];
    }
    return nil;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    if ([_delegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)]) {
        [_delegate scrollViewWillBeginZooming:scrollView withView:view];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    if ([_delegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)]) {
        [_delegate scrollViewDidEndZooming:scrollView withView:view atScale:scale];
    }
}
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)]) {
        return [_delegate scrollViewShouldScrollToTop:scrollView];
    }
    return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(scrollViewDidScrollToTop:)]) {
        [_delegate scrollViewDidScrollToTop:scrollView];
    }
}

@end
