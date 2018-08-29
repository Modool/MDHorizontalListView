//
//  MDHorizontalListView.m
//  MDHorizontalListView
//
//  Created by Jave on 2018/8/24.
//  Copyright © 2018年 markejave. All rights reserved.
//

#import "MDHorizontalListView.h"

const NSTimeInterval MDHorizontalListViewAnimatedDuration = 0.25;
const CGFloat MDHorizontalListViewIndicatorWidthDynamic = CGFLOAT_MAX;

@interface MDHorizontalListTapGestureRecognizer : UITapGestureRecognizer
@end

@implementation MDHorizontalListTapGestureRecognizer
@end

// Cell class extension to access properties setter
@interface MDHorizontalListViewCell ()

@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, strong) NSString *reusableIdentifier;
@property (nonatomic, assign) UITapGestureRecognizer *tapGestureRecognizer;

@end

@interface MDHorizontalListView () {
    NSRecursiveLock *_lock;
    NSMutableArray<MDHorizontalListViewCell *> *_queueCells;
    NSMutableDictionary<NSString *, MDHorizontalListViewCell *> *_visibleCells;

    NSMutableArray<NSString *> *_cellFrames;
    NSMutableIndexSet *_selectedIndexes;
    NSMutableIndexSet *_highlightedIndexes;

    NSUInteger _numberOfCells;
    CALayer *_indicatorLayer;

    BOOL _loaded;
    BOOL _layoutEver;
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
    _lock = nil;
    _queueCells = nil;
}

