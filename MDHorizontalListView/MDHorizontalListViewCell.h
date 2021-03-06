//
//  MDHorizontalListViewCell.h
//  MDHorizontalListView
//
//  Created by xulinfeng on 2018/8/24.
//  Copyright © 2018年 markejave. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDHorizontalListViewCell : UIView

@property (nonatomic, strong, readonly) UIView *contentView;

@property (nonatomic, assign) BOOL selected;
- (void)setSelected:(BOOL)selected animated:(BOOL)animated;

- (void)willSelectAtProgress:(CGFloat)progress animated:(BOOL)animated;

@property (nonatomic, assign) BOOL highlighted;
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated;

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier NS_DESIGNATED_INITIALIZER;

- (void)prepareForReuse;

@end

NS_ASSUME_NONNULL_END
