//
//  JDOUtils.m
//  YTBus
//
//  Created by zhang yi on 14-11-13.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDOUtils.h"
#import "MBProgressHUD.h"

@implementation JDOUtils

+ (NSString *) getJDOCacheDirectory{
    NSString *diskCachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *JDOCacheDirectory = [diskCachePath stringByAppendingPathComponent:@"JDOCache"];
    BOOL success = [JDOUtils getDiskDirectory:JDOCacheDirectory];
    if ( success ) {
        return JDOCacheDirectory;
    }else{
        return diskCachePath;
    }
}

+ (BOOL) getDiskDirectory:(NSString *)directoryPath{
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:directoryPath]){
        NSError *error;
        BOOL result = [fm createDirectoryAtPath:directoryPath withIntermediateDirectories:true attributes:nil error:&error];
        if(result == false){
            NSLog(@"创建缓存目录失败:%@",[error localizedDescription]);
        }
        return result;
    }
    return true;
}

+ (void) showHUDText:(NSString *)text inView:(UIView *)view{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:true];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = text;
    [hud hide:true afterDelay:1.0f];
}

@end
