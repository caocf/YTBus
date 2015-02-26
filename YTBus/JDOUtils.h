//
//  JDOUtils.h
//  YTBus
//
//  Created by zhang yi on 14-11-13.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum{
    DateFormatYMD,
    DateFormatMD,
    DateFormatYMDHM,
    DateFormatYMDHMS,
    DateFormatYMDHMS2,
    DateFormatMDHM,
    DateFormatHM,
    DateFormatHMS
}DateFormatType;

@interface JDOUtils : NSObject

+ (NSString *) getJDOCacheDirectory;
+ (void) showHUDText:(NSString *)text inView:(UIView *)view;
+ (void) showHUDText:(NSString *)text inView:(UIView *)view afterDelay:(float) delay;
+ (BOOL) isEmptyString:(NSString *)str;

+ (NSString *)formatDate:(NSDate *) date withFormatter:(DateFormatType) format;
+ (NSDate *)formatString:(NSString *)date withFormatter:(DateFormatType) format;
CGSize JDOSizeOfString(NSString *string, CGSize constrainedToSize, UIFont *font, NSLineBreakMode lineBreakMode, int numberOfLines);
@end
