//
//  ViewController.m
//  MDHorizontalListView
//
//  Created by xulinfeng on 2018/8/24.
//  Copyright © 2018年 modool. All rights reserved.
//

#import "ViewController.h"

@interface TestCell : MDHorizontalListViewCell

@property (nonatomic, strong) UIView *fadeView;

@end

@implementation TestCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        self.fadeView = [[UIView alloc] init];
        self.fadeView.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.5];
        
        [self.contentView addSubview:self.fadeView];
    }
    return self;
}

- (void)setSelectedProgress:(CGFloat)progress animated:(BOOL)animated {
    [super setSelectedProgress:progress animated:animated];

    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat x = progress >= 0 ? 0 : -width * progress;
    CGFloat w = progress >= 0 ? width * progress : width - x;

    self.fadeView.frame = CGRectMake(x, 0, w, CGRectGetHeight(self.bounds));
}

@end

@interface ViewController ()<MDHorizontalListViewDataSource, MDHorizontalListViewDelegate>

@property (strong, nonatomic) MDHorizontalListView *horizontalView;
@property (strong, nonatomic) UIButton *selectButton;
@property (strong, nonatomic) UIButton *scrollButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    _horizontalView = [[MDHorizontalListView alloc] initWithFrame:CGRectMake(0, 0, 300, 60)];
    [self.view addSubview:_horizontalView];

    _selectButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 300, 80, 80)];
    [_selectButton setTitle:@"Select" forState:UIControlStateNormal];
    [_selectButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_selectButton addTarget:self action:@selector(didClickSelectButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_selectButton];

    _scrollButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 300, 120, 80)];
    [_scrollButton setTitle:@"Select progress" forState:UIControlStateNormal];
    [_scrollButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_scrollButton addTarget:self action:@selector(didClickScrollButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_scrollButton];

    _horizontalView.delegate = self;
    _horizontalView.dataSource = self;
    _horizontalView.cellSpacing = 2.f;
    _horizontalView.allowsNoneSelection = NO;
    _horizontalView.allowsMultipleSelection = NO;
    _horizontalView.selectionStyle = MDHorizontalListViewCellSelectionStyleGray;
    _horizontalView.showsVerticalScrollIndicator = NO;
    _horizontalView.showsHorizontalScrollIndicator = NO;

    _horizontalView.indicatorEnabled = YES;
    _horizontalView.indicatorBackgroundColor = [UIColor greenColor];

    [_horizontalView reloadData];
}

- (IBAction)didClickSelectButton:(id)sender {
    [_horizontalView selectCellAtIndex:4 animated:YES nearestPosition:MDHorizontalListViewPositionCenter];
}

- (IBAction)didClickScrollButton:(id)sender {
    [_horizontalView selectIndexProgress:4.5 animated:YES];
}

#pragma mark - MDHorizontalListViewDataSource, MDHorizontalListViewDelegate

- (NSInteger)horizontalListViewNumberOfCells:(MDHorizontalListView *)horizontalListView {
    return 8;
}

- (CGFloat)horizontalListView:(MDHorizontalListView *)horizontalListView widthForCellAtIndex:(NSInteger)index {
    return 80;
}

- (MDHorizontalListViewCell *)horizontalListView:(MDHorizontalListView *)horizontalListView cellAtIndex:(NSInteger)index {
    TestCell *cell = (TestCell *)[horizontalListView dequeueCellWithReusableIdentifier:NSStringFromClass([TestCell class])];
    if (!cell) {
        cell = [[TestCell alloc] initWithReuseIdentifier:NSStringFromClass([TestCell class])];
    }
    cell.backgroundColor = [UIColor brownColor];

    return cell;
}

- (void)horizontalListView:(MDHorizontalListView *)horizontalListView didSelectCellAtIndex:(NSInteger)index {
    NSLog(@"selected cell %ld", index);
}

- (void)horizontalListView:(MDHorizontalListView *)horizontalListView didDeselectCellAtIndex:(NSInteger)index {
    NSLog(@"deselected cell %ld", index);
}

@end