- (void)initiliase {
    if (@available(iOS 11, *)) {
        self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    _lock = [[NSRecursiveLock alloc] init];
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

    _layoutEver = YES;

    if (!_loaded || _numberOfCells != [self _numberOfCell]) {
        [self _reloadData];
    } else {
        [self _updateCellsHeight];
        [self _updateVisibleCells];
    }
    [self _updateIndicator];
}

#pragma mark - accessor

- (NSIndexSet *)selectedIndexes {
    NSIndexSet *indexes = nil;
    [_lock lock];
    indexes = [_selectedIndexes copy];
    [_lock unlock];
    return indexes;
}

- (NSUInteger)selectedIndex {
    NSUInteger index = 0;
    [_lock lock];
    index = [_selectedIndexes firstIndex];
    [_lock unlock];
    return index;
}

- (NSIndexSet *)highlightedIndexes {
    NSIndexSet *indexes = nil;
    [_lock lock];
    indexes = [_highlightedIndexes copy];
    [_lock unlock];
    return indexes;
}

- (void)setCellSpacing:(CGFloat)cellSpacing {
    [_lock lock];
    if (_cellSpacing != cellSpacing) {
        _cellSpacing = cellSpacing;

        [self reloadData];
    }
    [_lock unlock];
}

- (void)setSelectionStyle:(MDHorizontalListViewCellSelectionStyle)selectionStyle {
    [_lock lock];
    if (_selectionStyle != selectionStyle) {
        _selectionStyle = selectionStyle;

        [self _updateSelectedCells];
    }
    [_lock unlock];
}

- (void)setIndicatorEnabled:(BOOL)indicatorEnabled {
    [_lock lock];
    if (_indicatorEnabled != indicatorEnabled) {
        _indicatorEnabled = indicatorEnabled;

        if (!_indicatorEnabled) [self _removeIndicator];
    }
    [_lock unlock];
}

- (void)setIndicatorBackgroundColor:(UIColor *)indicatorBackgroundColor {
    [_lock lock];
    if (_indicatorBackgroundColor != indicatorBackgroundColor) {
        _indicatorBackgroundColor = indicatorBackgroundColor;

        _indicatorLayer.backgroundColor = [indicatorBackgroundColor CGColor];
    }
    [_lock unlock];
}

- (void)setIndicatorHeight:(CGFloat)indicatorHeight {
    [_lock lock];
    if (_indicatorHeight != indicatorHeight) {
        _indicatorHeight = indicatorHeight;

        [self _updateIndicator];
    }
    [_lock unlock];
}

- (void)setIndicatorWidth:(CGFloat)indicatorWidth {
    [_lock lock];
    if (_indicatorWidth != indicatorWidth) {
        _indicatorWidth = indicatorWidth;

        [self _updateIndicator];
    }
    [_lock unlock];
}

#pragma mark - public

- (NSUInteger)indexAtPoint:(CGPoint)point {
    NSUInteger index = NSNotFound;
    [_lock lock];

    index = [_cellFrames indexOfObjectPassingTest:^BOOL(NSString *frameString, NSUInteger idx, BOOL *stop) {
        CGRect frame = CGRectFromString(frameString);
        return CGRectContainsPoint(frame, point);
    }];

    [_lock unlock];
    return index;
}

- (NSIndexSet *)indexesInRect:(CGRect)rect {
    NSIndexSet *indexes = nil;
    [_lock lock];

    indexes = [_cellFrames indexesOfObjectsPassingTest:^BOOL(NSString *frameString, NSUInteger idx, BOOL *stop) {
        CGRect frame = CGRectFromString(frameString);

        return CGRectContainsRect(rect, frame);
    }];

    [_lock unlock];
    return indexes;
}

- (void)reloadData {
    [_lock lock];
    if (_layoutEver) [self _reloadData];
    [_lock unlock];
}

- (MDHorizontalListViewCell *)dequeueCellWithReusableIdentifier:(NSString *)identifier {
    MDHorizontalListViewCell *reusableCell = nil;

    [_lock lock];

    reusableCell = [self _dequeueCellWithReusableIdentifier:identifier];

    [_lock unlock];
    return reusableCell;
}

- (void)scrollToIndex:(NSUInteger)index animated:(BOOL)animated {
    [self scrollToIndex:index animated:animated nearestPosition:MDHorizontalListViewPositionNone];
}

- (void)scrollToIndex:(NSUInteger)index animated:(BOOL)animated nearestPosition:(MDHorizontalListViewPosition)position {
    [_lock lock];
    [self _scrollToIndex:index animated:animated nearestPosition:position];
    [_lock unlock];
}

- (void)selectIndexProgress:(CGFloat)progress animated:(BOOL)animated {
    [self selectIndexProgress:progress animated:animated nearestPosition:MDHorizontalListViewPositionNone];
}

- (void)selectIndexProgress:(CGFloat)progress animated:(BOOL)animated nearestPosition:(MDHorizontalListViewPosition)position {
    [self selectIndexProgress:progress animated:animated nearestPosition:position indicatorSynchronously:YES];
}

- (void)selectIndexProgress:(CGFloat)progress animated:(BOOL)animated nearestPosition:(MDHorizontalListViewPosition)position indicatorSynchronously:(BOOL)indicatorSynchronously {
    [_lock lock];
    [self _selectIndexProgress:progress animated:animated nearestPosition:position];
    if (indicatorSynchronously) [self _updateIndicator];
    [_lock unlock];
}

- (BOOL)selectCellAtIndex:(NSUInteger)index animated:(BOOL)animated {
    BOOL success = NO;
    [_lock lock];
    success = index < _numberOfCells;
    success = success && [self _shouldSelectCellAtIndex:index];
    if (success) {
        [self _prepareToSelectCellAtIndex:index animated:animated];
        [self _cancelIndexProgressIfNeeds];
        [self _updateIndicator];
    }
    [_lock unlock];
    return success;
}

- (void)deselectCellAtIndex:(NSUInteger)index animated:(BOOL)animated {
    [_lock lock];
    if (_selectedIndexes.count > 1 || _allowsNoneSelection) {
        [self _deselectCellAtIndex:index animated:animated];
        [self _updateIndicator];
    }
    [_lock unlock];
}

- (void)reloadCellAtIndex:(NSUInteger)index animated:(BOOL)animated {
    [_lock lock];
    [self _reloadCellAtIndex:index animated:animated];
    [_lock unlock];
}

#pragma mark - private

- (void)_reloadData {
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
    for (NSUInteger i = 0; i < _numberOfCells; i++) {
        CGFloat cellWidth = [_dataSource horizontalListView:self widthForCellAtIndex:i];
        CGRect cellDestinationFrame = CGRectMake(contentWidth, 0.0, cellWidth, self.frame.size.height);

        contentWidth += cellWidth;
        contentWidth += ((_numberOfCells > 1 && i < _numberOfCells - 1) ? _cellSpacing : 0.0);

        [_cellFrames addObject:NSStringFromCGRect(cellDestinationFrame)];
    }
    self.contentOffset = CGPointMake(-self.contentInset.left, 0);
    self.contentSize = CGSizeMake(contentWidth, self.frame.size.height);
    // add the visible cells
    [self _updateVisibleCells];

    if (!_allowsNoneSelection && _cellFrames.count) [self selectCellAtIndex:0 animated:YES];

    _loaded = YES;
}

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

        frame.size.width = CGRectGetWidth(frame) + (CGRectGetWidth(nextFrame) - CGRectGetWidth(frame) + _cellSpacing) * offset;
        frame.origin.x = CGRectGetMinX(frame) + (CGRectGetMinX(nextFrame) - CGRectGetMinX(frame) - _cellSpacing) * offset;
    }

    CGFloat height = _indicatorHeight;
    CGFloat width = _indicatorWidth != MDHorizontalListViewIndicatorWidthDynamic ? _indicatorWidth : frame.size.width;
    frame = CGRectMake(CGRectGetMinX(frame) - (CGRectGetWidth(frame) - width) / 2, CGRectGetHeight(self.bounds) - height, width, height);

    _indicatorLayer.frame = frame;
}

