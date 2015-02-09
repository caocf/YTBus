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
#import "UMFeedback.h"

// ShareSDK
#import <ShareSDK/ShareSDK.h>
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import "WXApi.h"
#import "WeiboSDK.h"
#import <QZoneConnection/ISSQZoneApp.h>

#define Adv_Min_Show_Seconds 2.0f
#define Param_Max_Wait_Seconds 5.0f
#define Advertise_Cache_File @"advertise"

@interface AppDelegate () <BMKGeneralDelegate,BMKOfflineMapDelegate>{
    BMKOfflineMap* _offlineMap;
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
    
    // 友盟配置
    [self initUMengConfig];
    // 百度地图配置
    [self initBMKConfig];
    // 全局样式定义
    [self initAppearance];
    // 推送配置
    [self initPushConfig];
    
    // 使用LaunchImage作为背景占位图，如果从友盟检测到的最小允许版本高于当前版本，则不进入storyboard，直接退出应用或进入appstore下载
    controller = [[UIViewController alloc] init];
    if (Screen_Height > 480) {
        controller.view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LaunchImage-568h"]];
    }else{
        controller.view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LaunchImage"]];
    }
    controller.view.frame = [[UIScreen mainScreen] bounds];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = controller;
    [self.window makeKeyAndVisible];
    
//    [self asyncLoadAdvertise];
    [self performSelector:@selector(showAdvertiseView) withObject:nil afterDelay:2.0f];
    
    [[JDOHttpClient sharedBUSClient] getPath:@"index/getSysParams" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSData *jsonData = responseObject;
        NSDictionary *obj = [jsonData objectFromJSONData];
        if ([obj[@"status"] intValue]==1) {
            onlineParam = obj[@"data"];
            [self onVersionCheckFinished:true];
        }else{
            NSLog(@"获取参数结果错误:%@",obj[@"info"]);
            [self onVersionCheckFinished:false];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"获取参数网络错误:%@",error);
        [self onVersionCheckFinished:false];
    }];
    
    // 下载最新离线地图包，是dat格式，从网站上下载的是dat_svc格式，目前还不知道这两种格式有什么区别
//    _offlineMap = [[BMKOfflineMap alloc] init];
//    _offlineMap.delegate = self;
//    [_offlineMap start:326];
    // 把离线地图包从bundle中复制到document中
    [self performSelectorInBackground:@selector(copyOfflineMap) withObject:nil];
    
    [self initShareSDK];
    
    return YES;
}

- (void)initShareSDK {
    [ShareSDK registerApp:@"5a2cb151ceba"];
    [ShareSDK setInterfaceOrientationMask:SSInterfaceOrientationMaskPortrait];
    [ShareSDK allowExchangeDataEnabled:true];
    [ShareSDK ssoEnabled:true];
    
    
    // TODO 分享平台尚未提交审核
    [ShareSDK connectSinaWeiboWithAppKey:@"2993327297"
                               appSecret:@"7027a9f77cdd1d5ecdee09b433502ece"
                             redirectUri:@"http://m.jiaodong.net"
                             weiboSDKCls:[WeiboSDK class]];
    
    [ShareSDK connectQZoneWithAppKey:@"1104226312"
                           appSecret:@"leL07oBD9u3bi2r2"
                   qqApiInterfaceCls:[QQApiInterface class]
                     tencentOAuthCls:[TencentOAuth class]];

    [ShareSDK connectQQWithAppId:@"QQ41D12808" qqApiCls:[QQApi class]];
    // http://open.weixin.qq.com上注册应用，应用管理账户tec@jiaodong.net，密码Jdjsb6690009
    [ShareSDK connectWeChatWithAppId:@"wxa25ab258af707980" wechatCls:[WXApi class]];
    
    [ShareSDK connectRenRenWithAppId:@"475009"
                              appKey:@"9bee76292b5f43b783c2843a3ef837d4"
                           appSecret:@"256923d272c740e39cd7728fa612b5ae"
                   renrenClientClass:nil];
//    [ShareSDK connectSMS];
    
    //开启QQ空间网页授权开关(optional)
    id<ISSQZoneApp> app =(id<ISSQZoneApp>)[ShareSDK getClientWithType:ShareTypeQQSpace];
    [app setIsAllowWebAuthorize:YES];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [ShareSDK handleOpenURL:url wxDelegate:self];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [ShareSDK handleOpenURL:url sourceApplication:sourceApplication annotation:annotation wxDelegate:self];
}

