//
//  JDOMoreController.m
//  YTBus
//
//  Created by zhang yi on 14-12-22.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDOMoreController.h"
#import "JDOConstants.h"
#import "iVersion.h"
#import "UIViewController+MJPopupViewController.h"

@interface JDOUmengAdvController : UIViewController <UIWebViewDelegate>

@end

@implementation JDOUmengAdvController

- (void)loadView{
    [super loadView];

    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectInset([UIScreen mainScreen].bounds, 20, 80)];
    webView.delegate = self;
    webView.scalesPageToFit = true;
    NSString *advURL = [[MobClick getAdURL] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [webView loadRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:advURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5]];
    
    self.view = webView;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    
}

@end

@interface JDOMoreCell : UITableViewCell

@end

@implementation JDOMoreCell

- (id)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]){
        self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"表格圆角中"]];
        return self;
    }
    return nil;
}

@end

@interface JDOMoreController () <iVersionDelegate>

@end

@implementation JDOMoreController{
    BOOL hasNewVersion;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.bounces = false;
    self.tableView.backgroundColor = [UIColor colorWithHex:@"dfded9"];
    
    hasNewVersion = false;
    [iVersion sharedInstance].delegate = self;
    [[iVersion sharedInstance] checkForNewVersion];
    
    // 友盟IDFA广告
//    UIButton *advBtn = [UIButton buttonWithType:UIButtonTypeInfoLight];
//    advBtn.frame = CGRectMake(10, 10, 60, 30);
//    [advBtn setTitle:@"广告" forState:UIControlStateNormal];
//    [advBtn addTarget:self action:@selector(showAdvView) forControlEvents:UIControlEventTouchUpInside];
//    self.tableView.tableHeaderView = advBtn;
    
//    ADBannerView *bannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
//    bannerView.delegate = self;
//    bannerView.alpha = 0;
//    self.tableView.tableHeaderView = bannerView;
}

//- (void) bannerViewDidLoadAd:(ADBannerView *)banner {
//    [UIView animateWithDuration:0.5 animations:^{
//        bannerView.alpha = 1.0;
//    }];
//}
//
//- (void) bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error{
//    NSLog(@"加载iAd错误:%@",error);
//    [UIView animateWithDuration:0.5 animations:^{
//        bannerView.alpha = 0.0;
//    }];
//}

- (void)showAdvView {
    JDOUmengAdvController *advController = [[JDOUmengAdvController alloc] init];
    [self presentPopupViewController:advController animationType:MJPopupViewAnimationFade];
}

- (void)iVersionDidNotDetectNewVersion{
    UITableViewCell *checkUpdateCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:6 inSection:0]];
    UILabel *hintLabel = (UILabel *)[checkUpdateCell.contentView viewWithTag:1002];
    hintLabel.text = @"当前已是最新版本";
    hasNewVersion = false;
}

- (void)iVersionVersionCheckDidFailWithError:(NSError *)error{
    UITableViewCell *checkUpdateCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:6 inSection:0]];
    UILabel *hintLabel = (UILabel *)[checkUpdateCell.contentView viewWithTag:1002];
    hintLabel.text = @"无法检查新版本";
    hasNewVersion = false;
}

- (void)iVersionDidDetectNewVersion:(NSString *)version details:(NSString *)versionDetails{
    UITableViewCell *checkUpdateCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:6 inSection:0]];
    UILabel *hintLabel = (UILabel *)[checkUpdateCell.contentView viewWithTag:1002];
    hintLabel.text = [NSString stringWithFormat:@"发现新版本%@",version];
    hasNewVersion = true;
}

- (BOOL)iVersionShouldDisplayNewVersion:(NSString *)version details:(NSString *)versionDetails{
    return false;   // 不使用弹出Alert的方式提示新版本
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 6) {   // 检查更新
        if (hasNewVersion) {
            [[iVersion sharedInstance] openAppPageInAppStore];
        }else{
            [[iVersion sharedInstance] checkForNewVersion];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 15;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 15;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 15)];
    iv.image = [UIImage imageNamed:@"表格圆角上"];
    return iv;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 15)];
    iv.image = [UIImage imageNamed:@"表格圆角下"];
    return iv;
}


//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MoreCell" forIndexPath:indexPath];
//    cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"表格圆角中"]];
//    return cell;
//}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