- (NSUInteger)_numberOfCell {
    return [_dataSource horizontalListViewNumberOfCells:self];
}

- (MDHorizontalListViewCell *)_loadCellAtIndex:(NSUInteger)index {
    MDHorizontalListViewCell *cell = [_dataSource horizontalListView:self cellAtIndex:index];
    NSAssert(cell != nil, @"Cell can not be nil.");

    cell.index = index;
    cell.selectedColor = [self _selectionColor];

    NSString *frameString = _cellFrames[index];
    [_visibleCells setObject:cell forKey:frameString];

    UITapGestureRecognizer *tapGestureRecognizer = [[MDHorizontalListTapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapCell:)];
    tapGestureRecognizer.delegate = self;

    cell.tapGestureRecognizer = tapGestureRecognizer;
    [cell addGestureRecognizer:tapGestureRecognizer];

    [self insertSubview:cell atIndex:0];

    return cell;
}

- (NSIndexSet *)_visibleIndexes {
    NSMutableIndexSet *visibleIndexes = [NSMutableIndexSet indexSet];
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
    return [visibleIndexes copy];
}

- (CGRect)_visibleRect {
    CGRect visibleRect;

    visibleRect.origin = self.contentOffset;
    visibleRect.size = self.frame.size;

    return visibleRect;
}

- (void)_reloadAtIndex:(NSUInteger)index animated:(BOOL)animated{
    NSString *frameString = _cellFrames[index];
    CGRect frame = CGRectFromString(frameString);

    CGFloat width = [_dataSource horizontalListView:self widthForCellAtIndex:index];
    CGFloat offset = width - CGRectGetWidth(frame);

    frame.size.width = width;
    NSString *newFrameString = NSStringFromCGRect(frame);
    _cellFrames[index] = newFrameString;

    CGSize contentSize = self.contentSize;
    contentSize.width += offset;

    self.contentSize = contentSize;

    MDHorizontalListViewCell *cell = _visibleCells[frameString];
    if (cell) {
        MDHorizontalListViewCell *newCell = [_dataSource horizontalListView:self cellAtIndex:index];
        newCell.frame = CGRectFromString(newFrameString);

        _visibleCells[frameString] = newCell;
        [self _transitFromCell:cell toCell:newCell animted:animated];
    }

    if (offset == 0) return;
    for (NSUInteger i = index + 1; i < _numberOfCells; i++) {
        CGRect frame = CGRectFromString(_cellFrames[i]);
        frame.origin.x += offset;
        NSString *frameString = NSStringFromCGRect(frame);

        _cellFrames[i] = frameString;
    }
    if (!animated) {
        [self _updateVisibleCells];
    } else {
        [UIView animateWithDuration:MDHorizontalListViewAnimatedDuration
                         animations:^{
                             [self _updateVisibleCells];
                         } completion:^(BOOL finished) {
                             [self _updateIndicator];
                         }];
    }
}

