//
//  JDOUtils.m
//  YTBus
//
//  Created by zhang yi on 14-11-13.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDOUtils.h"
#import "MBProgressHUD.h"
#import "STKeychain.h"

@implementation JDOUtils

static NSDateFormatter *dateFormatter;

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

+ (void) showHUDText:(NSString *)text inView:(UIView *)view afterDelay:(float) delay{
    // 若有其他的hud正在显示，先关闭
    [MBProgressHUD hideAllHUDsForView:view animated:false];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:true];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = text;
    [hud hide:true afterDelay:delay];
}

+ (void) showHUDText:(NSString *)text inView:(UIView *)view{
    [self showHUDText:text inView:view afterDelay:1.0f];
}

+ (BOOL) isEmptyString:(NSString *)str{
    return str==nil || [[str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""];
}


+ (NSString *)formatDate:(NSDate *) date withFormatter:(DateFormatType) format{
    if(dateFormatter == nil){
        dateFormatter = [[NSDateFormatter alloc] init];
    }
    NSString *formatString;
    switch (format) {
        case DateFormatYMD:    formatString = @"yyyy/MM/dd";  break;
        case DateFormatMD:     formatString = @"MM/dd";  break;
        case DateFormatYMDHM:  formatString = @"yyyy/MM/dd HH:mm";  break;
        case DateFormatYMDHMS: formatString = @"yyyy/MM/dd HH:mm:ss";  break;
        case DateFormatYMDHMS2:formatString = @"yyyy-MM-dd HH:mm:ss";  break;
        case DateFormatMDHM:   formatString = @"MM-dd HH:mm";  break;
        case DateFormatHM:     formatString = @"HH:mm";  break;
        case DateFormatHMS:    formatString = @"HH:mm:ss";  break;
        default:    break;
    }
    [dateFormatter setDateFormat:formatString];
    return [dateFormatter stringFromDate:date];
}
+ (NSDate *)formatString:(NSString *)date withFormatter:(DateFormatType) format{
    if(dateFormatter == nil){
        dateFormatter = [[NSDateFormatter alloc] init];
    }
    NSString *formatString;
    switch (format) {
        case DateFormatYMD:    formatString = @"yyyy/MM/dd";  break;
        case DateFormatMD:     formatString = @"MM/dd";  break;
        case DateFormatYMDHM:  formatString = @"yyyy/MM/dd HH:mm";  break;
        case DateFormatYMDHMS: formatString = @"yyyy-MM-dd HH:mm:ss"; break;
        case DateFormatYMDHMS2:formatString = @"yyyy-MM-dd HH:mm:ss"; break;
        case DateFormatMDHM:   formatString = @"MM/dd HH:mm";  break;
        case DateFormatHM:     formatString = @"HH:mm";  break;
        case DateFormatHMS:    formatString = @"HH:mm:ss";  break;
        default:    break;
    }
    [dateFormatter setDateFormat:formatString];
    return [dateFormatter dateFromString:date];
}
+ (CGSize) JDOSizeOfString:(NSString *)string :(CGSize) constrainedToSize :(UIFont *) font :(NSLineBreakMode) lineBreakMode :(int) numberOfLines{
    if (string.length == 0) {
        return CGSizeZero;
    }
    
    CGFloat lineHeight = font.lineHeight;
    CGSize size = CGSizeZero;
    
    if (numberOfLines == 1) {
        size = [string sizeWithFont:font forWidth:constrainedToSize.width lineBreakMode:lineBreakMode];
        
    } else {
        size = [string sizeWithFont:font constrainedToSize:constrainedToSize lineBreakMode:lineBreakMode];
        if (numberOfLines > 0) {
            size.height = MIN(size.height, numberOfLines * lineHeight);
        }
    }
    
    return size;
}

+ (NSArray *) getXmlTagAttrib:(NSString *)xmlStr andTag:(NSString *)tag andAttr:(NSString *)attr {
    NSString *regxpForTag = [[@"<\\s*" stringByAppendingString:tag] stringByAppendingString:@"\\s+([^>]*)\\s*/>"];
    NSString *regxpForTagAttrib = [attr stringByAppendingString:@"=\"([^\"]+)\""];
    
    NSRegularExpression *regex1 = [NSRegularExpression regularExpressionWithPattern:regxpForTag options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSRegularExpression *regex2 = [NSRegularExpression regularExpressionWithPattern:regxpForTagAttrib options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSArray *matches =    nil;
    NSMutableArray *retArray =[[NSMutableArray alloc] init];
    matches = [regex1 matchesInString:xmlStr options:0 range:NSMakeRange(0, [xmlStr length])];
    for (NSTextCheckingResult *match in matches) {
        NSRange range = [match range];
        NSString *subString = [xmlStr substringWithRange:range];
        NSTextCheckingResult *firstSubMatch = [regex2 firstMatchInString:subString options:0 range:NSMakeRange(0, [subString length])];
        NSRange subRange = [firstSubMatch rangeAtIndex:1];
        NSString *retString = [subString substringWithRange:subRange];
        [retArray addObject:retString];
    }
    return retArray;
}

+ (BOOL) checkTelephone:(NSString *)number{
    // 扩大手机号正则匹配的范围，防止增加的176等号段超出该范围
    NSString *MOBILE = @"^1[3-8]\\d{9}$";
    NSPredicate *regex = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
    return [regex evaluateWithObject:number];
}

+ (NSString *) getUUID{
    NSError *error;
    NSString *uuid = [STKeychain getPasswordForUsername:@"YTBus" andServiceName:@"uuid" error:&error];
    if (error != nil) {
        NSLog(@"GetUUID Error:%li",(long)error.code);
        return @"00000000";
    }
    if (uuid == nil || [uuid isEqualToString:@""]){
        CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
        CFStringRef stringRef = CFUUIDCreateString (kCFAllocatorDefault,uuidRef);
        uuid = (__bridge_transfer NSString*)stringRef;
        BOOL success = [STKeychain storeUsername:@"YTBus" andPassword:uuid forServiceName:@"uuid" updateExisting:true error:&error];
        if (!success) {
            NSLog(@"SaveUUID Error:%li",(long)error.code);
            return @"00000000";
        }
    }
    return uuid;
}

+ (BOOL) deleteUUID{
    NSError *error;
    NSString *uuid = [STKeychain getPasswordForUsername:@"YTBus" andServiceName:@"uuid" error:&error];
    if (error != nil) {
        NSLog(@"GetUUID Error:%li",(long)error.code);
        return false;
    }
    if (uuid == nil || [uuid isEqualToString:@""]){
        return true;
    }else{
        BOOL success = [STKeychain deleteItemForUsername:@"YTBus" andServiceName:@"uuid" error:&error];
        if(success) {
            return true;
        }
    }
    return false;
}

@end
