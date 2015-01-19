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
#import "Reachability.h"
#import "JSONKit.h"
#import "MBProgressHUD.h"
#import "JDOHttpClient.h"

#define Adv_Min_Show_Seconds 2.0f
#define Param_Max_Wait_Seconds 5.0f
#define Advertise_Cache_File @"advertise"

@interface AppDelegate () <BMKGeneralDelegate>{
    
}

@end

@implementation AppDelegate{
    BOOL canEnterMain;
    __strong UIViewController *controller;
    UIImage *advImage;
    BOOL checkVersionFinished;
    BOOL showAdvFinished;
    MBProgressHUD *hud;
    NSDictionary *onlineParam;
}

+ (void)initialize{
    //发布时替换bundleId,注释掉就可以
//    [iVersion sharedInstance].applicationBundleID = @"com.jiaodong.JiaodongOnlineNews";
//    [iVersion sharedInstance].applicationVersion = @"3.5.0";
    
    [iVersion sharedInstance].verboseLogging = false;   // 调试信息
    [iVersion sharedInstance].appStoreCountry = @"CN";
    [iVersion sharedInstance].showOnFirstLaunch = false; // 不显示当前版本特性
    [iVersion sharedInstance].checkAtLaunch = NO;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (After_iOS7) {
        // 开启后台刷新
        // 从后台抓取启动应用不会在主线程执行performSelector:withObject:afterDelay:所以不会加载到正常流程中的main storyboard,目前还不知道如何在didFinishLaunchingWithOptions:中区分用户正常启动和由backgroundFetch启动
//        [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    }
    
    canEnterMain = true;
    
    // 友盟统计
    // Crashlytics和友盟的错误报告不能同时用，关闭友盟日志要把[MobClick setCrashReportEnabled:NO]；写在友盟appkey的前面
    [MobClick setCrashReportEnabled:true];
    [MobClick setLogEnabled:false];
    [MobClick setAppVersion:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    [MobClick startWithAppkey:@"54a8b1c7fd98c5d5850008c5" reportPolicy:BATCH channelId:nil];
    // 获取在线参数
//    [MobClick updateOnlineConfig];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UMOnlineConfigDidFinished:) name:UMOnlineConfigDidFinishedNotification object:nil];
    
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
        [BMKLocationService setLocationDistanceFilter:kCLDistanceFilterNone];//kCLDistanceFilterNone,Location_Auto_Refresh_Distance
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
    controller = [[UIViewController alloc] init];
    if (Screen_Height > 480) {
        controller.view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LaunchImage-568h"]];
    }else{
        controller.view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LaunchImage"]];
    }
    controller.view.frame = self.window.bounds;
    self.window.rootViewController = controller;
    [self.window makeKeyAndVisible];
    
    [self asyncLoadAdvertise];
    [self performSelector:@selector(showAdvertiseView) withObject:nil afterDelay:2.0f];
    
    [[JDOHttpClient sharedBUSClient] getPath:@"index/getSysParams" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSData *jsonData = responseObject;
        NSDictionary *obj = [jsonData objectFromJSONData];
        if ([obj[@"status"] intValue]==1) {
            onlineParam = obj[@"data"];
            [self onVersionCheckFinished];
        }else{
            NSLog(@"获取参数结果错误:%@",obj[@"info"]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"获取参数网络错误:%@",error);
    }];
    
    
    return YES;
}

- (void) asyncLoadAdvertise{   // 异步加载广告页
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int width = [[NSNumber numberWithFloat:Screen_Width*[UIScreen mainScreen].scale] intValue];
        int height = [[NSNumber numberWithFloat:Screen_Height*[UIScreen mainScreen].scale] intValue];
        NSString *advUrl = [JDO_Server_URL stringByAppendingString:[NSString stringWithFormat:@"/Data/getAdv?width=%d&height=%d",width,height] ];
        NSError *error ;
        NSData *jsonData = [NSData dataWithContentsOfURL:[NSURL URLWithString:advUrl] options:NSDataReadingUncached error:&error];
        if(error){
            NSLog(@"获取广告页json出错:%@",error);
            return;
        }
        NSDictionary *jsonObject = [[jsonData objectFromJSONData] objectForKey:@"data"];
        
        // 每次广告图更新后的URL会变动，则URL缓存就能够区分出是从本地获取还是从网络获取，没有必要使用版本号机制
        NSString *advServerURL = [jsonObject valueForKey:@"path"];
        NSString *advLocalURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"adv_url"];
        
        // 第一次加载或者NSUserDefault被清空，以及服务器地址与本地不一致时，从网络加载图片。同时需要保证服务器获得的advServerURL不是nil
        if( (advLocalURL==nil || ![advLocalURL isEqualToString:advServerURL]) && advServerURL!= nil ){
            NSString *advImgUrl = [JDO_RESOURCE_URL stringByAppendingString:advServerURL];
            // 同步方法不使用URLCache，若使用AFNetworking则无法禁用缓存
            NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:advImgUrl] options:NSDataReadingUncached error:&error];
            if(error){
                NSLog(@"获取广告页图片出错:%@",error);
                return;
            }
            advImage = [UIImage imageWithData:imgData];
            
            // 图片加载成功后才保存服务器版本
            [[NSUserDefaults standardUserDefaults] setObject:advServerURL forKey:@"adv_url"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            // 图片缓存到磁盘
            [imgData writeToFile:[[JDOUtils getJDOCacheDirectory] stringByAppendingPathComponent:Advertise_Cache_File] options:NSDataWritingAtomic error:&error];
            if(error){
                NSLog(@"磁盘缓存广告页图片出错:%@",error);
                return;
            }
        }else{
            // 从磁盘读取，也可以使用[NSData dataWithContentsOfFile];
            NSData *imgData = [[NSFileManager defaultManager] contentsAtPath:[[JDOUtils getJDOCacheDirectory] stringByAppendingPathComponent:Advertise_Cache_File]];
            if(imgData){
                advImage = [UIImage imageWithData:imgData];
            }else{
                // 从本地路径加载缓存广告图失败,则UserDefault中缓存的adv_url也应该失效
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"adv_url"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
    });
}

