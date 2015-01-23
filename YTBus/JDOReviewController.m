//
//  JDOReviewController.m
//  YTBus
//
//  Created by zhang yi on 15-1-20.
//  Copyright (c) 2015年 胶东在线. All rights reserved.
//

#import "JDOReviewController.h"
#import "UMFeedback.h"
#import "SVPullToRefresh.h"
#import "JDOConstants.h"
#import "Reachability.h"
#import "JDOConstants.h"
#import "UIView+Transition.h"

#define Feedback_Name_Width  120
#define Feedback_Name_Height 20
#define Feedback_Time_Width  120

#define Main_Background_Color @"f0f0f0"
#define Finished_Label_Tag 111
#define Default_Page_Size 20

@interface JDOReviewCell : UITableViewCell

@property (nonatomic,strong) UILabel *pubtimeLabel;
@property (nonatomic,strong) UIImageView *separatorLine;

@end

@implementation JDOReviewCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.textLabel.font = [UIFont systemFontOfSize:14];
        self.textLabel.backgroundColor = [UIColor clearColor];
        
        self.detailTextLabel.font = [UIFont systemFontOfSize:14];
        self.detailTextLabel.numberOfLines = 0;
        self.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.detailTextLabel.textColor = [UIColor colorWithHex:@"505050"];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        
        self.pubtimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(320-Feedback_Time_Width-10, 10, Feedback_Time_Width, Feedback_Name_Height)];
        self.pubtimeLabel.font = [UIFont systemFontOfSize:14];
        self.pubtimeLabel.textColor = [UIColor colorWithHex:@"969696"];
        self.pubtimeLabel.textAlignment = UITextAlignmentRight;
        self.pubtimeLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.pubtimeLabel];
        
        self.separatorLine = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.separatorLine.image = [UIImage imageNamed:@"full_separator_line"];
        [self.contentView addSubview:self.separatorLine];
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.textLabel.frame = CGRectMake(10, 10, Feedback_Name_Width, Feedback_Name_Height);
    float contentHeight = JDOSizeOfString(self.detailTextLabel.text, CGSizeMake(300, MAXFLOAT), [UIFont systemFontOfSize:Review_Font_Size], NSLineBreakByWordWrapping, 0).height;
    self.detailTextLabel.frame = CGRectMake(10, 10+Feedback_Name_Height+5, 300, contentHeight);
    self.separatorLine.frame = CGRectMake(10, 10+Feedback_Name_Height+5+contentHeight+10, 320-20, 1);
}

- (void)setModel:(NSDictionary *)model{
    if(model == nil){
        self.textLabel.text = nil;
        self.detailTextLabel.text = nil;
        self.pubtimeLabel.text = nil;
        self.separatorLine.hidden = true;
    }else{
        //        content = "\U6d4b\U8bd5";
        //        "created_at" = 1421641390815;
        //        "is_failed" = 0;
        //        "reply_id" = "CA68D3B5C-BEB5-49EA-A0E7-09FB85DEEEFF";
        //        type = "user_reply";
        self.textLabel.textColor = [UIColor colorWithHex:@"1673ba"];
        self.textLabel.text = [model[@"type"] isEqualToString:@"user_reply"]?@"我":@"烟台公交客服";
        self.detailTextLabel.text = model[@"content"];
        self.pubtimeLabel.text = [JDOUtils formatDate:[NSDate dateWithTimeIntervalSince1970:[model[@"created_at"] longValue]/1000.0f] withFormatter:DateFormatYMDHM];
        self.separatorLine.hidden = false;
    }
}

@end



@interface JDOReviewController () <UMFeedbackDataDelegate,UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UMFeedback *feedback;
@property (strong, nonatomic) UITapGestureRecognizer *closeReviewGesture;

@property (nonatomic,strong) UIImageView *noNetWorkView;
@property (nonatomic,strong) UIImageView *logoView;
@property (nonatomic,strong) UIImageView *retryView;
@property (nonatomic,strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic,assign) ViewStatusType status;

@end

