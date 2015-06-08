//
//  JDOMainTabController.h
//  YTBus
//
//  Created by zhang yi on 14-10-31.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JDOMainTabController : UITabBarController

@property (nonatomic,assign) int hasNewVersion;
@property (nonatomic,strong) NSString *versionNumber;
@property (nonatomic,assign) BOOL hasNewInfo;
@property (nonatomic,strong) NSString *newsId;

@end
