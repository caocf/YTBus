//
//  UIView+Transition.m
//  JiaodongOnlineNews
//
//  Created by zhang yi on 13-6-6.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import "UIView+Transition.h"
#import <objc/runtime.h>
#import "JDOConstants.h"

#define Transition_Time 0.3f

// 视图转换
#define Min_Scale 0.96f
#define Max_Alpah 0.6f
#define Transition_Window_Right CGRectMake(320, 20, 320, App_Height)
#define Transition_Window_Center CGRectMake(0, 20, 320, App_Height)
#define Transition_Window_Bottom CGRectMake(0, 20+App_Height, 320, App_Height)
#define Transition_View_Right CGRectMake(320, 0, 320, App_Height)
#define Transition_View_Center CGRectMake(0, 0, 320, App_Height)
#define Transition_View_Bottom CGRectMake(0, App_Height, 320, App_Height)

@implementation UIView (Transition)

static const char* shadowViewKey = "shadowViewKey";
static const char* blackMaskKey = "blackMaskKey";

- (void) pushView:(UIView *) moveInView orientation:(JDOTransitionOrientation)orientation complete:(void (^)())complete{
    
    CGRect moveInStartFrame = CGRectZero;
    CGRect moveInEndFrame = Transition_View_Center;
    if(orientation == JDOTransitionFromRight){
        moveInStartFrame = Transition_View_Right;
    }else if(orientation == JDOTransitionFromBottom){
        moveInStartFrame = Transition_View_Bottom;
    }
    
    [self pushView:moveInView startFrame:moveInStartFrame endFrame:moveInEndFrame complete:complete];
}

- (void) pushView:(UIView *) moveInView startFrame:(CGRect)startFrame endFrame:(CGRect)endFrame complete:(void (^)())complete{
    
    [self pushView:moveInView process:^(CGRect *_startFrame, CGRect *_endFrame, NSTimeInterval *_timeInterval) {
        *_startFrame = startFrame;
        *_endFrame = endFrame;
        *_timeInterval = Transition_Time;
    } complete:complete];
}

- (void) pushView:(UIView *) moveInView process:(void (^)(CGRect*,CGRect*,NSTimeInterval*))process complete:(void (^)())complete{
    
    [moveInView addSubview:self.shadowView];
    self.blackMask.alpha = 0;
    [self.superview insertSubview:self.blackMask aboveSubview:self];
    [self.superview insertSubview:moveInView aboveSubview:self.blackMask];
    
    CGRect startFrame,endFrame;
    NSTimeInterval timeInterval;
    process(&startFrame,&endFrame,&timeInterval);
    
    moveInView.frame = startFrame;
    
    // iOS7 改变了键盘显隐时的动画，为图方便，所有使用push和pop视图的地方都使用相同的动画，该动画是私有项只能通过掩码7<<16直接设置
    NSUInteger curveType = After_iOS7 ? 7<<16 : 0;
    [UIView animateWithDuration:timeInterval delay:0 options:curveType animations:^{
        moveInView.frame = endFrame;
//        self.transform = CGAffineTransformMakeScale(Min_Scale, Min_Scale);
        self.blackMask.alpha = Max_Alpah;
    } completion:^(BOOL finished) {
        [self.shadowView removeFromSuperview];
        if(complete)    complete();
    }];
}

- (void) popView:(UIView *) presentView orientation:(JDOTransitionOrientation)orientation complete:(void (^)()) complete{
    
    CGRect moveOutStartFrame = Transition_View_Center;
    CGRect moveOutEndFrame = CGRectZero;
    if(orientation == JDOTransitionToRight){
        moveOutEndFrame = Transition_View_Right;
    }else if(orientation == JDOTransitionToBottom){
        moveOutEndFrame = Transition_View_Bottom;
    }
    [self popView:presentView startFrame:moveOutStartFrame endFrame:moveOutEndFrame complete:complete];
}

- (void) popView:(UIView *) presentView startFrame:(CGRect)startFrame endFrame:(CGRect)endFrame complete:(void (^)()) complete{
    
    [self popView:presentView process:^(CGRect *_startFrame, CGRect *_endFrame, NSTimeInterval *_timeInterval) {
        *_startFrame = startFrame;
        *_endFrame = endFrame;
        *_timeInterval = Transition_Time;
    } complete:complete];
    
}

- (void) popView:(UIView *) presentView process:(void (^)(CGRect*,CGRect*,NSTimeInterval*))process complete:(void (^)())complete{
    
//    presentView.transform = CGAffineTransformMakeScale(Min_Scale, Min_Scale);
    [self addSubview:self.shadowView];
    self.blackMask.alpha = Max_Alpah;
    [self.superview insertSubview:self.blackMask belowSubview:self];
    [self.superview insertSubview:presentView belowSubview:self.blackMask];
    
    CGRect startFrame,endFrame;
    NSTimeInterval timeInterval;
    process(&startFrame,&endFrame,&timeInterval);
    
    self.frame = startFrame;
    
    NSUInteger curveType = After_iOS7 ? 7<<16 : 0;
    [UIView animateWithDuration:timeInterval delay:0 options:curveType animations:^{
        self.frame = endFrame;
//        presentView.transform = CGAffineTransformIdentity;
        self.blackMask.alpha = 0;
    } completion:^(BOOL finished) {
        [self.shadowView removeFromSuperview];
        if(complete)    complete();
    }];
}

- (UIView *) blackMask{
    UIView  *_blackMask = objc_getAssociatedObject(self, blackMaskKey);
    if( _blackMask == nil){
        _blackMask = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320 , App_Height)];
        _blackMask.backgroundColor = [UIColor blackColor];
        objc_setAssociatedObject(self, blackMaskKey, _blackMask, OBJC_ASSOCIATION_RETAIN);
    }
    return _blackMask;
}

- (UIImageView *) shadowView{
    UIImageView  *_shadowView = objc_getAssociatedObject(self, shadowViewKey);
    if( _shadowView == nil){
        _shadowView =[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"leftside_shadow_bg"]];
        _shadowView.frame = CGRectMake(-10, 0, 10, App_Height);
        objc_setAssociatedObject(self, shadowViewKey, _shadowView, OBJC_ASSOCIATION_RETAIN);
    }
    return _shadowView;
}


@end