- (void)copyOfflineMap {
    // iOS8以下的沙盒机制应用的bundle跟data在同一个目录下/var/mobile/Applications/，iOS8以上的沙盒将bundle和data分离，bundle放在"/private/var/mobile/Containers/Bundle/Application"目录下，document放在"/var/mobile/Containers/Data/Application/"目录下。
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *baidumapDir = [documentDir stringByAppendingPathComponent:@"vmp/h"];
    NSString *baidumapDes = [documentDir stringByAppendingPathComponent:@"vmp/h/yantai_326.dat"];
    NSString *baidumapSrc = [[NSBundle mainBundle] pathForResource:@"yantai_326" ofType:@"dat"];
    
    BOOL isDir;
    BOOL doCopy = false;
    NSError *error;
    if ([fm fileExistsAtPath:baidumapDir isDirectory:&isDir]) {
        if (isDir) {
            NSLog(@"目录已存在");
            if ([fm fileExistsAtPath:baidumapDes]) {
                NSLog(@"离线地图已存在");
            }else{
                doCopy = true;
            }
        }else{
            NSLog(@"%@不是目录",baidumapDir);
        }
    }else{
        BOOL success = [fm createDirectoryAtPath:baidumapDir withIntermediateDirectories:true attributes:nil error:&error];
        if ( success ) {
            NSLog(@"创建地图目录成功");
            doCopy = true;
        }else{
            NSLog(@"创建地图目录失败:%@",error);
        }
    }
    
    if( doCopy ){
        NSLog(@"开始复制离线地图");
        BOOL result = [fm copyItemAtPath:baidumapSrc toPath:baidumapDes error:&error];
        if(!result){
            NSLog(@"复制离线地图失败:%@",error);
        }else{
            NSLog(@"复制离线地图成功");
        }
    }
}

- (void)onGetOfflineMapState:(int)type withState:(int)state{
    if (type == TYPE_OFFLINE_UPDATE) {
        //id为state的城市正在下载或更新，start后会毁掉此类型
        BMKOLUpdateElement* updateInfo;
        updateInfo = [_offlineMap getUpdateInfo:state];
        NSLog(@"城市名：%@,下载比例:%d",updateInfo.cityName,updateInfo.ratio);
    }
    if (type == TYPE_OFFLINE_NEWVER) {
        //id为state的state城市有新版本,可调用update接口进行更新
        BMKOLUpdateElement* updateInfo;
        updateInfo = [_offlineMap getUpdateInfo:state];
        NSLog(@"是否有更新%d",updateInfo.update);
    }
    if (type == TYPE_OFFLINE_UNZIP) {
        //正在解压第state个离线包，导入时会回调此类型
    }
    if (type == TYPE_OFFLINE_ZIPCNT) {
        //检测到state个离线包，开始导入时会回调此类型
        NSLog(@"检测到%d个离线包",state);
    }
    if (type == TYPE_OFFLINE_ERRZIP) {
        //有state个错误包，导入完成后会回调此类型
        NSLog(@"有%d个离线包导入错误",state);
    }
    if (type == TYPE_OFFLINE_UNZIPFINISH) {
        NSLog(@"成功导入%d个离线包",state);
        //导入成功state个离线包，导入成功后会回调此类型
    }
    
}

