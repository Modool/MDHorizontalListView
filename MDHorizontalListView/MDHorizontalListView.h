//
//  MDHorizontalListView.h
//  MDHorizontalListView
//
//  Created by xulinfeng on 2018/8/24.
//  Copyright © 2018年 markejave. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MDHorizontalListViewCell.h"

/** Scroll position enum type declaration */
typedef NS_ENUM(NSUInteger, MDHorizontalListViewPosition) {
    MDHorizontalListViewPositionNone,
    MDHorizontalListViewPositionLeft,       /** Cell alignment from the left side of the list view */
    MDHorizontalListViewPositionRight,      /** Cell alignment from the right side of the list view */
    MDHorizontalListViewPositionCenter,     /** Cell alignment at the center of the list view */
};

typedef NS_ENUM(NSUInteger, MDHorizontalListViewCellSelectionStyle) {
    MDHorizontalListViewCellSelectionStyleNone = 0,
    MDHorizontalListViewCellSelectionStyleGray,
    MDHorizontalListViewCellSelectionStyleBlue,
};

UIKIT_EXTERN const CGFloat MDHorizontalListViewIndicatorWidthDynamic;

NS_ASSUME_NONNULL_BEGIN

@class MDHorizontalListView;

/**
 *  This protocol rapresent the MDHorizontalListView datasource
 *
 *  You MUST implement all the datasource method for the correct behavior of the horizontal list,
 *  none of them are optional.
 */
@protocol MDHorizontalListViewDataSource <NSObject>

/**
 *  Method to get the number of cells to display in the datasource
 *
 *  @param horizontalListView - the MDHorizontalListView asking for the number if cells to diplay
 *
 *  @return NSInteger the number of cells to display
 */
- (NSInteger)horizontalListViewNumberOfCells:(MDHorizontalListView *)horizontalListView;

/**
 *  Method to get the width of cell to display at a specific index
 *
 *  @param horizontalListView - the MDHorizontalListView asking for the width of the cell to diplay
 *  @param index - the given index of the cell asking for the width
 *
 *  @return CGFloat the width of the cell to display
 */
- (CGFloat)horizontalListView:(MDHorizontalListView *)horizontalListView widthForCellAtIndex:(NSInteger)index;

/**
 *  Method to get the width MDHorizontalListViewCell view to display at a specific index
 *
 *  @param horizontalListView - the MDHorizontalListView asking for the MDHorizontalListViewCell view to diplay
 *  @param index - the given index of the cell asking for the view to display
 *
 *  @return MDHorizontalListViewCell the cell to display
 */
- (MDHorizontalListViewCell *)horizontalListView:(MDHorizontalListView *)horizontalListView cellAtIndex:(NSInteger)index;

@end

/**
 *  This protocol rapresent the MDHorizontalListView delegate, the optional method are called to handle selections of the cells
 *
 *  MDHorizontalListViewDelegate is conform to the UIScrollViewDelegate
 */
@protocol MDHorizontalListViewDelegate <UIScrollViewDelegate>

@optional

/**
 *  Method called when a cell will be selected at a specific index
 *
 *  @param horizontalListView - the MDHorizontalListView of the selected cell
 *  @param index - the given index of the selected cell
 *
 *  @return BOOL Allow to selected
 */
- (BOOL)horizontalListView:(MDHorizontalListView *)horizontalListView shouldSelectCellAtIndex:(NSInteger)index;

/**
 *  Method called when a cell is selected at a specific index
 *
 *  @param horizontalListView - the MDHorizontalListView of the selected cell
 *  @param index - the given index of the selected cell
 */
- (void)horizontalListView:(MDHorizontalListView *)horizontalListView didSelectCellAtIndex:(NSInteger)index;

/**
 *  Method called when a cell is deselected at a specific index
 *
 *  @param horizontalListView - the MDHorizontalListView of the deselected cell
 *  @param index - the given index of the deselected cell
 */
- (void)horizontalListView:(MDHorizontalListView *)horizontalListView didDeselectCellAtIndex:(NSInteger)index;

@end

/**
 *  MDHorizontalListView is a UIScrollView subclass implementing a scrollable horizontal datasource of reusable MDHorizontalListViewCell
 *
 *  like UITableView, MDHorizontalListView implement cells reusability using an identifier that should be assinged to the same kind of cells
 */
@interface MDHorizontalListView : UIScrollView <UIScrollViewDelegate, UIGestureRecognizerDelegate>

/** The MDHorizontalListViewDelegate is conform to UIScrollView and should be implemented to handle cells selections */
@property (nonatomic, weak, nullable) id<MDHorizontalListViewDelegate> delegate;

/** The list datasource MUST be implemented to populate the list */
@property (nonatomic, weak, nullable) id<MDHorizontalListViewDataSource> dataSource;

/** Style for selected cell */
@property (nonatomic, assign) MDHorizontalListViewCellSelectionStyle selectionStyle;

/** Allow none selection */
@property (nonatomic, assign) BOOL allowsNoneSelection;

/** Allow multiple selections */
@property (nonatomic, assign) BOOL allowsMultipleSelection;

/** The selected indexes of cells. */
@property (nonatomic, copy, readonly) NSIndexSet *selectedIndexes;

/** The index of selected cell. */
@property (nonatomic, assign, readonly) NSUInteger selectedIndex;

/** Ability of highlight state, it's unavailabel if NO. */
@property (nonatomic, assign) BOOL highlightEnabled;

/** The hightlighted indexes of cells. */
@property (nonatomic, copy, readonly) NSIndexSet *highlightedIndexes;

/** Spacing between cells, the default value is 0.0f */
@property (nonatomic, assign) CGFloat cellSpacing;

