//
//  MDHorizontalListViewCell.h
//  MDHorizontalListView
//
//  Created by Jave on 2018/8/24.
//  Copyright © 2018年 markejave. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MDHorizontalListViewCell : UIView

@property (nonatomic, strong, readonly) UIView *contentView;

@property (nonatomic, assign) BOOL selected;
- (void)setSelected:(BOOL)selected animated:(BOOL)animated;

- (void)setSelectedProgress:(CGFloat)progress animated:(BOOL)animated;

@property (nonatomic, assign) BOOL highlighted;
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated;

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier NS_DESIGNATED_INITIALIZER;

- (void)prepareForReuse;

@end
