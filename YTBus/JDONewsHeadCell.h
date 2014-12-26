//
//  JDONewsHeadCell.h
//  JiaodongOnlineNews
//
//  Created by zhang yi on 13-6-2.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StyledPageControl.h"

@interface JDONewsHeadCell : UITableViewCell <UIScrollViewDelegate>

@property (nonatomic,strong) NSMutableArray *models;
@property (nonatomic,strong) UIScrollView *scrollView;
@property (nonatomic,strong) NSMutableArray *imageViews;
@property (nonatomic,strong) UILabel *titleLabel;
@property (nonatomic,strong) StyledPageControl *pageControl;
@property (nonatomic,strong) UIImageView *titleBackground;
@property (nonatomic,assign) int currentPage;

@end