- (void)_transitFromCell:(MDHorizontalListViewCell *)fromCell toCell:(MDHorizontalListViewCell *)toCell animted:(BOOL)animated{
    [self insertSubview:toCell aboveSubview:fromCell];
    if (!animated) {
        [fromCell removeFromSuperview];
    } else {
        toCell.alpha = 0.f;
        [UIView animateWithDuration:MDHorizontalListViewAnimatedDuration
                         animations:^{
                             fromCell.alpha = 0.f;
                             toCell.alpha = 1.f;
                         }
                         completion:^(BOOL finished) {
                             fromCell.alpha = 1.f;
                             [fromCell removeFromSuperview];
                         }];
    }
}

- (void)_updateCellsHeight {
    CGFloat height = self.bounds.size.height;
    NSArray *cellFrames = [_cellFrames copy];

    [cellFrames enumerateObjectsUsingBlock:^(NSString *cellFrame, NSUInteger idx, BOOL *stop) {
        CGRect frame = CGRectFromString(cellFrame);
        CGFloat cellHeight = frame.size.height;

        if (cellHeight != height) {
            frame.size.height = height;

            self->_cellFrames[idx] = NSStringFromCGRect(frame);
        }
    }];
}

- (void)_updateVisibleCells {
    NSIndexSet *visibleIndexes = [self _visibleIndexes];

    NSArray *cellFrames = [_cellFrames copy];
    NSIndexSet *selectedIndexes = [_selectedIndexes copy];
    NSDictionary<NSString *, MDHorizontalListViewCell *> *visibleCells = [_visibleCells copy];
    NSMutableArray<NSString *> *nonVisibleCellKeys = [NSMutableArray arrayWithArray:[visibleCells allKeys]];

    [visibleIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        NSString *frameString = cellFrames[index];
        MDHorizontalListViewCell *cell = visibleCells[frameString];
        // already on view
        if ([nonVisibleCellKeys containsObject:frameString]) {
            [nonVisibleCellKeys removeObject:frameString];
        } else {
            cell = [self _loadCellAtIndex:index];
        }
        cell.frame = CGRectFromString(frameString);

        // handle selection
        BOOL selected = [selectedIndexes containsIndex:index];
        [cell setSelected:selected animated:NO];
    }];
    // enqueue unused cells
    for (NSString *unusedCellKey in nonVisibleCellKeys) {
        MDHorizontalListViewCell *cell = visibleCells[unusedCellKey];

        [self _enqueueCell:cell forKey:unusedCellKey];
    }

    if (_indexProgress >= 0 && _indexProgress < _cellFrames.count) {
        [self _updateSelectIndexProgress:_indexProgress animated:NO];
    }
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
    [_queueCells addObject:cell];

    [cell removeFromSuperview];
    [cell removeGestureRecognizer:cell.tapGestureRecognizer];

    cell.index = -1;

    [_visibleCells removeObjectForKey:frameKey];
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

- (void)_scrollToIndex:(NSUInteger)index animated:(BOOL)animated nearestPosition:(MDHorizontalListViewPosition)position {
    if (index >= _numberOfCells) return;

    CGRect frame = CGRectFromString(_cellFrames[index]);
    [self _scrollToRect:frame animated:animated nearestPosition:position];
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
    [self _scrollToRect:frame animated:animated nearestPosition:position];
}

- (void)_scrollToRect:(CGRect)rect animated:(BOOL)animated nearestPosition:(MDHorizontalListViewPosition)position {
    if (position == MDHorizontalListViewPositionNone) return;

    CGFloat offsetX = rect.origin.x;

    UIEdgeInsets contentInset = self.contentInset;
    CGSize contentSize = self.contentSize;

    CGFloat width = self.frame.size.width;

    switch (position) {
        case MDHorizontalListViewPositionLeft: offsetX = CGRectGetMinX(rect) - contentInset.left; break;
        case MDHorizontalListViewPositionRight: offsetX = CGRectGetMaxX(rect) - width + contentInset.right; break;
        case MDHorizontalListViewPositionCenter: offsetX = CGRectGetMinX(rect) - (width - CGRectGetWidth(rect)) / 2.; break;
        default: break;
    }

    offsetX = MAX(offsetX, -self.contentInset.left);
    offsetX = MIN(offsetX, contentInset.right + contentSize.width - width);

    [self setContentOffset:CGPointMake(offsetX, 0) animated:animated];
}

- (void)_updateSelectIndexProgress:(CGFloat)progress animated:(BOOL)animated {
    if (progress < 0 || progress >= _numberOfCells) return;

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
}

