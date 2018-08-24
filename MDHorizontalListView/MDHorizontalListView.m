//
//  MDHorizontalListView.m
//  MDHorizontalListView
//
//  Created by Jave on 2018/8/24.
//  Copyright © 2018年 markejave. All rights reserved.
//

#import "MDHorizontalListView.h"

@interface MDHorizontalListTapGestureRecognizer : UITapGestureRecognizer
@end

@implementation MDHorizontalListTapGestureRecognizer
@end

// Cell class extension to access properties setter
@interface MDHorizontalListViewCell ()

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

- (NSIndexSet *)highlightedIndexes {
    return [_highlightedIndexes copy];
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

    NSString *frameString = [_cellFrames objectAtIndex:index];
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
    [_mainLock unlock];
}

- (void)selectCellAtIndex:(NSInteger)index animated:(BOOL)animated {
    [_mainLock lock];

    [_selectedIndexes addIndex:index];

    NSString *frameString = [_cellFrames objectAtIndex:index];
    MDHorizontalListViewCell *cell = [_visibleCells objectForKey:frameString];

    if (cell) [cell setSelected:YES animated:animated];

    [_mainLock unlock];
}

- (void)deselectCellAtIndex:(NSInteger)index animated:(BOOL)animated {
    [_mainLock lock];

    [_selectedIndexes removeIndex:index];

    NSString *frameString = [_cellFrames objectAtIndex:index];
    MDHorizontalListViewCell *cell = [_visibleCells objectForKey:frameString];

    if (cell) [cell setSelected:NO animated:animated];

    [_mainLock unlock];
}

#pragma mark - private

- (NSUInteger)_numberOfCell {
    return [_dataSource horizontalListViewNumberOfCells:self];
}

- (void)_addCellAtIndex:(NSInteger)index {
    MDHorizontalListViewCell *cell = [_dataSource horizontalListView:self cellAtIndex:index];
    cell.index = index;

    NSString *frameString = [_cellFrames objectAtIndex:index];
    [_visibleCells setObject:cell forKey:frameString];

    UITapGestureRecognizer *tapGestureRecognizer = [[MDHorizontalListTapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapCell:)];
    tapGestureRecognizer.delegate = self;

    cell.tapGestureRecognizer = tapGestureRecognizer;
    [cell addGestureRecognizer:tapGestureRecognizer];

    [self addSubview:cell];
}

- (NSIndexSet *)_visibleIndexes {
    NSMutableIndexSet *visibleIndexes = [NSMutableIndexSet indexSet];
    [_mainLock lock];

    CGRect visibleRect = [self _visibleRect];
    BOOL canBreak = NO;  // for a shorter loop... after the first match the next fail mean no more visible cells
    for (int i = 0; i < [_cellFrames count]; i++) {
        NSString *frameString = [_cellFrames objectAtIndex:i];
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
        NSString * frameString = [cellFrames objectAtIndex:index];

        // already on view
        if ([nonVisibleCellKeys containsObject:frameString]) {
            [nonVisibleCellKeys removeObject:frameString];
        } else {
            [self _addCellAtIndex:index];
        }
        // handle selection
        BOOL selected = [selectedIndexes containsIndex:index];
        MDHorizontalListViewCell *cell = [visibleCell objectForKey:frameString];

        cell.frame = CGRectFromString(frameString);

        [cell setSelected:selected animated:NO];
    }];
    // enqueue unused cells
    for (NSString *unusedCellKey in nonVisibleCellKeys) {
        MDHorizontalListViewCell *cell = [visibleCell objectForKey:unusedCellKey];

        [self _enqueueCell:cell forKey:unusedCellKey];
    }
    [_mainLock unlock];
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

    MDHorizontalListViewCell *cell = [_queueCells objectAtIndex:index];
    [_queueCells removeObjectAtIndex:index];

    [cell prepareForReuse];

    return cell;
}

- (void)_highlightCellAtIndex:(NSInteger)index animated:(BOOL)animated {
    [_mainLock lock];
    [_highlightedIndexes addIndex:index];

    NSString *frameString = [_cellFrames objectAtIndex:index];

    MDHorizontalListViewCell *cell = [_visibleCells objectForKey:frameString];
    if (cell) [cell setHighlighted:YES animated:animated];
    
    [_mainLock unlock];
}

- (void)_unhighlightCellAtIndex:(NSInteger)index animated:(BOOL)animated {
    [_mainLock lock];
    [_highlightedIndexes removeIndex:index];

    NSString *frameString = [_cellFrames objectAtIndex:index];
    MDHorizontalListViewCell *cell = [_visibleCells objectForKey:frameString];
    if (cell) [cell setHighlighted:NO animated:animated];
    
    [_mainLock unlock];
}

#pragma mark - actions

- (void)didTapCell:(UITapGestureRecognizer *)tapGestureRecognizer {
    MDHorizontalListViewCell *cell = (MDHorizontalListViewCell *)tapGestureRecognizer.view;
    [self _unhighlightCellAtIndex:cell.index animated:NO];

    BOOL select = !cell.selected;
    if (select) {
        [self selectCellAtIndex:cell.index animated:NO];
    } else {
        [self deselectCellAtIndex:cell.index animated:NO];
    }

    if (select && [_delegate respondsToSelector:@selector(horizontalListView:didSelectCellAtIndex:)]) {
        [_delegate horizontalListView:self didSelectCellAtIndex:cell.index];
    } else if (!select && [_delegate respondsToSelector:@selector(horizontalListView:didDeselectCellAtIndex:)]) {
        [_delegate horizontalListView:self didDeselectCellAtIndex:cell.index];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(MDHorizontalListTapGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([gestureRecognizer isKindOfClass:[MDHorizontalListTapGestureRecognizer class]]) {
        MDHorizontalListViewCell *cell = (MDHorizontalListViewCell *)gestureRecognizer.view;
        [self _highlightCellAtIndex:cell.index animated:NO];
    }
    return YES;
}

- (BOOL)gestureRecognizer:(MDHorizontalListTapGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[MDHorizontalListTapGestureRecognizer class]]) {
        MDHorizontalListViewCell *cell = (MDHorizontalListViewCell *)gestureRecognizer.view;
        [self _unhighlightCellAtIndex:cell.index animated:NO];
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
