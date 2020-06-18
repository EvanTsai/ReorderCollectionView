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
#define kEdgeStayThreshold          0.2f
#define kEdgeWidthThreshold         30.f
#define kMoveLongStep               6.f
#define kMoveShortStep              2.8f
#define kMoveAccelerateThreshold                   2.f

typedef NS_ENUM(NSUInteger, JDEdgeState) {
    JDEdgeStateNone,
    JDEdgeStateTesting,
    JDEdgeStateTriggered,
};

@interface JDReorderCollectionView ()

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGes;
@property (nonatomic, strong) NSIndexPath *originalIndexPath;
@property (nonatomic, strong) NSIndexPath *currentIndexPath;
@property (nonatomic, strong) UIView *snapshotView;
@property (nonatomic, assign) JDEdgeState edgeState;
@property (nonatomic, assign) NSInteger lastEdge;
@property (nonatomic, assign) NSTimeInterval edgeTestBeginTime;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) UISelectionFeedbackGenerator *feedbackGen;
@end

@implementation JDReorderCollectionView


- (void)setEnableReordering:(BOOL)enableReordering {
    _enableReordering = enableReordering;
    if (!self.longPressGes.view) {
        [self addGestureRecognizer:self.longPressGes];
    }
    self.longPressGes.enabled = _enableReordering;
}

- (UISelectionFeedbackGenerator *)feedbackGen {
    if (!_feedbackGen) {
        _feedbackGen = [UISelectionFeedbackGenerator new];
        [_feedbackGen prepare];
    }
    return _feedbackGen;
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
    if (_needsHapticFeedback) [self.feedbackGen selectionChanged];
    [UIView animateWithDuration:kAttachAnimationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _snapshotView.center = location;
    } completion:^(BOOL finished) {
      
    }];
}


- (void)handleLocationEnded:(CGPoint)location {
    [self resetWindowAndEdge];
    [self invalidateDisplayLink];
    
    UICollectionViewCell *toCell = [self cellForItemAtIndexPath:_currentIndexPath];
    if ([toCell respondsToSelector:@selector(willEndDragging)]) {
        [(id)toCell willEndDragging];
    }
    
    CGRect endFrame = [toCell.superview convertRect:[toCell frame] toView:self];
    
    [UIView animateWithDuration:kAttachAnimationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _snapshotView.frame = endFrame;
    } completion:^(BOOL finished) {
        [_snapshotView removeFromSuperview];
        _snapshotView = nil;
        _currentIndexPath = nil;
        _originalIndexPath = nil;
        if ([toCell respondsToSelector:@selector(didEndDragging)]) {
            [(id)toCell didEndDragging];
        }
    }];
}

/**/
- (void)handleLocationChange:(CGPoint)location {
    if (!_originalIndexPath) return;
    _snapshotView.center = location;
    NSIndexPath *newIp = [self indexPathForItemAtPoint:location];
    if (!newIp) return;
    
    if (![newIp isEqual:_currentIndexPath] ) { //}&& !_inSwap) {
        
        [self performBatchUpdates:^{
            [self moveItemAtIndexPath:_currentIndexPath toIndexPath:newIp];
            [self.dataSource collectionView:self moveItemAtIndexPath:_currentIndexPath toIndexPath:newIp];
            _currentIndexPath = newIp;
            if (_needsHapticFeedback) {
                [self.feedbackGen selectionChanged];
                [self.feedbackGen prepare];
            }
        } completion:^(BOOL finished) {
            NSLog(@"finished: %d", finished);
        }];
    }
    [self handleEdgeCasesWithPoint:location];
}

