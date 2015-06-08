//
//  JDONewsController.m
//  YTBus
//
//  Created by zhang yi on 14-12-26.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDONewsController.h"
#import "MBProgressHUD.h"
#import "JDOConstants.h"
#import "SVPullToRefresh.h"
#import "JDOHttpClient.h"
#import "Reachability.h"
#import "JDONewsHeadCell.h"
#import "JDONewsTableCell.h"
#import "JSONKit.h"
#import "JDONewsModel.h"
#import "JDONewsDetailController.h"
#import "JDOAlertTool.h"

#define NewsHead_Page_Size 3
#define NewsList_Page_Size 20
#define News_Cell_Height 70.0f
#define Finished_Label_Tag 111

@interface JDONewsController ()

@property (nonatomic,strong) UIImageView *noNetWorkView;
@property (nonatomic,strong) UIImageView *logoView;
@property (nonatomic,strong) UIImageView *retryView;
@property (nonatomic,strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic,assign) ViewStatusType status;

@end

@implementation JDONewsController{
    MBProgressHUD *HUD;
    BOOL needReloadHeaderSection;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem.target = self;
    self.navigationItem.rightBarButtonItem.action = @selector(showDownloadAlert);
    
    self.currentPage = 1;
    self.tableView.backgroundColor = [UIColor colorWithHex:Main_Background_Color];
    
    __block JDONewsController *blockSelf = self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        [blockSelf refresh];
    }];
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [blockSelf loadMore];
    }];
    self.headArray = [[NSMutableArray alloc] initWithCapacity:NewsHead_Page_Size];
    self.listArray = [[NSMutableArray alloc] initWithCapacity:NewsList_Page_Size];
    
    // 各种状态
    self.noNetWorkView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"status_no_network"]];
    self.noNetWorkView.backgroundColor = [UIColor colorWithHex:Main_Background_Color];
    self.noNetWorkView.contentMode = UIViewContentModeScaleAspectFit;
    self.noNetWorkView.userInteractionEnabled = true;
    [self.view addSubview:self.noNetWorkView];
    
    self.retryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"status_retry"]];
    self.retryView.backgroundColor = [UIColor colorWithHex:Main_Background_Color];
    self.retryView.contentMode = UIViewContentModeScaleAspectFit;
    self.retryView.userInteractionEnabled = true;
    [self.view addSubview:self.retryView];
    
    self.logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"status_logo"]];
    self.logoView.backgroundColor = [UIColor colorWithHex:Main_Background_Color];
    self.logoView.contentMode = UIViewContentModeScaleAspectFit;
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.activityIndicator sizeToFit];
    [self.logoView addSubview:self.activityIndicator];
    [self.view addSubview:self.logoView];
    
    [self.retryView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onRetryClicked)]];
    [self.noNetWorkView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onRetryClicked)]];
    self.status = ViewStatusLoading;
    [self loadDataFromNetwork];
}

- (void)showDownloadAlert{
    JDOAlertTool *alert = [[JDOAlertTool alloc] init];
    [alert showAlertView:self title:@"强烈推荐" message:@"“看天下，知烟台”，更多新闻、资讯、爆料内容，尽在烟台第一掌上媒体“胶东在线新闻客户端”。" cancelTitle:@"关闭" otherTitle1:@"前往下载" otherTitle2:nil cancelAction:^{
        
    } otherAction1:^{
        NSURL *url = [NSURL URLWithString:@"itms-apps://itunes.apple.com/cn/app/jiao-dong-zai-xian/id693957416?mt=8"];
        [[UIApplication sharedApplication] openURL:url];
    } otherAction2:nil];
}

- (void)viewWillAppear:(BOOL)animated{
    [MobClick beginLogPageView:@"newslist"];
    [MobClick event:@"newslist"];
    [MobClick beginEvent:@"newslist"];
    
    self.noNetWorkView.frame = self.view.bounds;
    self.retryView.frame = self.view.bounds;
    self.logoView.frame = self.view.bounds;
    self.activityIndicator.center = CGPointMake(self.logoView.center.x,self.logoView.center.y-80);
}