@implementation JDOReviewController{
    int loadOrRefresh;  // load:0   refresh:1
}

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor colorWithHex:Main_Background_Color];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:_tableView];
    __block JDOReviewController *blockSelf = self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        [blockSelf refresh];
    }];
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [blockSelf loadMore];
    }];
    
    self.toolbar.model = self.model;
    self.toolbar.parentController = self;
    self.toolbar.typeConfig = @[ [NSNumber numberWithInt:ToolBarInputField], [NSNumber numberWithInt:ToolBarButtonReview] ];;
    self.toolbar.widthConfig = @[ @{@"frameWidth":[NSNumber numberWithFloat:270.0f],@"controlWidth":[NSNumber numberWithFloat:240.0f],@"controlHeight":[NSNumber numberWithFloat:28.0f]}, @{@"frameWidth":[NSNumber numberWithFloat:50.0f],@"controlWidth":[NSNumber numberWithFloat:47.0f],@"controlHeight":[NSNumber numberWithFloat:47.0f]} ];
    self.toolbar.theme = ToolBarThemeWhite;
    self.toolbar.btns = [[NSMutableDictionary alloc] initWithCapacity:10];
    self.toolbar.isKeyboardShowing = false;
    [self.toolbar setupToolBar];
    
    self.closeReviewGesture = [[UITapGestureRecognizer alloc] initWithTarget:self.toolbar action:@selector(hideReviewView)];
    [self.view.blackMask addGestureRecognizer:self.closeReviewGesture];
    
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
    
    self.listArray = [[NSMutableArray alloc] initWithCapacity:Default_Page_Size];
    self.feedback = [UMFeedback sharedInstance];
    self.feedback.delegate = self;
    [self loadDataFromNetwork];
}

- (void)viewWillAppear:(BOOL)animated{
    [MobClick beginLogPageView:@"feedback"];
    
    self.noNetWorkView.frame = self.view.bounds;
    self.retryView.frame = self.view.bounds;
    self.logoView.frame = self.view.bounds;
    self.activityIndicator.center = CGPointMake(self.logoView.center.x,self.logoView.center.y-80);
}

- (void)viewWillDisappear:(BOOL)animated{
    [self.toolbar hideReviewView];
}

