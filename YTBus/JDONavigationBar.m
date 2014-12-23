//
//  JDONavigationBar.m
//  YTBus
//
//  Created by zhang yi on 14-11-19.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDONavigationBar.h"
#import "JDOConstants.h"

@implementation JDONavigationBar

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }
    if (After_iOS7){
        // 若设置该选项=false，则self.view的origin.y从导航栏以下开始计算，否则从屏幕顶端开始计算，
        // 这是因为iOS7的controller中extendedLayoutIncludesOpaqueBars属性默认是false，也就是说不透明的bar不启用extendedLayout，
        // 若背景是半透明的情况下，也可以通过设置controller的edgesForExtendedLayout使view从导航栏下方开始计算
        self.translucent = false;
        [self setBackgroundImage:[UIImage imageNamed:@"navigation_iOS7"] forBarMetrics:UIBarMetricsDefault];
    }else{
        [self setBackgroundImage:[UIImage imageNamed:@"navigation_iOS6"] forBarMetrics:UIBarMetricsDefault];
    }
//    UITextAttributeFont,UITextAttributeTextShadowOffset,UITextAttributeTextShadowColor
    self.titleTextAttributes = @{UITextAttributeTextColor:[UIColor whiteColor]};
    
    return self;
}

@end
