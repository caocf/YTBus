//
//  AppDelegate.m
//  YTBus
//
//  Created by zhang yi on 14-10-17.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "AppDelegate.h"
#import "JDODatabase.h"
#import "AFNetworking.h"
#import "SSZipArchive.h"

@interface AppDelegate () <BMKGeneralDelegate,SSZipArchiveDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 要使用百度地图，请先启动BaiduMapManager
    _mapManager = [[BMKMapManager alloc]init];
    BOOL ret = [_mapManager start:@"BI3iLNMvqHHWiELxAi5kkbn2" generalDelegate:self];
    if (!ret) {
        NSLog(@"manager start failed!");
    }
    if (![JDODatabase isDBExistInDocument]) {
        // 若document中不存在数据库文件，则下载数据库文件
        NSURL *URL = [NSURL URLWithString:@"http://218.56.32.7:1030/SynBusSoftWebservice/DownloadServlet?method=downloadDb"];
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSData *zipData = (NSData *)responseObject;
            BOOL success = [JDODatabase saveZipFile:zipData];
            if ( success) { // 解压缩文件
                BOOL result = [JDODatabase unzipDBFile:self];
                if ( result) {
                    // 正在解压
                }else{  // 解压文件出错
                    [JDODatabase openDB:1];
                }
            }else{  // 保存文件出错
                [JDODatabase openDB:1];
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            [JDODatabase openDB:1];
        }];
        [[NSOperationQueue mainQueue] addOperation:op];
    }else{
        [JDODatabase openDB:2];
    }
    return YES;
}

- (void)zipArchiveDidUnzipArchiveAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo unzippedPath:(NSString *)unzippedPath{
    [JDODatabase openDB:2];
}

- (void)zipArchiveProgressEvent:(NSInteger)loaded total:(NSInteger)total{
    NSLog(@"解压进度:%g",loaded*1.0/total);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
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