- (void)viewWillDisappear:(BOOL)animated{
    [MobClick endLogPageView:@"newslist"];
    [MobClick endEvent:@"newslist"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) onRetryClicked{
    self.status = ViewStatusLoading;
    self.headArray = [[NSMutableArray alloc] initWithCapacity:NewsHead_Page_Size];
    self.listArray = [[NSMutableArray alloc] initWithCapacity:NewsList_Page_Size];
    [self loadDataFromNetwork];
}

- (void) setStatus:(ViewStatusType)status{
    _status = status;
    switch (status) {
        case ViewStatusNormal:
            self.logoView.hidden = self.retryView.hidden = self.noNetWorkView.hidden = true;
            break;
        case ViewStatusNoNetwork:
            self.noNetWorkView.hidden = false;
            self.logoView.hidden = self.retryView.hidden = true;
            break;
        case ViewStatusLogo:
            self.logoView.hidden = false;
            self.activityIndicator.hidden = true;
            self.noNetWorkView.hidden = self.retryView.hidden = true;
            break;
        case ViewStatusLoading:
            self.logoView.hidden = self.activityIndicator.hidden = false;
            self.noNetWorkView.hidden = self.retryView.hidden = true;
            break;
        case ViewStatusRetry:
            self.retryView.hidden = false;
            self.noNetWorkView.hidden = self.logoView.hidden = true;
            break;
    }
    if(status == ViewStatusLoading){
        [self.activityIndicator startAnimating];
    }else{
        [self.activityIndicator stopAnimating];
    }
}

- (NSDictionary *) newsListParam{
    return @{@"channelid":@"47",@"p":[NSNumber numberWithInt:self.currentPage],@"pageSize":@NewsList_Page_Size,@"natype":@"a"};
}

- (NSDictionary *) headLineParam{
    return @{@"channelid":@"47",@"p":[NSNumber numberWithInt:1],@"pageSize":@NewsHead_Page_Size,@"atype":@"a"};
}

- (void)loadDataFromNetwork{
    __block bool headlineFinished = false;
    __block bool newslistFinished = false;
    
    [[JDOHttpClient sharedJDOClient] getPath:@"Data/getArticles" parameters:self.headLineParam success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSData *jsonData = responseObject;
        NSDictionary *obj = [jsonData objectFromJSONData];
        if ([obj[@"status"] intValue]==1) {
            NSArray *data = obj[@"data"];
            NSMutableArray *dataList = [NSMutableArray new];
            for (int i = 0; i < data.count; i++) {
                JDONewsModel *newsModel = [[JDONewsModel alloc] initWithDict:[data objectAtIndex:i]];
                [dataList addObject:newsModel];
            }
            if(dataList.count >0){
                [self.headArray removeAllObjects];
                [self.headArray addObjectsFromArray:dataList];
                headlineFinished = true;
                if(newslistFinished){
                    [self reloadTableView];
                }
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.status = ViewStatusRetry;
        [JDOUtils showHUDText:error.localizedDescription inView:self.view];
    }];
    
    // 加载列表
    [[JDOHttpClient sharedJDOClient] getPath:@"Data/getArticles" parameters:self.newsListParam success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSData *jsonData = responseObject;
        NSDictionary *obj = [jsonData objectFromJSONData];
        if ([obj[@"status"] intValue]==1) {
            NSArray *data = obj[@"data"];
            NSMutableArray *dataList = [NSMutableArray new];
            for (int i = 0; i < data.count; i++) {
                JDONewsModel *newsModel = [[JDONewsModel alloc] initWithDict:[data objectAtIndex:i]];
                [dataList addObject:newsModel];
            }
            if(dataList.count >0){
                [self.listArray removeAllObjects];
                [self.listArray addObjectsFromArray:dataList];
                newslistFinished = true;
                if(headlineFinished){
                    [self reloadTableView];
                }
                if(dataList.count<NewsList_Page_Size ){
                    [self.tableView.infiniteScrollingView setEnabled:false];
                    // 总数量不足第一页时不显示"已加载完成"提示
                    [self.tableView.infiniteScrollingView viewWithTag:Finished_Label_Tag].hidden = true;
                }else{
                    [self.tableView.infiniteScrollingView setEnabled:true];
                    [self.tableView.infiniteScrollingView viewWithTag:Finished_Label_Tag].hidden = true;
                }
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.status = ViewStatusRetry;
        [JDOUtils showHUDText:error.localizedDescription inView:self.view];
    }];
}


- (void) refresh{
    if(![Reachability isEnableNetwork]){
        [JDOUtils showHUDText:@"网络当前不可用" inView:self.view];
        [self.tableView.pullToRefreshView stopAnimating];
        return ;
    }
    self.currentPage = 1;
    __block bool headlineFinished = false;
    __block bool newslistFinished = false;
    // 刷新头条
    [[JDOHttpClient sharedJDOClient] getPath:@"Data/getArticles" parameters:self.headLineParam success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSData *jsonData = responseObject;
        NSDictionary *obj = [jsonData objectFromJSONData];
        if ([obj[@"status"] intValue]==1) {
            NSArray *data = obj[@"data"];
            NSMutableArray *dataList = [NSMutableArray new];
            for (int i = 0; i < data.count; i++) {
                JDONewsModel *newsModel = [[JDONewsModel alloc] initWithDict:[data objectAtIndex:i]];
                [dataList addObject:newsModel];
            }
            if(dataList.count >0){
                [self.headArray removeAllObjects];
                [self.headArray addObjectsFromArray:dataList];
                headlineFinished = true;
                if(newslistFinished){
                    [self reloadTableView];
                }
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.tableView.pullToRefreshView stopAnimating];
        [JDOUtils showHUDText:error.localizedDescription inView:self.view];
    }];
    
    // 刷新列表
    [[JDOHttpClient sharedJDOClient] getPath:@"Data/getArticles" parameters:self.newsListParam success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSData *jsonData = responseObject;
        NSDictionary *obj = [jsonData objectFromJSONData];
        if ([obj[@"status"] intValue]==1) {
            NSArray *data = obj[@"data"];
            NSMutableArray *dataList = [NSMutableArray new];
            for (int i = 0; i < data.count; i++) {
                JDONewsModel *newsModel = [[JDONewsModel alloc] initWithDict:[data objectAtIndex:i]];
                [dataList addObject:newsModel];
            }
            if(dataList.count >0){
                [self.listArray removeAllObjects];
                [self.listArray addObjectsFromArray:dataList];
                newslistFinished = true;
                if(headlineFinished){
                    [self reloadTableView];
                }
                if(dataList.count<NewsList_Page_Size ){
                    [self.tableView.infiniteScrollingView setEnabled:false];
                    // 总数量不足第一页时不显示"已加载完成"提示
                    [self.tableView.infiniteScrollingView viewWithTag:Finished_Label_Tag].hidden = true;
                }else{
                    [self.tableView.infiniteScrollingView setEnabled:true];
                    [self.tableView.infiniteScrollingView viewWithTag:Finished_Label_Tag].hidden = true;
                }
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.tableView.pullToRefreshView stopAnimating];
        [JDOUtils showHUDText:error.localizedDescription inView:self.view];
    }];
}

- (void) reloadTableView{
    self.status = ViewStatusNormal;
    [self.tableView.pullToRefreshView stopAnimating];
    [self updateLastRefreshTime];
    needReloadHeaderSection = true;
    [self.tableView reloadData];
}

// 更新下拉刷新控件的时间
- (void) updateLastRefreshTime{
    self.lastUpdateTime = [NSDate date];
#warning 使用NSDate+SSToolkitAdditions来表示文字描述的刷新时间,但没有办法使pullToRefreshView每次下拉时都刷新时间
    NSString *updateTimeStr = [JDOUtils formatDate:self.lastUpdateTime withFormatter:DateFormatYMDHM];
    [self.tableView.pullToRefreshView setSubtitle:[NSString stringWithFormat:@"上次刷新于:%@",updateTimeStr] forState:SVPullToRefreshStateAll];
}


- (void) loadMore{
    if(![Reachability isEnableNetwork]){
        [JDOUtils showHUDText:@"网络当前不可用" inView:self.view];
        [self.tableView.infiniteScrollingView stopAnimating];
        return ;
    }
    
    self.currentPage += 1;
    [[JDOHttpClient sharedJDOClient] getPath:@"Data/getArticles" parameters:self.newsListParam success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self.tableView.infiniteScrollingView stopAnimating];
        NSData *jsonData = responseObject;
        NSDictionary *obj = [jsonData objectFromJSONData];
        if ([obj[@"status"] intValue]==1) {
            NSArray *data = obj[@"data"];
            NSMutableArray *dataList = [NSMutableArray new];
            for (int i = 0; i < data.count; i++) {
                JDONewsModel *newsModel = [[JDONewsModel alloc] initWithDict:[data objectAtIndex:i]];
                [dataList addObject:newsModel];
            }
            bool finished = false;
            if( dataList.count == 0){    // 数据加载完成
                finished = true;
            }else{
                NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:NewsList_Page_Size];
                for(int i=0;i<dataList.count;i++){
                    [indexPaths addObject:[NSIndexPath indexPathForRow:self.listArray.count+i inSection:1]];
                }
                [self.listArray addObjectsFromArray:dataList];
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationRight];
                [self.tableView endUpdates];
                
                if(dataList.count < NewsList_Page_Size){
                    finished = true;
                }
            }
            if(finished){
                [self.tableView.infiniteScrollingView setEnabled:false];
                // 延时执行是为了给insertRowsAtIndexPaths的动画留出时间
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    if([self.tableView.infiniteScrollingView viewWithTag:Finished_Label_Tag]){
                        [self.tableView.infiniteScrollingView viewWithTag:Finished_Label_Tag].hidden = false;
                    }else{
                        UILabel *finishLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.infiniteScrollingView.bounds.size.width, self.tableView.infiniteScrollingView.bounds.size.height)];
                        finishLabel.textAlignment = NSTextAlignmentCenter;
                        finishLabel.font = [UIFont systemFontOfSize:16];
                        finishLabel.textColor = [UIColor colorWithWhite:130/255.0f alpha:1.0];
                        finishLabel.text = @"全部数据加载完成";
                        finishLabel.tag = Finished_Label_Tag;
                        finishLabel.backgroundColor = [UIColor clearColor];
                        [self.tableView.infiniteScrollingView addSubview:finishLabel];
                    }
                });
            }
        }else{
            self.currentPage -= 1;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.tableView.infiniteScrollingView stopAnimating];
        self.currentPage -= 1;
        [JDOUtils showHUDText:error.localizedDescription inView:self.view];
    }];
}

