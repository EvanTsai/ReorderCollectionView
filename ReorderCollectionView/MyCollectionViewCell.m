//
//  MyCollectionViewCell.m
//  ReorderCollectionView
//
//  Created by Evan on 2020/6/16.
//  Copyright © 2020 Evan. All rights reserved.
//

#import "MyCollectionViewCell.h"

@interface MyCollectionViewCell ()
{
    UILabel *_label;
}
@end

@implementation MyCollectionViewCell


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initViews];
    }
    return self;
}

- (void)initViews {
    self.contentView.backgroundColor = [UIColor whiteColor];
    _label = [UILabel new];
    _label.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:_label];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _label.frame = self.contentView.bounds;
}

- (void)setModel:(NSString *)model {
    _label.text = model;
}

//- (void)enterReorderingMode {
//    self.contentView.hidden = YES;
//}
//
//- (void)quitRecorderingMode {
//    self.contentView.hidden = NO;
//}

- (void)willBeginDragging {
    self.contentView.hidden = YES;
}

- (void)didEndDragging {
    self.contentView.hidden = NO;
}


@end
