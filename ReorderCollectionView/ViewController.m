//
//  ViewController.m
//  ReorderCollectionView
//
//  Created by Evan on 2020/6/16.
//  Copyright © 2020 Evan. All rights reserved.
//

#import "ViewController.h"
#import "JDReorderCollectionView.h"
#import "MyCollectionViewCell.h"

@interface ViewController ()<UICollectionViewDelegate, UICollectionViewDataSource>
{
    NSMutableArray <NSString *> *_dataArr;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self configData];
    [self configCollectionView];
}

- (void)configData {
    _dataArr = [NSMutableArray new];
    for (int i = 0; i < 20; i++) {
        [_dataArr addObject:[NSString stringWithFormat:@"%d", i]];
    }
}

- (void)configCollectionView {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(50, 50);
    flowLayout.minimumInteritemSpacing = 8.f;
    flowLayout.minimumLineSpacing = 8.f;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    JDReorderCollectionView *cv = [[JDReorderCollectionView alloc] initWithFrame:CGRectMake(0, 100, UIScreen.mainScreen.bounds.size.width, 100) collectionViewLayout:flowLayout];
    cv.delegate = self;
    cv.dataSource = self;
    cv.enableReordering = YES;
    cv.needsHapticFeedback = YES;
    [cv registerClass:[MyCollectionViewCell class] forCellWithReuseIdentifier:@"cellId"];
    [self.view addSubview:cv];
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _dataArr.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MyCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellId" forIndexPath:indexPath];
    [cell setModel:_dataArr[indexPath.row]];
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSLog(@"offset: %@\n", NSStringFromCGPoint(scrollView.contentOffset));
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    id m = _dataArr[sourceIndexPath.row];
    [_dataArr removeObjectAtIndex:sourceIndexPath.item];
    [_dataArr insertObject:m atIndex:destinationIndexPath.item];
}

@end
