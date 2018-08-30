//
//  MDHorizontalListViewCell.m
//  MDHorizontalListView
//
//  Created by Jave on 2018/8/24.
//  Copyright © 2018年 markejave. All rights reserved.
//

#import "MDHorizontalListViewCell.h"

@interface MDHorizontalListViewCell ()

@property (nonatomic, copy) NSString *reusableIdentifier;

@property (nonatomic, assign) NSUInteger index;

@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@property (nonatomic, strong) UIView *selectionView;

@end

@implementation MDHorizontalListViewCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    NSParameterAssert([reuseIdentifier length]);
    
    if (self = [super initWithFrame:CGRectZero]) {
        _reusableIdentifier = reuseIdentifier;
        _contentView = [[UIView alloc] init];
        _selectionView = [[UIView alloc] init];
        _selectionView.userInteractionEnabled = NO;

        [self addSubview:_contentView];
        [self addSubview:_selectionView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithReuseIdentifier:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithReuseIdentifier:nil];
}

- (void)dealloc {
    if (_tapGestureRecognizer) [self removeGestureRecognizer:_tapGestureRecognizer];
}

#pragma mark - protected

- (void)prepareForReuse {
}

- (void)layoutSubviews {
    [super layoutSubviews];

    _contentView.frame = self.bounds;
    _selectionView.frame = self.bounds;
}

#pragma mark - accessor

- (void)setSelected:(BOOL)selected {
    [self setSelected:selected animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    _selected = selected;

    [self _updateSelectedView:_highlighted || selected animated:animated];
}

- (void)setSelectedProgress:(CGFloat)progress animated:(BOOL)animated {
}

- (void)setHighlighted:(BOOL)highlighted {
    [self setHighlighted:highlighted animated:NO];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    _highlighted = highlighted;

    [self _updateSelectedView:highlighted || _selected animated:animated];
}

- (void)setSelectedColor:(UIColor *)selectedColor {
    if (_selectedColor != selectedColor) {
        _selectedColor = selectedColor;

        [self _updateSelectedView:_selected animated:NO];
    }
}

#pragma mark - private

- (void)_updateSelectedView:(BOOL)enabled animated:(BOOL)animated {
    _selectionView.backgroundColor = enabled ? [self selectedColor] : nil;
    if (!animated || ![self selectedColor]) return;

    _selectionView.alpha = 0.f;
    [UIView animateWithDuration:0.3 animations:^{
        self.selectionView.alpha = 1.f;
    }];
}

@end
