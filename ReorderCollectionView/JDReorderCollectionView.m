//
//  JDReorderCollectionView.m
//  jiandan
//
//  Created by Evan on 2020/5/21.
//  Copyright © 2020 iqiyi. All rights reserved.
//

#import "JDReorderCollectionView.h"
#import "JDCellReorderable.h"

#define kAttachAnimationDuration    0.25f

@interface JDReorderCollectionView ()

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGes;
@property (nonatomic, strong) NSIndexPath *originalIndexPath;
@property (nonatomic, strong) NSIndexPath *currentIndexPath;
@property (nonatomic, strong) NSIndexPath *tmpIndexPath;

@property (nonatomic, strong) UIView *snapshotView;

@property (nonatomic, assign) BOOL inSwap;
@property (nonatomic, assign) BOOL shouldCancelMove;
@property (nonatomic, assign) JDReorderStatus status;
@end

@implementation JDReorderCollectionView


- (void)setEnableReordering:(BOOL)enableReordering {
    _enableReordering = enableReordering;
    if (!self.longPressGes.view) {
        [self addGestureRecognizer:self.longPressGes];
    }
    self.longPressGes.enabled = _enableReordering;
}

- (void)handleLongPressGes:(UIPanGestureRecognizer *)longPressGes {
    CGPoint location = [longPressGes locationInView:self];
    NSLog(@"location: %@\n", NSStringFromCGPoint(location));
    switch (longPressGes.state) {
        case UIGestureRecognizerStateBegan:
        {
            [self handleLocationBegan:location];
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            [self handleLocationChange:location];
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            if (!_originalIndexPath) return;
            [self handleLocationEnded:location];
            break;
        }
        case UIGestureRecognizerStateCancelled:
        {
            if (!_originalIndexPath) return;
            [self handleLocationEnded:location];
            break;
        }
        default:
            break;
    }
}

- (void)handleLocationBegan:(CGPoint)location {
    NSIndexPath *ip = [self indexPathForItemAtPoint:location];
    if (!ip) return;
    _originalIndexPath = ip;
    _currentIndexPath = ip;
    UICollectionViewCell *fromCell = [self cellForItemAtIndexPath:ip];
    
    if ([fromCell respondsToSelector:@selector(snapshotViewForReordering)]) {
        _snapshotView = [(id)fromCell snapshotViewForReordering];
    } else {
        _snapshotView = [fromCell snapshotViewAfterScreenUpdates:NO];
    }
    
    [self addSubview:_snapshotView];
    _snapshotView.frame = [fromCell.superview convertRect:[fromCell frame] toView:self];
    
    if ([fromCell respondsToSelector:@selector(willBeginDragging)]) {
        [(id)fromCell willBeginDragging];
    }
    
//    if ([fromCell respondsToSelector:@selector(enterReorderingMode)]) {
//        [(id)fromCell enterReorderingMode];
//    }
    
    [UIView animateWithDuration:kAttachAnimationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _snapshotView.center = location;
    } completion:^(BOOL finished) {
      
    }];
}

- (void)handleLocationEnded:(CGPoint)location {
//    if (_inSwap) {
//        _shouldCancelMove = YES;
//    }
    UICollectionViewCell *toCell;
    NSLog(@"swap in process: %d", _inSwap);
    if (_status == JDReorderStatusMoved) {
        // 说明动画没有结束
        toCell = [self cellForItemAtIndexPath:_tmpIndexPath];

    } else {
        toCell = [self cellForItemAtIndexPath:_currentIndexPath];
    }
//    UICollectionViewCell *toCell = [self cellForItemAtIndexPath:_currentIndexPath];
//    if ([toCell respondsToSelector:@selector(willEndDragging)]) {
//        [(id)toCell willEndDragging];
//    }
    
    CGRect endFrame = [toCell.superview convertRect:[toCell frame] toView:self];
    
    [UIView animateWithDuration:kAttachAnimationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _snapshotView.frame = endFrame;
    } completion:^(BOOL finished) {
        [_snapshotView removeFromSuperview];
        _currentIndexPath = nil;
        _originalIndexPath = nil;
        _tmpIndexPath = nil;
        if ([toCell respondsToSelector:@selector(didEndDragging)]) {
            [(id)toCell didEndDragging];
        }
        _status = JDReorderStatusIdle;
    }];
}

/**/
- (void)handleLocationChange:(CGPoint)location {
    if (!_originalIndexPath) return;
    _snapshotView.center = location;
    NSIndexPath *newIp = [self indexPathForItemAtPoint:location];
    if (!newIp) return;
//    NSLog(@"new: %d current: %d\n", newIp.item, _currentIndexPath.item);
    if (![newIp isEqual:_currentIndexPath] && !_inSwap) {
        
        _inSwap = YES;
        [self performBatchUpdates:^{
            _tmpIndexPath = newIp;
            _status = JDReorderStatusMoved;
            [self moveItemAtIndexPath:_currentIndexPath toIndexPath:newIp];
        } completion:^(BOOL finished) {
            NSLog(@"finished: %d", finished);
            _currentIndexPath = newIp;
            _inSwap = NO;
            _status = JDReorderStatusCompleted;
        }];
    }
}
 /**/


/*
- (void)handleLocationChange:(CGPoint)location {
    if (!_originalIndexPath) return;
    _snapshotView.center = location;
    NSIndexPath *newIp = [self indexPathForItemAtPoint:location];
    if (!newIp) return;
//    NSLog(@"new: %d current: %d\n", newIp.item, _currentIndexPath.item);
    if (![newIp isEqual:_currentIndexPath] && !_inSwap) {
        
        _inSwap = YES;
        BOOL directionToRight = _currentIndexPath.item - newIp.item < 0;
        NSInteger gap = (newIp.item - _currentIndexPath.item) * (directionToRight ? 1 : -1);
        NSLog(@"direction: %d, gap: %d\n", directionToRight, gap);
        [self performBatchUpdates:^{
            NSIndexPath *fromIndexPath = _currentIndexPath;
            for (int i = 1; i <= gap; i++) {
                NSIndexPath *toIndexPath = [NSIndexPath indexPathForItem:directionToRight ? (fromIndexPath.item + 1): (fromIndexPath.item - i) inSection:fromIndexPath.section];
                [self moveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
//                [self moveItemAtIndexPath:toIndexPath toIndexPath:fromIndexPath];
                NSLog(@"from %d: to: %d\n", fromIndexPath.item, toIndexPath.item);
                fromIndexPath = toIndexPath;
            }
        } completion:^(BOOL finished) {
            NSLog(@"finished: %d", finished);
            _currentIndexPath = newIp;
            _inSwap = NO;
        }];
    }
}*/


- (UILongPressGestureRecognizer *)longPressGes {
    if (!_longPressGes) {
        _longPressGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGes:)];
    }
    return _longPressGes;
}

@end
