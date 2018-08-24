//
//  MDHorizontalListViewCell.m
//  MDHorizontalListView
//
//  Created by Jave on 2018/8/24.
//  Copyright © 2018年 markejave. All rights reserved.
//

#import "MDHorizontalListViewCell.h"

@interface MDHorizontalListViewCell ()

@property (nonatomic, strong) NSString *reusableIdentifier;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation MDHorizontalListViewCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    NSParameterAssert([reuseIdentifier length]);
    
    if (self = [super initWithFrame:CGRectZero]) {
        _reusableIdentifier = reuseIdentifier;
        _contentView = [[UIView alloc] init];
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

    self.contentView.frame = self.bounds;
}

#pragma mark - accessor

- (void)setSelected:(BOOL)selected {
    [self setSelected:selected animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    _selected = selected;
}

- (void)setHighlighted:(BOOL)highlighted {
    [self setHighlighted:highlighted animated:NO];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    _highlighted = highlighted;
}

@end