- (void)_selectIndexProgress:(CGFloat)progress forCell:(MDHorizontalListViewCell *)cell animated:(BOOL)animated {
    if (progress < 0 || progress >= _numberOfCells) return;

    progress = cell.index - progress;
    progress = MAX(progress, -1);
    progress = MIN(progress, 1);
    if (progress == 1) progress = 0;

    [cell setSelectedProgress:progress animated:animated];
}

- (void)_prepareToSelectCellAtIndex:(NSUInteger)index animated:(BOOL)animated{
    if (index >= _numberOfCells) return;

    if (!_allowsMultipleSelection && [_selectedIndexes count] == 1 && _selectedIndexes.firstIndex != index) {
        [self _deselectCellAtIndex:_selectedIndexes.firstIndex animated:animated];
    }

    [self _selectCellAtIndex:index animated:animated];
}

- (void)_selectCellAtIndex:(NSUInteger)index animated:(BOOL)animated {
    if (index >= _numberOfCells) return;

    [_selectedIndexes addIndex:index];

    NSString *frameString = _cellFrames[index];
    MDHorizontalListViewCell *cell = _visibleCells[frameString];

    if (cell) [cell setSelected:YES animated:animated];
}

- (void)_deselectCellAtIndex:(NSUInteger)index animated:(BOOL)animated {
    if (index >= _numberOfCells) return;

    [_selectedIndexes removeIndex:index];

    NSString *frameString = _cellFrames[index];
    MDHorizontalListViewCell *cell = _visibleCells[frameString];

    if (cell) [cell setSelected:NO animated:animated];
}

- (void)_reloadCellAtIndex:(NSUInteger)index animated:(BOOL)animated {
    if (index >= _numberOfCells) return;

    [self _cancelIndexProgressIfNeeds];
    [self _reloadAtIndex:index animated:animated];
    [self _updateIndicator];
}

- (void)_highlightCellAtIndex:(NSUInteger)index animated:(BOOL)animated {
    if (index >= _numberOfCells) return;

    [_highlightedIndexes addIndex:index];

    NSString *frameString = _cellFrames[index];

    MDHorizontalListViewCell *cell = _visibleCells[frameString];
    if (cell) [cell setHighlighted:YES animated:animated];
}

- (void)_unhighlightCellAtIndex:(NSUInteger)index animated:(BOOL)animated {
    if (index >= _numberOfCells) return;

    [_highlightedIndexes removeIndex:index];

    NSString *frameString = _cellFrames[index];
    MDHorizontalListViewCell *cell = _visibleCells[frameString];
    if (cell) [cell setHighlighted:NO animated:animated];
}

- (void)_cancelIndexProgressIfNeeds {
    if (_allowsMultipleSelection || _allowsNoneSelection) return;

    [self _updateSelectIndexProgress:_selectedIndexes.firstIndex animated:NO];
}

- (BOOL)_shouldSelectCellAtIndex:(NSUInteger)index {
    if (index >= _numberOfCells) return NO;

    BOOL shouldSelect = _allowsMultipleSelection || ![_selectedIndexes count] || ([_selectedIndexes count] == 1 && _selectedIndexes.firstIndex != index);

    if ([self.delegate respondsToSelector:@selector(horizontalListView:shouldSelectCellAtIndex:)]) {
        shouldSelect = shouldSelect && [self.delegate horizontalListView:self shouldSelectCellAtIndex:index];
    }
    return shouldSelect;
}

- (BOOL)_shouldDeselectCellAtIndex:(NSUInteger)index {
    if (index >= _numberOfCells) return NO;

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
        if ([self.delegate respondsToSelector:@selector(horizontalListView:didSelectCellAtIndex:)]) {
            [self.delegate horizontalListView:self didSelectCellAtIndex:cell.index];
        }
    } else {
        BOOL shouldDeselect = [self _shouldDeselectCellAtIndex:cell.index];
        if (!shouldDeselect) return;

        [self deselectCellAtIndex:cell.index animated:YES];
        if (!select && [self.delegate respondsToSelector:@selector(horizontalListView:didDeselectCellAtIndex:)]) {
            [self.delegate horizontalListView:self didDeselectCellAtIndex:cell.index];
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

@end
