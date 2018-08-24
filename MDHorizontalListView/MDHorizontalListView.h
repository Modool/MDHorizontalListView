//
//  MDHorizontalListView.h
//  MDHorizontalListView
//
//  Created by Jave on 2018/8/24.
//  Copyright © 2018年 markejave. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MDHorizontalListViewCell.h"

/** Scroll position enum type declaration */
typedef NS_ENUM(NSUInteger, MDHorizontalListViewPosition) {
    MDHorizontalListViewPositionNone = 0,   /** No specific position */
    MDHorizontalListViewPositionLeft,       /** Cell alignment from the left side of the list view */
    MDHorizontalListViewPositionRight,      /** Cell alignment from the right side of the list view */
    MDHorizontalListViewPositionCenter,     /** Cell alignment at the center of the list view */
    
};

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
@property (nonatomic, weak) id<MDHorizontalListViewDelegate> delegate;

/** The list datasource MUST be implemented to populate the list */
@property (nonatomic, weak) id<MDHorizontalListViewDataSource> dataSource;

/** The selected indexes of cells. */
@property (nonatomic, copy, readonly) NSIndexSet *selectedIndexes;

/** The hightlighted indexes of cells. */
@property (nonatomic, copy, readonly) NSIndexSet *highlightedIndexes;

/** spacing between cells, the default value is 0.0f */
@property (nonatomic, assign) CGFloat cellSpacing;

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
- (MDHorizontalListViewCell *)dequeueCellWithReusableIdentifier:(NSString *)identifier;

/**
 *  Method to scroll the list to a specific index, 
 *  calling this method is like call 'scrollToIndex:animated:nearestPosition:' using MDHorizontalListViewPositionNone
 *
 *  @param index - the index of the list to scroll to
 *  @param animated - perform the scrolling using an animatiom
 */
- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated;

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
- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated nearestPosition:(MDHorizontalListViewPosition)position;

/**
 *  Method to set selected a cell at a specific index 
 *
 *  @param index - the given index to select in the datasource
 *  @param animated - select the cell using animation (the cell it self has to implement the animation)
 */
- (void)selectCellAtIndex:(NSInteger)index animated:(BOOL)animated;

/**
 *  Method to set deselected a cell at a specific index
 *
 *  @param index - the given index to deselect in the datasource
 *  @param animated - deselect the cell using animation (the cell it self has to implement the animation)
 */
- (void)deselectCellAtIndex:(NSInteger)index animated:(BOOL)animated;

@end