// 将普通新闻和头条划分为两个section
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0){
        return 1;
    }else{
        return self.listArray.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *headIdentifier = @"headCell";
    static NSString *listIdentifier = @"listCell";
    if(indexPath.section == 0){
        JDONewsHeadCell *cell = [tableView dequeueReusableCellWithIdentifier:headIdentifier];
        if(self.headArray.count > 0 && needReloadHeaderSection){
            [cell setModels:self.headArray];
            for(int i=0; i<cell.imageViews.count; i++){
                [[cell.imageViews objectAtIndex:i] addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(galleryImageClicked:)]];
            }
            needReloadHeaderSection = false;
        }
        return cell;
    }else{
        JDONewsTableCell *cell = [tableView dequeueReusableCellWithIdentifier:listIdentifier];
        JDONewsModel *newsModel = nil;
        if(self.listArray.count > 0){
            newsModel = [self.listArray objectAtIndex:indexPath.row];
        }
        if (newsModel != nil) {
            [cell setModel:newsModel];
        }
        return cell;
    }
}

- (void) galleryImageClicked:(UITapGestureRecognizer *)gesture{
    JDONewsHeadCell *cell = (JDONewsHeadCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    NSUInteger index = [cell.imageViews indexOfObject:gesture.view];
    JDONewsDetailController *detailController = [[JDONewsDetailController alloc] initWithNewsModel:[self.headArray objectAtIndex:index]];
    [self.navigationController pushViewController:detailController animated:true];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == 0)  return Headline_Height;
    return News_Cell_Height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == 0){
        // section0 由于存在scrollView与didSelectRowAtIndexPath冲突，不会进入该函数，通过给UIImageView设置gesture的方式解决
    }else{
        JDONewsModel* model = [self.listArray objectAtIndex:indexPath.row];
        JDONewsDetailController *detailController = [[JDONewsDetailController alloc] initWithNewsModel:model];
        [self.navigationController pushViewController:detailController animated:true];
        [tableView deselectRowAtIndexPath:indexPath animated:true];
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
