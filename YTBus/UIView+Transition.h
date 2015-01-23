//
//  UIView+Transition.h
//  JiaodongOnlineNews
//
//  Created by zhang yi on 13-6-6.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    JDOTransitionFromRight,
    JDOTransitionFromBottom,
    JDOTransitionToRight,
    JDOTransitionToBottom
} JDOTransitionOrientation;

@interface UIView (Transition)

- (UIView *) blackMask;

- (void) pushView:(UIView *) moveInView orientation:(JDOTransitionOrientation)orientation complete:(void (^)()) complete;
- (void) pushView:(UIView *) moveInView startFrame:(CGRect)startFrame endFrame:(CGRect)endFrame complete:(void (^)())complete;
- (void) pushView:(UIView *) moveInView process:(void (^)(CGRect* _startFrame,CGRect* _endFrame,NSTimeInterval* _interval))process complete:(void (^)())complete;

- (void) popView:(UIView *) presentView orientation:(JDOTransitionOrientation)orientation complete:(void (^)()) complete;
- (void) popView:(UIView *) presentView startFrame:(CGRect)startFrame endFrame:(CGRect)endFrame complete:(void (^)()) complete;
- (void) popView:(UIView *) presentView process:(void (^)(CGRect* _startFrame,CGRect* _endFrame,NSTimeInterval* _interval))process complete:(void (^)())complete;

@end
