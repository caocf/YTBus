//
//  JDORealTimeController.m
//  YTBus
//
//  Created by zhang yi on 14-10-21.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDORealTimeController.h"
#import "BMapKit.h"

@interface JDORealTimeController ()

@end

@implementation JDORealTimeController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = self.naviTitle;
    UIBarButtonItem *rightBtnItem = [[UIBarButtonItem alloc] initWithTitle:@"地图" style:UIBarButtonItemStylePlain target:self action:@selector(switchMode:)];
    [self.navigationItem setRightBarButtonItem:rightBtnItem];
}

- (void)switchMode:(UIBarButtonItem *)btn{
    btn.enabled = false;
    CATransition *animation = [CATransition animation];
    animation.delegate = self;
    animation.duration = 1.2;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.removedOnCompletion = YES;
    animation.type = @"oglFlip";
    if ([btn.title isEqualToString:@"地图"]) {
        UIView *mapView = [[UIView alloc] initWithFrame:self.view.bounds];
        mapView.backgroundColor = [UIColor redColor];
        mapView.tag = 1001;
        [self.view addSubview:mapView];
        animation.subtype = kCATransitionFromRight;
    }else{
        UIView *mapView = [self.view viewWithTag:1001];
        [mapView removeFromSuperview];
        animation.subtype = kCATransitionFromLeft;
    }
    [self.view.layer addAnimation:animation forKey:@"animation"];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    UIBarButtonItem *rightBtnItem = self.navigationItem.rightBarButtonItem;
    rightBtnItem.enabled = true;
    if([rightBtnItem.title isEqualToString:@"地图"]){
        rightBtnItem.title = @"列表";
    }else{
        rightBtnItem.title = @"地图";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