- (void)showAdvertiseView{
    // 无网络或者2秒之后仍未加载完成,则显示已缓存的广告图
    if(advImage == nil){
        NSData *imgData = [[NSFileManager defaultManager] contentsAtPath:[[JDOUtils getJDOCacheDirectory] stringByAppendingPathComponent:Advertise_Cache_File]];
        if(imgData){
            advImage = [UIImage imageWithData:imgData];
        }
    }
    if (advImage) {  // 有广告可供加载
        controller.view = [[UIImageView alloc] initWithImage:advImage];
        [self performSelector:@selector(advFinished:) withObject:@"showAdvertiseFinished" afterDelay:3.0f];
    }else{
        [self advFinished:@"noAdvertise"];
    }
}

- (void) advFinished:(NSString *)info {
    NSLog(@"%@",info);
    showAdvFinished = true;
    if (!checkVersionFinished ) {
        hud = [MBProgressHUD showHUDAddedTo:controller.view animated:true];
        hud.labelText = @"正在检查版本信息";
    }else{
        if (canEnterMain) {
            [self enterMainStoryboard];
        }
    }
}

// TODO 从后台获取在线参数，友盟的在线参数有如下几个问题：
// 1.网络丢包率高的情况下，请求超时时间太长，会导致界面卡在版本检查的地方
// 2.[MobClick getAdURL]同样会触发该回调，若被调用过早，会导致逻辑错乱
// 3.在客户端同样的网络情况下，响应时间不稳定。
// 4.程序在前台运行阶段，应该按一定的时间间隔检查最低版本，以防止在启动时由于网络差或者暂时关闭网络导致跳过版本检查。

// 新的在线参数在notification.userInfo中，可能是从网络获取的，也可能是本地缓存在NSUserDefault中的
- (void)UMOnlineConfigDidFinished:(NSNotification *)noti{
    onlineParam = (NSDictionary *)noti.userInfo;
    [self onVersionCheckFinished];
    // 加载完成后即移除该观察者，否则获取广告的[MobClick getAdURL]会引起该回调再次被执行
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UMOnlineConfigDidFinishedNotification object:nil];
}

- (void) onVersionCheckFinished{
    NSLog(@"检查版本完成");
    checkVersionFinished = true;
    if (hud) {
        [hud hide:true];
    }
    
    float sysVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    NSString *minVersion;
    if (sysVersion>=5.0f && sysVersion<6.0f) {
        minVersion = onlineParam[@"iOS5MinVersion"];
    }else if(sysVersion>=6.0f && sysVersion<7.0f){
        minVersion = onlineParam[@"iOS6MinVersion"];
    }else if(sysVersion>=7.0f && sysVersion<8.0f){
        minVersion = onlineParam[@"iOS7MinVersion"];
    }else if(sysVersion>=8.0f && sysVersion<9.0f){
        minVersion = onlineParam[@"iOS8MinVersion"];
    }else{
        minVersion = onlineParam[@"minVersion"];
    }
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    if (minVersion && [minVersion floatValue] > [currentVersion floatValue]) {
        canEnterMain = false;
        // 如果还没进入广告页，就没必要展示广告页了
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showAdvertiseView) object:nil];
        // 弹AlertView提示，程序不能继续向下执行
        if (After_iOS8) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"当前版本过低，请更新后使用。"  message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"退出" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
                exit(0);
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"更新" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                [iVersion sharedInstance].updateURL = [NSURL URLWithString:onlineParam[@"updateURL"]];
                [[iVersion sharedInstance] openAppPageInAppStore];
                exit(0);
            }]];
            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
        }else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"当前版本过低，请更新后使用。" message:nil delegate:self cancelButtonTitle:@"退出" otherButtonTitles:@"更新", nil];
            [alert show];
        }
    }else{
        if (showAdvFinished) {
            if (hud) {
                [hud hide:true];
            }
            [self enterMainStoryboard];
        }
    }
}

- (void)enterMainStoryboard{
    // 保证只被执行一次
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIStoryboard * storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        self.window.rootViewController = [storyBoard instantiateInitialViewController];
    });
    
//    @synchronized (self){
//        if (canEnterMain) {
//            canEnterMain = false;
//            UIStoryboard * storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//            self.window.rootViewController = [storyBoard instantiateInitialViewController];
//        }
//    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        [iVersion sharedInstance].updateURL = [NSURL URLWithString:onlineParam[@"updateURL"]];
        [[iVersion sharedInstance] openAppPageInAppStore];
    }
    exit(0);
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    if (notificationSettings.types != UIUserNotificationTypeNone) {
        [application registerForRemoteNotifications];
    }
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {

}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {

}

//- (void)application:(UIApplication *)applicatio didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
//    
//}

- (void)application:(UIApplication *)applicatio didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
}


//- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler{
//    NSLog(@"执行抓取，时间是：%@",[NSDate date]);
//    // 获取数据，并执行viewController的刷新界面方法，根据获取的结果调用completionHandler
//    UIView *view = (UIView *)[[[(UITabBarController *)[((AppDelegate *)application.delegate).window rootViewController] viewControllers][0] topViewController] view];
//    view.backgroundColor = [UIColor colorWithRed:arc4random()%255/255.0f green:arc4random()%255/255.0f blue:arc4random()%255/255.0f alpha:1.0f];
//    completionHandler(UIBackgroundFetchResultNewData);
//}

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
