//
//  JDOMainTabController.m
//  YTBus
//
//  Created by zhang yi on 14-10-31.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDOMainTabController.h"
#import "JDOConstants.h"
#import "UMFeedback.h"
#import "JDOHttpClient.h"
#import "JSONKit.h"
#import "iVersion.h"

@interface JDOMainTabController () <UITabBarDelegate,iVersionDelegate>

@property (strong, nonatomic) UMFeedback *feedback;

@end

@implementation JDOMainTabController{
    BOOL notShowHint;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }
    
    self.tabBar.backgroundImage = [UIImage imageNamed:@"导航底图"];
    if (After_iOS7){
        self.tabBar.itemPositioning = UITabBarItemPositioningFill;
        self.tabBar.translucent = false;
    }
    
    // 设置tabBarItem的图标
    NSArray *imageNames = @[@"附近",@"线路",@"站点",@"换乘",@"更多"];
    for(int i=0; i<self.tabBar.items.count; i++){
        UITabBarItem *item = self.tabBar.items[i];
        item.title = nil;
        // 按TabBar的默认item大小128*96进行裁图会让图标向上偏移
        item.imageInsets = UIEdgeInsetsMake(5.5, 0, -5.5, 0);
        UIImage *selectedImg = [UIImage imageNamed:[imageNames[i] stringByAppendingString:@"2"]];
        UIImage *unselectedImg = [UIImage imageNamed:[imageNames[i] stringByAppendingString:@"1"]];
        if (After_iOS7) {
            item.image = [unselectedImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            item.selectedImage = [selectedImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        }else{
            [item setFinishedSelectedImage:selectedImg withFinishedUnselectedImage:unselectedImg];
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    notShowHint = false;

    // UITabBarController本身就会把self设置为tabBar的delegate，这里再手动设置反而会报错！
//    self.tabBar.delegate = self;
    
    //TODO 在这里就检查一遍意见反馈和新闻资讯，有新的话在“更多”那里加红点提示
    self.feedback = [UMFeedback sharedInstance];
    if (self.feedback.theNewReplies.count>0) {
        [self showHintPoint];
    }else if([[NSUserDefaults standardUserDefaults] boolForKey:@"JDO_Read_Guide"] == false){
        [self showHintPoint];
    }
    
    // 检查最新资讯
    long newestAid = [[NSUserDefaults standardUserDefaults] integerForKey:@"JDO_Newest_Aid"]?:1;
    [[JDOHttpClient sharedJDOClient] getPath:@"Data/getNewestAid" parameters:@{@"aid":@(newestAid),@"cid":@"47"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSData *jsonData = responseObject;
        NSDictionary *obj = [jsonData objectFromJSONData];
        if ([obj[@"status"] isEqualToString:@"exist"]) {
            [self showHintPoint];
            self.newsId = obj[@"data"];
            self.hasNewInfo = true;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
    
    // 检查新版本
    // Apple新的审核规范禁止应用内版本升级检查
//    [iVersion sharedInstance].delegate = self;
//    [[iVersion sharedInstance] checkForNewVersion];
}

- (void)iVersionDidNotDetectNewVersion{
    self.hasNewVersion = 1;
}

- (void)iVersionVersionCheckDidFailWithError:(NSError *)error{
    self.hasNewVersion = 2;
}

- (void)iVersionDidDetectNewVersion:(NSString *)version details:(NSString *)versionDetails{
    self.versionNumber = version;
    self.hasNewVersion = 3;
}

- (BOOL)iVersionShouldDisplayNewVersion:(NSString *)version details:(NSString *)versionDetails{
    return false;   // 不使用弹出Alert的方式提示新版本
}

- (void) showHintPoint {
    UIView *badge = [self.tabBar viewWithTag:7001];
    if (!badge && !notShowHint) {
        badge = [[UIView alloc] initWithFrame:CGRectMake(298, 3, 8, 8)];
        badge.layer.cornerRadius = 4;
        badge.tag = 7001;
        badge.backgroundColor = [UIColor colorWithHex:@"da4000"];
        [self.tabBar addSubview:badge];
    }
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item{
    if (item == [tabBar.items lastObject]) {
        [[tabBar viewWithTag:7001] removeFromSuperview];
        notShowHint = true;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    UIViewController *vc = [segue destinationViewController];
//}


@end
