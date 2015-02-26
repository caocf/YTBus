//
//  AppDelegate.h
//  YTBus
//
//  Created by zhang yi on 14-10-17.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BMapKit.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) BMKMapManager *mapManager;

@property (nonatomic, strong) BMKUserLocation *userLocation;

@end

