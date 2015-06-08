//
//  JDONewsController.h
//  YTBus
//
//  Created by zhang yi on 14-12-26.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JDONewsController : UITableViewController

@property (nonatomic,strong) NSMutableArray *headArray;
@property (nonatomic,strong) NSMutableArray *listArray;

@property (nonatomic,strong) NSDate *lastUpdateTime;
@property (nonatomic,assign) int currentPage;
- (void)loadDataFromNetwork;

@end
