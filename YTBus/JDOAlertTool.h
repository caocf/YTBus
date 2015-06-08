//
//  JDOAlertTool.h
//  YTBus
//
//  Created by zhang yi on 15-4-13.
//  Copyright (c) 2015年 胶东在线. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface JDOAlertTool : NSObject

- (void) showAlertView:(UIViewController *)viewController title:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle otherTitle1:(NSString *)otherTitle1 otherTitle2:(NSString *)otherTitle2 cancelAction:(void (^)())cancelAction otherAction1:(void (^)())otherAction1 otherAction2:(void (^)())otherAction2;

@end
