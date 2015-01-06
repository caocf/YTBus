//
//  AppDelegate.m
//  YTBus
//
//  Created by zhang yi on 14-10-17.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "AppDelegate.h"
#import "JDOConstants.h"

@interface AppDelegate () <BMKGeneralDelegate>{
    
}

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //友盟统计
    //Crashlytics和友盟的错误报告不能同时用，关闭友盟日志要把[MobClick setCrashReportEnabled:NO]；写在友盟appkey的前面
    [MobClick setCrashReportEnabled:true];
    [MobClick setLogEnabled:true];
    [MobClick setAppVersion:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    [MobClick startWithAppkey:@"54a8b1c7fd98c5d5850008c5" reportPolicy:BATCH channelId:nil];
    
    // 要使用百度地图，请先启动BaiduMapManager
    _mapManager = [[BMKMapManager alloc]init];
    BOOL ret = [_mapManager start:@"BI3iLNMvqHHWiELxAi5kkbn2" generalDelegate:self];
    if (!ret) {
        NSLog(@"manager start failed!");
    }else{
        [BMKLocationService setLocationDesiredAccuracy:kCLLocationAccuracyBestForNavigation];
        [BMKLocationService setLocationDistanceFilter:Location_Auto_Refresh_Distance];    //kCLDistanceFilterNone
    }
    
    application.statusBarStyle = UIStatusBarStyleLightContent;
    if (After_iOS7) {
        [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
        [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
    }else{
        [[UIBarButtonItem appearance] setTintColor:[UIColor colorWithHex:@"233247"]];
    }
    
//    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
//        [application registerForRemoteNotifications];
//        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIRemoteNotificationTypeAlert| UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound categories:nil];
//        [application registerUserNotificationSettings:settings];
//    } else {
//        [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert| UIRemoteNotificationTypeBadge| UIRemoteNotificationTypeSound];
//    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [BMKMapView willBackGround];//当应用即将后台时调用，停止一切调用opengl相关的操作
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [BMKMapView didForeGround];//当应用恢复前台状态时调用，回复地图的渲染和opengl相关的操作
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)onGetNetworkState:(int)iError {
    if (0 == iError) {
        NSLog(@"联网成功");
    }else{
        NSLog(@"onGetNetworkState %d",iError);
    }
}

- (void)onGetPermissionState:(int)iError {
    if (0 == iError) {
        NSLog(@"授权成功");
    }else {
        NSLog(@"onGetPermissionState %d",iError);
    }
}

@end