/** Ability of indicator, it's unavailabel if NO. */
@property (nonatomic, assign, getter=isIndicatorEnabled) BOOL indicatorEnabled;

/** background color of indicator, default is 2.f */
@property (nonatomic, strong, readonly, nullable) UIView *indicatorView;

/** inset of indicator, default is UIEdgeInsetsZero, nil if indicatorEnabled is NO. */
@property (nonatomic, assign) UIEdgeInsets indicatorInset;

/** Height of indicator, default is 2.f */
@property (nonatomic, assign) CGFloat indicatorHeight;

/** Width of indicator, default is dynamic */
@property (nonatomic, assign) CGFloat indicatorWidth;

/** To update index progress while index updating.*/
@property (nonatomic, assign) BOOL indexProgressSynchronous;

/** The index progress for indicator. */
@property (nonatomic, assign) CGFloat indexProgress;

/**
 *  Method to update index progress, single selection only.
 *
 *  @param indexProgress - the index progress of the list to select
 *  @param animated - perform the scrolling using an animatiom
 *
 *  the nearest position containing the cell frame depending to the scrolling direction.
 */
- (void)setIndexProgress:(CGFloat)indexProgress animated:(BOOL)animated;

/**
 *  Method to update index progress, single selection only.
 *
 *  @param indexProgress - the index progress of the list to select
 *  @param animated - perform the scrolling using an animatiom
 *  @param position - the nearest position to scroll the list to the cell's view frame
 *
 *  @discussion this method use UIScrollView 'scrollRectToVisible:animated:', if MDHorizontalListViewPositionNone is used
 *  the nearest position containing the cell frame depending to the scrolling direction.
 */
- (void)setIndexProgress:(CGFloat)indexProgress animated:(BOOL)animated nearestPosition:(MDHorizontalListViewPosition)position;

/**
 *  Method to scroll with index progress.
 *
 *  @param indexProgress - the index progress of the list to select
 *  @param animated - perform the scrolling using an animatiom
 *
 *  @discussion this method use UIScrollView 'scrollRectToVisible:animated:', if MDHorizontalListViewPositionNone is used
 *  the nearest position containing the cell frame depending to the scrolling direction.
 */
- (void)scrollToIndexProgress:(CGFloat)indexProgress animated:(BOOL)animated;

/**
 *  Method to scroll with index progress.
 *
 *  @param indexProgress - the index progress of the list to select
 *  @param animated - perform the scrolling using an animatiom
 *  @param position - the nearest position to scroll the list to the cell's view frame
 *
 *  @discussion this method use UIScrollView 'scrollRectToVisible:animated:', if MDHorizontalListViewPositionNone is used
 *  the nearest position containing the cell frame depending to the scrolling direction.
 */
- (void)scrollToIndexProgress:(CGFloat)indexProgress animated:(BOOL)animated nearestPosition:(MDHorizontalListViewPosition)position;

/**
 *  Method to map index with point
 *
 *  Calling this method to map index from the whole visible cells
 */
- (NSUInteger)indexAtPoint:(CGPoint)point;

/**
 *  Method to map index with point
 *
 *  Calling this method to map index from the whole visible cells
 */
- (NSIndexSet *)indexesInRect:(CGRect)rect;

/**
 *  Method to reload the list datasource
 *
 *  Calling this method the whole datasource will be rebuilt also the contentsize of the scrollview will change, but not the contetoffset
 *  the datasource delegate method will be called to build it
 */
- (void)reloadData;

/**
 *  Method to dequeue unused cells, when a cell go outside the view bound is enqueued to be reused
 *
 *  Use this method to implement the cells reusability to save memory, each kind of cell should have is own identifier
 *  if an enqueued cell is dequeued can be reused to be displayed at a different index rather than allocate a new cell
 */
- (MDHorizontalListViewCell *_Nullable)dequeueCellWithReusableIdentifier:(NSString *)identifier;

/**
 *  Method to scroll the list to a specific index,
 *  calling this method is like call 'scrollToIndex:animated:nearestPosition:' using MDHorizontalListViewPositionNone
 *
 *  @param index - the index of the list to scroll to
 *  @param animated - perform the scrolling using an animatiom
 */
- (void)scrollToIndex:(NSUInteger)index animated:(BOOL)animated;

/**
 *  Method to scroll the list to a specific index,
 *  calling this method is like call 'scrollToIndex:animated:nearestPosition:' using MDHorizontalListViewPositionNone
 *
 *  @param index - the index of the list to scroll to
 *  @param animated - perform the scrolling using an animatiom
 *  @param position - the nearest position to scroll the list to the cell's view frame
 *
 *  @discussion this method use UIScrollView 'scrollRectToVisible:animated:', if MDHorizontalListViewPositionNone is used
 *  the nearest position containing the cell frame depending to the scrolling direction.
 */
- (void)scrollToIndex:(NSUInteger)index animated:(BOOL)animated nearestPosition:(MDHorizontalListViewPosition)position;

/**
 *  Method to set selected a cell at a specific index
 *
 *  @param index - the given index to select in the datasource
 *  @param animated - select the cell using animation (the cell it self has to implement the animation)
 */
- (BOOL)selectCellAtIndex:(NSUInteger)index animated:(BOOL)animated;

/**
 *  Method to set deselected a cell at a specific index
 *
 *  @param index - the given index to deselect in the datasource
 *  @param animated - deselect the cell using animation (the cell it self has to implement the animation)
 */
- (void)deselectCellAtIndex:(NSUInteger)index animated:(BOOL)animated;

/**
 *  Method to reload a cell at a specific index
 *
 *  @param index - the given index to deselect in the datasource
 *  @param animated - deselect the cell using animation (the cell it self has to implement the animation)
 */
- (void)reloadCellAtIndex:(NSUInteger)index animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
