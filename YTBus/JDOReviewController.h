//
//  JDOReviewController.h
//  YTBus
//
//  Created by zhang yi on 15-1-20.
//  Copyright (c) 2015年 胶东在线. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JDOToolBar.h"
#import "JDOToolbarModel.h"

@interface JDOReviewController : UIViewController

@property (nonatomic,strong) IBOutlet UITableView *tableView;
@property (nonatomic,strong) IBOutlet JDOToolBar *toolbar;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *btnItem;

@property (nonatomic,strong) NSMutableArray *listArray;

@property (nonatomic,strong) NSDate *lastUpdateTime;
@property (nonatomic,strong) id<JDOToolbarModel> model;

@end
