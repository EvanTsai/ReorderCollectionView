//
//  JDReorderCollectionView.h
//  jiandan
//
//  Created by Evan on 2020/5/21.
//  Copyright © 2020 iqiyi. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@protocol JDReorderCellDelegate <NSObject>

@optional
- (UIView *)snapshotViewForReordering;
- (void)willBeginDragging;
//- (void)didBeginDragging;
//- (void)willEndDragging;
- (void)didEndDragging;
@end


typedef NS_ENUM(NSUInteger, JDReorderStatus) {
    JDReorderStatusIdle,
    JDReorderStatusMoved,       // 动画完成了，但是没有调用回调
    JDReorderStatusCompleted,   // 回调结束
};

@interface JDReorderCollectionView : UICollectionView

@property (nonatomic, assign) BOOL enableReordering;
@property (nonatomic, assign) BOOL needsHapticFeedback;

@end

NS_ASSUME_NONNULL_END
