//
//  ViewController.m
//  MDHorizontalListView
//
//  Created by xulinfeng on 2018/8/24.
//  Copyright © 2018年 modool. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    _horizontalView = [[MDHorizontalListView alloc] initWithFrame:CGRectMake(0, 0, 300, 60)];
    [self.view addSubview:_horizontalView];

    _horizontalView.delegate = self;
    _horizontalView.dataSource = self;
    _horizontalView.cellSpacing = 0;
    _horizontalView.scrollEnabled = YES;
    _horizontalView.pagingEnabled = YES;

    [_horizontalView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)horizontalListViewNumberOfCells:(MDHorizontalListView *)horizontalListView {
    return 5;
}

- (CGFloat)horizontalListView:(MDHorizontalListView *)horizontalListView widthForCellAtIndex:(NSInteger)index {
    return CGRectGetWidth(horizontalListView.bounds);
}

- (MDHorizontalListViewCell *)horizontalListView:(MDHorizontalListView *)horizontalListView cellAtIndex:(NSInteger)index {
    MDHorizontalListViewCell *cell = [horizontalListView dequeueCellWithReusableIdentifier:NSStringFromClass([MDHorizontalListViewCell class])];
    if (!cell) {
        cell = [[MDHorizontalListViewCell alloc] initWithReuseIdentifier:NSStringFromClass([MDHorizontalListViewCell class])];
    }
    cell.backgroundColor = [UIColor colorWithRed:(arc4random() % 255)/255.0 green:(arc4random() % 255)/255.0 blue:(arc4random() % 255)/255.0 alpha:1.0];

    return cell;
}

- (void)horizontalListView:(MDHorizontalListView *)horizontalListView didSelectCellAtIndex:(NSInteger)index {
    NSLog(@"selected cell %ld", index);
}

- (void)horizontalListView:(MDHorizontalListView *)horizontalListView didDeselectCellAtIndex:(NSInteger)index {
    NSLog(@"deselected cell %ld", index);
}

@end
