//
//  JDCellReorderable.h
//  ReorderCollectionView
//
//  Created by Evan on 2020/6/16.
//  Copyright © 2020 Evan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol JDCellReorderable <NSObject>
@optional
- (UIView *)snapshotViewForReordering;
- (void)willBeginDragging;
- (void)willEndDragging;
- (void)didEndDragging;
@end

NS_ASSUME_NONNULL_END
