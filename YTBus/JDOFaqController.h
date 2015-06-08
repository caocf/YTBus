//
//  JDOFaqController.h
//  YTBus
//
//  Created by zhang yi on 15-5-12.
//  Copyright (c) 2015年 胶东在线. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JDOFaqController : UITableViewController

@property (nonatomic,strong) NSMutableArray *listArray;

- (void)loadDataFromNetwork;

@end
