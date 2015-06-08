//
//  JDOInterChangeController.h
//  YTBus
//
//  Created by zhang yi on 14-11-25.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BMapKit.h"

@interface JDOInterChangeController : UIViewController

@property (nonatomic,weak) IBOutlet UITextField *startField;
@property (nonatomic,weak) IBOutlet UITextField *endField;
@property (nonatomic,strong) BMKPoiInfo *startPoi;
@property (nonatomic,strong) BMKPoiInfo *endPoi;

@end
