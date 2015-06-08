//
//  JDOAboutUsController.m
//  YTBus
//
//  Created by zhang yi on 15-1-8.
//  Copyright (c) 2015年 胶东在线. All rights reserved.
//

#import "JDOAboutUsController.h"
#import "JDOUtils.h"
#import "AppDelegate.h"

@interface JDOAboutUsController ()

@property (nonatomic,strong) NSMutableString *banAdvPwd;

@end

@implementation JDOAboutUsController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated{
    _banAdvPwd = [[NSMutableString alloc] init];
    for (int tag=8001; tag<8005; tag++) {
        [[self.view viewWithTag:tag] addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onPwdClicked:)]];
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    _banAdvPwd = nil;
    for (int tag=8001; tag<8005; tag++) {
        UIView *view = [self.view viewWithTag:tag];
        if(view.gestureRecognizers.count>0){
            [view removeGestureRecognizer:view.gestureRecognizers[0]];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)onPwdClicked:(UITapGestureRecognizer *)gesture{
    [_banAdvPwd appendFormat:@"%ld",(long)gesture.view.tag-8000];
    if ([_banAdvPwd isEqualToString:@"1423"]) {
        AppDelegate *delegate = [UIApplication sharedApplication].delegate;
        if([delegate.systemParam[@"allowBanAdv"] isEqualToString:@"1"]){
            BOOL flg = [[NSUserDefaults standardUserDefaults] boolForKey:@"JDO_Ban_Adv"];
            if (flg) {
                [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"JDO_Ban_Adv"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [JDOUtils showHUDText:@"已允许广告展示" inView:self.view];
            }else{
                [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"JDO_Ban_Adv"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [JDOUtils showHUDText:@"已屏蔽广告展示" inView:self.view];
            }
        }
    }
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
