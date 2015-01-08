//
//  JDOAboutUsController.m
//  YTBus
//
//  Created by zhang yi on 15-1-8.
//  Copyright (c) 2015年 胶东在线. All rights reserved.
//

#import "JDOAboutUsController.h"

@interface JDOAboutUsController ()

@end

@implementation JDOAboutUsController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onTelClicked
{
    NSString *num = [[NSString alloc] initWithFormat:@"telprompt://6690009"];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:num]];
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