- (void) onRetryClicked{
    self.status = ViewStatusLoading;
    self.listArray = [[NSMutableArray alloc] initWithCapacity:Default_Page_Size];
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

- (void)getFinishedWithError: (NSError *)error{
    if (error) {
        NSLog(@"错误内容--%@", error.description);
        if (loadOrRefresh == 0) {
            self.status = ViewStatusRetry;
        }else{
            [self.tableView.pullToRefreshView stopAnimating];
            //            [JDOCommonUtil showHintHUD:errorStr inView:self.view];
        }
    }else{
        if (loadOrRefresh == 0) {
            self.status = ViewStatusNormal;
        }else{
            [self.tableView.pullToRefreshView stopAnimating];
        }
        
        NSArray *dataList = [NSArray arrayWithArray:self.feedback.topicAndReplies];
        [self dataLoadFinished:dataList];
    }
}

- (void)postFinishedWithError:(NSError *)error{
    
}

- (void)stopRecordAndPlayback{
    
}

- (void)loadDataFromNetwork{
    if(![Reachability isEnableNetwork]){
        self.status = ViewStatusNoNetwork;
        return;
    }else{
        self.status = ViewStatusLoading;
    }
    loadOrRefresh = 0;
    [self.feedback get];
}




- (void) refresh{
    if(![Reachability isEnableNetwork]){
        //        [JDOCommonUtil showHintHUD:No_Network_Connection inView:self.view];
        [self.tableView.pullToRefreshView stopAnimating];
        return ;
    }
    loadOrRefresh = 1;
    [self.feedback get];
}

- (void) dataLoadFinished:(NSArray *)dataList{
    [self.listArray removeAllObjects];
    [self.listArray addObjectsFromArray:dataList];
    [self.tableView reloadData];
    if( dataList.count < Default_Page_Size ){
        [self.tableView.infiniteScrollingView setEnabled:false];
        [self.tableView.infiniteScrollingView viewWithTag:Finished_Label_Tag].hidden = false;
    }else{
        [self.tableView.infiniteScrollingView setEnabled:true];
        [self.tableView.infiniteScrollingView viewWithTag:Finished_Label_Tag].hidden = true;
    }
}

- (void) loadMore{
    //    if(![Reachability isEnableNetwork]){
    //        [JDOCommonUtil showHintHUD:No_Network_Connection inView:self.view];
    //        [self.tableView.infiniteScrollingView stopAnimating];
    //        return ;
    //    }
    //
    //    self.currentPage += 1;
    //    [self.listParam setObject:[NSNumber numberWithInt:self.currentPage] forKey:@"p"];
    //    [self prepareParam];
    //    [[JDOHttpClient sharedClient] getJSONByServiceName:_serviceName modelClass:@"JDOArrayModel" config:self.config params:self.listParam success:^(JDOArrayModel *dataModel) {
    //        NSArray *dataList = (NSArray *)dataModel.data;
    //        [self.tableView.infiniteScrollingView stopAnimating];
    //        bool finished = false;
    //        if(dataList == nil || dataList.count == 0){    // 数据加载完成
    //            finished = true;
    //        }else{
    //            NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:self.pageSize];
    //            for(int i=0;i<dataList.count;i++){
    //                [indexPaths addObject:[NSIndexPath indexPathForRow:self.listArray.count+i inSection:0]];
    //            }
    //            [self.listArray addObjectsFromArray:dataList];
    //            [self.tableView beginUpdates];
    //            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationRight];
    //            [self.tableView endUpdates];
    //
    //            if(dataList.count < self.pageSize){
    //                finished = true;
    //            }
    //        }
    //        if(finished){
    //            // 延时执行是为了给insertRowsAtIndexPaths的动画留出时间
    //            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
    //            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    //                if([self.tableView.infiniteScrollingView viewWithTag:Finished_Label_Tag]){
    //                    [self.tableView.infiniteScrollingView viewWithTag:Finished_Label_Tag].hidden = false;
    //                }else{
    //                    UILabel *finishLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.infiniteScrollingView.bounds.size.width, self.tableView.infiniteScrollingView.bounds.size.height)];
    //                    finishLabel.textAlignment = NSTextAlignmentCenter;
    //                    finishLabel.text = All_Data_Load_Finished;
    //                    finishLabel.tag = Finished_Label_Tag;
    //                    finishLabel.backgroundColor = [UIColor clearColor];
    //                    [self.tableView.infiniteScrollingView setEnabled:false];
    //                    [self.tableView.infiniteScrollingView addSubview:finishLabel];
    //                }
    //            });
    //        }
    //    } failure:^(NSString *errorStr) {
    //        [self.tableView.infiniteScrollingView stopAnimating];
    //        [JDOCommonUtil showHintHUD:errorStr inView:self.view];
    //    }];
}

- (void) backToDetailList{
    //    JDOCenterViewController *centerViewController = (JDOCenterViewController *)[SharedAppDelegate deckController].centerController;
    //    [centerViewController popToViewController:[centerViewController.viewControllers objectAtIndex:centerViewController.viewControllers.count-2] animated:true];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(self.listArray.count == 0){
        return 1;
    }
    return self.listArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"identifier";
    
    JDOReviewCell *cell = (JDOReviewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    if(cell == nil){
        cell = [[JDOReviewCell alloc] initWithReuseIdentifier:identifier];
    }
    if(self.listArray.count == 0){
        [cell setModel:nil];
    }else{
        [cell setModel:self.listArray[indexPath.row]];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(self.listArray.count == 0){
        return 0;
    }else{
        NSDictionary *model = [self.listArray objectAtIndex:indexPath.row];
        NSString *content = model[@"content"];
        
        float contentHeight = JDOSizeOfString(content, CGSizeMake(300, MAXFLOAT), [UIFont systemFontOfSize:Review_Font_Size], NSLineBreakByWordWrapping, 0).height;
        return contentHeight + Feedback_Name_Height + 10+15 /*上下边距*/ +5 /*间隔*/ ;
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
