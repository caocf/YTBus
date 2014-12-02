//
//  JDOUtils.h
//  YTBus
//
//  Created by zhang yi on 14-11-13.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface JDOUtils : NSObject

+ (NSString *) getJDOCacheDirectory;
+ (void) showHUDText:(NSString *)text inView:(UIView *)view;
+ (BOOL) isEmptyString:(NSString *)str;

@end
