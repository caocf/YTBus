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
#import "UMFeedback.h"
#import <ShareSDK/ShareSDK.h>
#import <QZoneConnection/ISSQZoneApp.h>
#import "JDOShareController.h"

typedef enum{
    JDOSettingTypeSystem = 0,
    JDOSettingTypeNews,
    JDOSettingTypeShare,
    JDOSettingTypeFeedback,
    JDOSettingTypeFaq,
    JDOSettingTypeHelp,
    JDOSettingTypeVersion,
    JDOSettingTypeAboutus
}JDOSettingType;

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

@interface JDOMoreController () <iVersionDelegate,UMFeedbackDataDelegate>

@property (strong, nonatomic) UMFeedback *feedback;

@end

@implementation JDOMoreController{
    BOOL hasNewVersion;
    BOOL needGetFeedback;
    NSUInteger unreadNumber;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.bounces = false;
    self.tableView.backgroundColor = [UIColor colorWithHex:@"dfded9"];
    
    hasNewVersion = false;
    [iVersion sharedInstance].delegate = self;
    
    // 友盟IDFA广告
    // TODO 同步方法，最好是在本地后台获取开关
//    if ([MobClick getAdURL]) {
//        UIButton *advBtn = [UIButton buttonWithType:UIButtonTypeInfoLight];
//        advBtn.frame = CGRectMake(10, 10, 60, 30);
//        [advBtn setTitle:@"广告" forState:UIControlStateNormal];
//        [advBtn addTarget:self action:@selector(showAdvView) forControlEvents:UIControlEventTouchUpInside];
//        self.tableView.tableHeaderView = advBtn;
//    }
    
    // 注册UMFeedback的时候就会获取一遍数据，若已经有新反馈，则直接显示提示。如果没有新反馈，还有可能在应用启动到切换到“更多”tab页这段时间有新的反馈，则再重新获取一遍
    unreadNumber= 0;
    self.feedback = [UMFeedback sharedInstance];
    if (self.feedback.theNewReplies.count>0) {
        unreadNumber = self.feedback.theNewReplies.count;
        needGetFeedback = false;
    }else{
        needGetFeedback = true;
    }
}

- (void)viewWillAppear:(BOOL)animated{
    self.feedback.delegate = self;
    if (needGetFeedback) {
        [self.feedback get];
    }else{
        needGetFeedback = true;
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    self.feedback.delegate = nil;
}

- (void)getFinishedWithError: (NSError *)error{
    [self performSelectorOnMainThread:@selector(onGetFinished:) withObject:error waitUntilDone:false];
}

- (void)onGetFinished:(NSError *)error{
    if (error) {
        NSLog(@"获取内容错误--%@", error.description);
    }else{
        unreadNumber += self.feedback.theNewReplies.count;
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:JDOSettingTypeFeedback inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }
}

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
    if (indexPath.row == JDOSettingTypeVersion) {   // 检查更新
        if (hasNewVersion) {
            [[iVersion sharedInstance] openAppPageInAppStore];
        }else{
            [[iVersion sharedInstance] checkForNewVersion];
        }
    }else if(indexPath.row == JDOSettingTypeFeedback){
//        [self.navigationController pushViewController:[UMFeedback feedbackViewController] animated:YES];
//        [self presentModalViewController:[UMFeedback feedbackModalViewController] animated:YES];
    }else if(indexPath.row == JDOSettingTypeShare){
        // TODO 全局替换m.jiaodong.net
        NSString *content = @"我正在使用“烟台公交”查询公交车的实时位置,你也来试试吧!";
        id<ISSContent> publishContent = [ShareSDK content:content defaultContent:nil image:[ShareSDK jpegImageWithImage:[UIImage imageNamed:@"分享80"] quality:1.0] title:@"“烟台公交”上线啦！等车不再捉急，到点准时来接你。" url:@"http://m.jiaodong.net" description:content mediaType:SSPublishContentMediaTypeNews];
        
        //QQ使用title和content(大概26个字以内)，但能显示字数更少。
        [publishContent addQQUnitWithType:INHERIT_VALUE content:content title:@"“烟台公交”上线啦！" url:INHERIT_VALUE image:INHERIT_VALUE];
        [publishContent addQQSpaceUnitWithTitle:@"“烟台公交”上线啦！" url:INHERIT_VALUE site:@"胶东在线" fromUrl:@"http://www.jiaodong.net" comment:nil summary:content image:INHERIT_VALUE type:INHERIT_VALUE playUrl:INHERIT_VALUE nswb:INHERIT_VALUE];
        
        id<ISSQZoneApp> app =(id<ISSQZoneApp>)[ShareSDK getClientWithType:ShareTypeQQSpace];
        NSObject *qZone;
        if (app.isClientInstalled) {
            qZone = SHARE_TYPE_NUMBER(ShareTypeQQSpace);
        }else{
            qZone = [self getShareItem:ShareTypeQQSpace content:content];
        }
        
        NSArray *shareList = [ShareSDK customShareListWithType:SHARE_TYPE_NUMBER(ShareTypeWeixiSession),SHARE_TYPE_NUMBER(ShareTypeWeixiTimeline),SHARE_TYPE_NUMBER(ShareTypeQQ),qZone,[self getShareItem:ShareTypeSinaWeibo content:content],[self getShareItem:ShareTypeRenren content:content],nil];
        
        [ShareSDK showShareActionSheet:nil shareList:shareList content:publishContent statusBarTips:NO authOptions:nil shareOptions:nil result:^(ShareType type, SSResponseState state, id<ISSPlatformShareInfo> statusInfo, id<ICMErrorInfo> error, BOOL end) {
            if (state == SSResponseStateSuccess){
                NSLog(@"分享成功");
            }else if (state == SSResponseStateFail){
                [JDOUtils showHUDText:[NSString stringWithFormat:@"分享失败,错误码:%ld",(long)[error errorCode]] inView:self.view];
            }
        }
         ];
    }
}

- (id<ISSShareActionSheetItem>) getShareItem:(ShareType) type content:(NSString *)content{
    return [ShareSDK shareActionSheetItemWithTitle:[ShareSDK getClientNameWithType:type] icon:[ShareSDK getClientIconWithType:type] clickHandler:^{
        JDOShareController *vc = [[JDOShareController alloc] initWithImage:nil content:content type:type];
        UINavigationController *naVC = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:naVC animated:true completion:nil];
    }];
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == JDOSettingTypeVersion) {
        [[iVersion sharedInstance] checkForNewVersion];
    }else if(indexPath.row == JDOSettingTypeFeedback){
        [[cell.contentView viewWithTag:1003] removeFromSuperview];
        if (unreadNumber > 0) {
            UILabel *hint = [[UILabel alloc] initWithFrame:CGRectMake(130, 12, 80, 20)];
            hint.tag = 1003;
            hint.font = [UIFont systemFontOfSize:12];
            hint.backgroundColor = [UIColor clearColor];
            hint.textColor = [UIColor redColor];
            hint.text = [NSString stringWithFormat:@"(%lu条新消息)",(unsigned long)unreadNumber];
            [cell.contentView addSubview:hint];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"toFeedback"]) {
        unreadNumber = 0;
    }
}

//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MoreCell" forIndexPath:indexPath];
//    cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"表格圆角中"]];
//    return cell;
//}


@end
