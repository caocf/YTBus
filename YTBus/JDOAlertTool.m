//
//  JDOAlertTool.m
//  YTBus
//
//  Created by zhang yi on 15-4-13.
//  Copyright (c) 2015年 胶东在线. All rights reserved.
//

#import "JDOAlertTool.h"
#import "JDOConstants.h"

typedef void (^action)();

@implementation JDOAlertTool{
    action _cancelAction;
    action _otherAction1;
    action _otherAction2;
}

- (void) showAlertView:(UIViewController *)viewController title:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle otherTitle1:(NSString *)otherTitle1 otherTitle2:(NSString *)otherTitle2 cancelAction:(void (^)())cancelAction otherAction1:(void (^)())otherAction1 otherAction2:(void (^)())otherAction2{
    _cancelAction = cancelAction;
    _otherAction1 = otherAction1;
    _otherAction2 = otherAction2;
    
    if (After_iOS8) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title  message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
            cancelAction();
        }]];
        if (otherTitle1) {
            [alert addAction:[UIAlertAction actionWithTitle:otherTitle1 style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                otherAction1();
            }]];
        }
        if (otherTitle2) {
            [alert addAction:[UIAlertAction actionWithTitle:otherTitle2 style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                otherAction2();
            }]];
        }
        [viewController presentViewController:alert animated:YES completion:nil];
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:otherTitle1,otherTitle2, nil];
        [alert show];
    }
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        _cancelAction();
    }else if(buttonIndex == 1){
        _otherAction1();
    }else{
        _otherAction2();
    }
}

@end
