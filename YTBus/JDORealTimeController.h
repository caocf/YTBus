//
//  JDORealTimeController.h
//  YTBus
//
//  Created by zhang yi on 14-10-21.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JDOBusLine.h"

@interface JDORealTimeController : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,strong) JDOBusLine *busLine;

@end
