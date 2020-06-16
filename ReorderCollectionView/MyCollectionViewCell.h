//
//  MyCollectionViewCell.h
//  ReorderCollectionView
//
//  Created by Evan on 2020/6/16.
//  Copyright © 2020 Evan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JDCellReorderable.h"

NS_ASSUME_NONNULL_BEGIN

@interface MyCollectionViewCell : UICollectionViewCell<JDCellReorderable>

- (void)setModel:(NSString *)model;

@end

NS_ASSUME_NONNULL_END