- (void) initUMengConfig{
    // 友盟统计
    // Crashlytics和友盟的错误报告不能同时用，关闭友盟日志要把[MobClick setCrashReportEnabled:NO]；写在友盟appkey的前面
    [MobClick setCrashReportEnabled:true];
    [MobClick setLogEnabled:false];
    [MobClick setAppVersion:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    [MobClick startWithAppkey:@"54a8b1c7fd98c5d5850008c5" reportPolicy:BATCH channelId:nil];
    // 获取在线参数
//    [MobClick updateOnlineConfig];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UMOnlineConfigDidFinished:) name:UMOnlineConfigDidFinishedNotification object:nil];
    
    // 友盟用户反馈
    [UMFeedback setAppkey:@"54a8b1c7fd98c5d5850008c5"];
    [UMFeedback setLogEnabled:true];
    
    // 友盟集成测试获取测试设备唯一识别码
//    Class cls = NSClassFromString(@"UMANUtil");
//    SEL deviceIDSelector = @selector(openUDIDString);
//    NSString *deviceID = nil;
//    if(cls && [cls respondsToSelector:deviceIDSelector]){
//        deviceID = [cls performSelector:deviceIDSelector];
//    }
//    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{@"oid" : deviceID} options:NSJSONWritingPrettyPrinted error:nil];
//    NSLog(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
}

- (void) initBMKConfig{
    // 要使用百度地图，请先启动BaiduMapManager
    _mapManager = [[BMKMapManager alloc]init];
    BOOL ret = [_mapManager start:@"BI3iLNMvqHHWiELxAi5kkbn2" generalDelegate:self];
    if (!ret) {
        NSLog(@"manager start failed!");
    }else{
        [BMKLocationService setLocationDesiredAccuracy:kCLLocationAccuracyBestForNavigation];
        [BMKLocationService setLocationDistanceFilter:kCLDistanceFilterNone];//kCLDistanceFilterNone,Location_Auto_Refresh_Distance
    }
}

- (void) initAppearance{
//    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    if (After_iOS7) {
        // 若设置该选项=false，则self.view的origin.y从导航栏以下开始计算，否则从屏幕顶端开始计算，
        // 这是因为iOS7的controller中extendedLayoutIncludesOpaqueBars属性默认是false，也就是说不透明的bar不启用extendedLayout，
        // 若背景是半透明的情况下，也可以通过设置controller的edgesForExtendedLayout使view从导航栏下方开始计算
        
        // iOS7未实现translucent的appearance，iOS8以后可用，已经改为在所有的storyboard中的navigationbar中设置该属性
//        [[UINavigationBar appearance] setTranslucent:false];
        [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
        [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navigation_iOS7"] forBarMetrics:UIBarMetricsDefault];
        [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
    }else{
        [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navigation_iOS6"] forBarMetrics:UIBarMetricsDefault];
        [[UIBarButtonItem appearance] setTintColor:[UIColor colorWithHex:@"233247"]];
    }
    //    UITextAttributeFont,UITextAttributeTextShadowOffset,UITextAttributeTextShadowColor
    [[UINavigationBar appearance] setTitleTextAttributes: @{UITextAttributeTextColor:[UIColor whiteColor]}];
}

- (void) initPushConfig{
//    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
//        [application registerForRemoteNotifications];
//        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIRemoteNotificationTypeAlert| UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound categories:nil];
//        [application registerUserNotificationSettings:settings];
//    } else {
//        [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert| UIRemoteNotificationTypeBadge| UIRemoteNotificationTypeSound];
//    }
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
//- (void)UMOnlineConfigDidFinished:(NSNotification *)noti{
//    onlineParam = (NSDictionary *)noti.userInfo;
//    [self onVersionCheckFinished];
//    // 加载完成后即移除该观察者，否则获取广告的[MobClick getAdURL]会引起该回调再次被执行
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UMOnlineConfigDidFinishedNotification object:nil];
//}

- (void) onVersionCheckFinished:(BOOL)success{
    checkVersionFinished = true;
    if (hud) {
        [hud hide:true];
    }
    
    if (success) {
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
                [self enterMainStoryboard];
            }
        }
    }else{
        if (showAdvFinished) {
            [self enterMainStoryboard];
        }
    }
    
    
    
}

- (void)enterMainStoryboard{
    [UIApplication sharedApplication].statusBarHidden = false;
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