- (void)handleEdgeCasesWithPoint:(CGPoint)point {

    CGPoint relativePoint = [self convertPoint:point toView:self.window];
    CGRect selfRect = [self.superview convertRect:self.frame toView:self.window];
    if (!CGRectContainsPoint(selfRect, relativePoint)) return;
    
    CGFloat maxX = CGRectGetMaxX(selfRect);
    CGFloat minX = CGRectGetMinX(selfRect);
    
    NSInteger edge = 0;
    if (relativePoint.x - minX < kEdgeWidthThreshold) {
        // 左边边界
        edge = -1;
    } else if (maxX - relativePoint.x < kEdgeWidthThreshold) {
        // 右边边界
        edge = 1;
    }
    if (edge != 1 && edge != -1) {
        // 不管以前是什么，只要现在不在edge就reset
        [self invalidateDisplayLink];
        [self resetWindowAndEdge];
        return;
    }
    if ((_lastEdge == 1 && edge == -1) || (_lastEdge == -1 && edge == 1)) {
      // 从一侧edge切换到另一侧的edge，就需要变成none，重新走一遍下面的判断
        [self invalidateDisplayLink];
        _edgeState = JDEdgeStateNone;
    }
    // 走到这的case就是要么是从中间新到一侧edge，要么是持续呆在了一侧的edge
    // 表示开启
    if (_edgeState == JDEdgeStateTesting) {
        // 之前有
        NSTimeInterval ctime = [self currentTime];
        if (ctime < kEdgeStayThreshold) return;
        _edgeState = JDEdgeStateTriggered;
        // change time to the triggered time
        _edgeTestBeginTime = ctime;
        [self startMovement];
    } else if (_edgeState == JDEdgeStateNone) {
        // 之前没有
        _edgeTestBeginTime = [self currentTime];
        _edgeState = JDEdgeStateTesting;
    } else if (_edgeState == JDEdgeStateTriggered) {
        // 之前有并且已经开始滚动了
        // keep scrolling if possible
//        [self startMovement];
    }
    _lastEdge = edge;
}



- (void)resetWindowAndEdge {
    _lastEdge = 0;
    _edgeState = JDEdgeStateNone;
    _edgeTestBeginTime = 0;
}

- (void)invalidateDisplayLink {
    [_displayLink invalidate];
    _displayLink = nil;
}


- (void)startMovement {
    _displayLink = nil;
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}


- (NSTimeInterval)currentTime {
    return [NSProcessInfo processInfo].systemUptime;
}

- (CADisplayLink *)displayLink {
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(makeMovement:)];
    }
    return _displayLink;
}

- (void)makeMovement:(CADisplayLink *)displayLink {
    NSLog(@"movement");
    CGPoint currentOffset = self.contentOffset;
    CGFloat targetOffsetX = currentOffset.x;
    CGRect oldFrame = _snapshotView.frame;
    CGFloat speed =  [self speed];
    if (_lastEdge == 1) {
        // 右边
        CGFloat maxOffsetX = [self maxOffsetX];
        if (currentOffset.x + speed < maxOffsetX) {
            targetOffsetX += speed;
            oldFrame.origin.x += speed;
        } else {
            [self invalidateDisplayLink];
        }
    } else {
        // 左边
        CGFloat minOffsetX = [self minOffsetX];
        
        if (currentOffset.x - speed > minOffsetX) {
            targetOffsetX -= speed;
            oldFrame.origin.x -= speed;
        } else {
            [self invalidateDisplayLink];
        }
    }
    // offset在变更的同时，_snapshotView也要跟这变位置；
    _snapshotView.frame = oldFrame;
    // 同时也要继续进行交换。所以把contentOffset造成的gesture位置的变更，直接传给handleLocationChange方法，继续进行交换
    [self handleLocationChange:_snapshotView.center];
    [self setContentOffset:CGPointMake(targetOffsetX, 0)];
    //  change snapshot view position
}

- (CGFloat)speed {
    CGFloat delta = [self currentTime] - _edgeTestBeginTime;
    CGFloat speed = MIN(MAX(delta * 3, kMoveShortStep), kMoveLongStep);
    return speed;
//    CGFloat speed =  ([self currentTime] - _edgeTestBeginTime > kMoveAccelerateThreshold) ? kMoveLongStep : kMoveShortStep;
//    return speed;
}

- (CGFloat)minOffsetX {
    return -self.contentInset.left;
}

- (CGFloat)maxOffsetX {
    return self.contentSize.width - self.frame.size.width + self.contentInset.right - self.contentInset.left;
//    return -self.contentInset.left + self.contentSize.width + self.contentInset.right;
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
