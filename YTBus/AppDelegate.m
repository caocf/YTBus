//
//  AppDelegate.m
//  YTBus
//
//  Created by zhang yi on 14-10-17.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "AppDelegate.h"
#import "JDOConstants.h"
#import "iVersion.h"

#define Adv_Min_Show_Seconds 2.0f
#define Param_Max_Wait_Seconds 5.0f

@interface AppDelegate () <BMKGeneralDelegate>{
    
}

@end

@implementation AppDelegate{
    NSDate *advBeginTime;
    BOOL canEnterMain;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    canEnterMain = true;
    
    // 友盟统计
    // Crashlytics和友盟的错误报告不能同时用，关闭友盟日志要把[MobClick setCrashReportEnabled:NO]；写在友盟appkey的前面
    [MobClick setCrashReportEnabled:true];
    [MobClick setLogEnabled:false];
    [MobClick setAppVersion:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    [MobClick startWithAppkey:@"54a8b1c7fd98c5d5850008c5" reportPolicy:BATCH channelId:nil];
    // 获取在线参数
    [MobClick updateOnlineConfig];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UMOnlineConfigDidFinished:) name:UMOnlineConfigDidFinishedNotification object:nil];
    
    // 友盟集成测试获取测试设备唯一识别码
//    Class cls = NSClassFromString(@"UMANUtil");
//    SEL deviceIDSelector = @selector(openUDIDString);
//    NSString *deviceID = nil;
//    if(cls && [cls respondsToSelector:deviceIDSelector]){
//        deviceID = [cls performSelector:deviceIDSelector];
//    }
//    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{@"oid" : deviceID} options:NSJSONWritingPrettyPrinted error:nil];
//    NSLog(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    
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
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    // 使用LaunchImage作为背景占位图，如果从友盟检测到的最小允许版本高于当前版本，则不进入storyboard，直接退出应用或进入appstore下载
    UIViewController *controller = [[UIViewController alloc] init];
    if (CGRectGetHeight([UIScreen mainScreen].bounds) > 480) {
        controller.view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LaunchImage-568h"]];
    }else{
        controller.view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LaunchImage"]];
    }
    controller.view.frame = self.window.bounds;
    self.window.rootViewController = controller;
    [self.window makeKeyAndVisible];
    
    advBeginTime = [NSDate date];
    // 为防止网络链接慢的情况下查询minVersion回调一直未完成导致卡在启动页，在此加一个最大等待时间的跳转
    [self performSelector:@selector(enterMainStoryboard:) withObject:@"checkVersionTimeout" afterDelay:Param_Max_Wait_Seconds];
    
    return YES;
}

+ (void)initialize{
    //发布时替换bundleId,注释掉就可以
//    [iVersion sharedInstance].applicationBundleID = @"com.jiaodong.JiaodongOnlineNews";
//    [iVersion sharedInstance].applicationVersion = @"3.5.0";
    
    [iVersion sharedInstance].verboseLogging = true;   // 调试信息
    [iVersion sharedInstance].appStoreCountry = @"CN";
    [iVersion sharedInstance].showOnFirstLaunch = false; // 不显示当前版本特性
    [iVersion sharedInstance].checkAtLaunch = NO;
}

- (void)UMOnlineConfigDidFinished:(NSNotification *)noti{
    NSDate *now = [NSDate date];
    double passedTime = [now timeIntervalSinceDate:advBeginTime];
    NSLog(@"获取友盟参数消耗时间:%g", passedTime);
    if (!canEnterMain) { // 该回调返回时已经超过最大等待时间，应用已经进入MainStoryboard，则忽略本次查询结果
        return;
    }
    
    float sysVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    NSString *minVersion;
    if (sysVersion>=5.0f && sysVersion<6.0f) {
        minVersion = [MobClick getConfigParams:@"iOS5MinVersion"];
    }else if(sysVersion>=6.0f && sysVersion<7.0f){
        minVersion = [MobClick getConfigParams:@"iOS6MinVersion"];
    }else if(sysVersion>=7.0f && sysVersion<8.0f){
        minVersion = [MobClick getConfigParams:@"iOS7MinVersion"];
    }else if(sysVersion>=8.0f && sysVersion<9.0f){
        minVersion = [MobClick getConfigParams:@"iOS8MinVersion"];
    }else{
        minVersion = [MobClick getConfigParams:@"minVersion"];
    }
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    if (minVersion && [minVersion floatValue] > [currentVersion floatValue]) {
        canEnterMain = false;
        // 弹AlertView提示，程序不能继续向下执行
        if (After_iOS8) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"当前版本过低，请更新后使用。"  message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"退出" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
                exit(0);
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"更新" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                [iVersion sharedInstance].updateURL = [NSURL URLWithString:[MobClick getConfigParams:@"updateURL"]];
                [[iVersion sharedInstance] openAppPageInAppStore];
                exit(0);
            }]];
            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
        }else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"当前版本过低，请更新后使用。" message:nil delegate:self cancelButtonTitle:@"退出" otherButtonTitles:@"更新", nil];
            [alert show];
        }
    }else{  // 第一次获取时没有联网，无法获取minVersion，或者未联网时从NSUserDefault获取都走这个分支
        if (passedTime >= Adv_Min_Show_Seconds) {
            [self enterMainStoryboard:@"checkVersionFinished"];
        }else{
            [self performSelector:@selector(enterMainStoryboard:) withObject:@"checkVersionFinishedWaitAdv" afterDelay:(Adv_Min_Show_Seconds-passedTime)];
        }
    }
}

- (void)enterMainStoryboard:(NSString *)info{
    if (canEnterMain) {
        canEnterMain = false;
        NSLog(@"%@",info);
        UIStoryboard * storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        self.window.rootViewController = [storyBoard instantiateInitialViewController];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        [iVersion sharedInstance].updateURL = [NSURL URLWithString:[MobClick getConfigParams:@"updateURL"]];
        [[iVersion sharedInstance] openAppPageInAppStore];
    }
    exit(0);
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
