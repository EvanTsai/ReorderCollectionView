//
//  JDReorderCollectionView.h
//  jiandan
//
//  Created by Evan on 2020/5/21.
//  Copyright © 2020 iqiyi. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface JDReorderCollectionView : UICollectionView

@property (nonatomic, assign) BOOL enableReordering;
@property (nonatomic, assign) BOOL needsHapticFeedback;

@end

NS_ASSUME_NONNULL_END
