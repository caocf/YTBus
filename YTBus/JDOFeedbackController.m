//
//  JDOFeedbackController.m
//  YTBus
//
//  Created by zhang yi on 15-1-19.
//  Copyright (c) 2015年 胶东在线. All rights reserved.
//

#import "JDOFeedbackController.h"
#import "UMFeedback.h"
#import "SVPullToRefresh.h"
#import "JDOConstants.h"
#import "Reachability.h"
#import "JDOConstants.h"
#import "UIView+Transition.h"
#import "JDONewsReviewView.h"
#import "JDOToolBar.h"
#import "HPTextViewInternal.h"

#define Feedback_Name_Width  120
#define Feedback_Name_Height 20
#define Feedback_Time_Width  150

#define Main_Background_Color @"f0f0f0"

//@class JDOFeedbackController;
//
//@interface JDOFeedbackCell : UITableViewCell
//
//@property (nonatomic,strong) UILabel *pubtimeLabel;
//@property (nonatomic,strong) UIImageView *separatorLine;
//@property (nonatomic,weak) JDOFeedbackController *controller;
//@property (nonatomic,strong) NSDictionary *model;
//
//@end
//
//@implementation JDOFeedbackCell
//
//- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
//{
//    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
//    if (self) {
//        self.backgroundColor = [UIColor clearColor];
//        self.selectionStyle = UITableViewCellSelectionStyleNone;
//        self.textLabel.font = [UIFont systemFontOfSize:14];
//        self.textLabel.backgroundColor = [UIColor clearColor];
//        
//        self.detailTextLabel.font = [UIFont systemFontOfSize:14];
//        self.detailTextLabel.numberOfLines = 0;
//        self.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
//        self.detailTextLabel.textColor = [UIColor colorWithHex:@"505050"];
//        self.detailTextLabel.backgroundColor = [UIColor clearColor];
//        
//        self.pubtimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(320-Feedback_Time_Width-10, 10, Feedback_Time_Width, Feedback_Name_Height)];
//        self.pubtimeLabel.font = [UIFont systemFontOfSize:14];
//        self.pubtimeLabel.textColor = [UIColor colorWithHex:@"969696"];
//        self.pubtimeLabel.textAlignment = UITextAlignmentRight;
//        self.pubtimeLabel.backgroundColor = [UIColor clearColor];
//        [self.contentView addSubview:self.pubtimeLabel];
//        
//        self.separatorLine = [[UIImageView alloc] initWithFrame:CGRectZero];
//        self.separatorLine.image = [UIImage imageNamed:@"full_separator_line"];
//        [self.contentView addSubview:self.separatorLine];
//        
//    }
//    return self;
//}
//
//- (void)layoutSubviews {
//    [super layoutSubviews];
//    
//    self.textLabel.frame = CGRectMake(10, 10, Feedback_Name_Width, Feedback_Name_Height);
//    float contentHeight = JDOSizeOfString(self.detailTextLabel.text, CGSizeMake(300, MAXFLOAT), [UIFont systemFontOfSize:Review_Font_Size], NSLineBreakByWordWrapping, 0).height;
//    self.detailTextLabel.frame = CGRectMake(10, 10+Feedback_Name_Height+5, 300, contentHeight);
//    self.separatorLine.frame = CGRectMake(10, 10+Feedback_Name_Height+5+contentHeight+10, 320-20, 1);
//}
//
//- (void)setContent:(NSDictionary *)model{
//    if(model == nil){
//        self.textLabel.text = nil;
//        self.detailTextLabel.text = nil;
//        self.pubtimeLabel.text = nil;
//        self.separatorLine.hidden = true;
//    }else{
//        _model = model;
//        self.textLabel.textColor = [UIColor colorWithHex:@"1673ba"];
//        self.textLabel.text = [model[@"type"] isEqualToString:@"user_reply"]?@"我":@"烟台公交客服";
//        self.detailTextLabel.text = model[@"content"];
//        // armv7下long型长度为32位，arm64下long型长度为64位，时间的毫秒数长度超过32位long型的取值范围
//        self.pubtimeLabel.text = [JDOUtils formatDate:[NSDate dateWithTimeIntervalSince1970:[model[@"created_at"] longLongValue]/1000.0] withFormatter:DateFormatYMDHM];
//        self.separatorLine.hidden = false;
//        
//        int state = [model[@"is_failed"] intValue];
//        if (state == 0) {   // 发送成功
//            self.textLabel.text = [model[@"type"] isEqualToString:@"user_reply"]?@"我(发送成功)":@"烟台公交客服";
//        }else if(state == 1){   // 发送失败
//            self.textLabel.text = [model[@"type"] isEqualToString:@"user_reply"]?@"我(发送失败)":@"烟台公交客服";
//            UIButton *resendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//            [resendBtn setTitle:@"重新发送" forState:UIControlStateNormal];
//            [resendBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
//            resendBtn.titleLabel.font = [UIFont systemFontOfSize:12];
//            resendBtn.frame = CGRectMake(85, 6, 60, 30);
//            resendBtn.tag = 1001;
//            [resendBtn addTarget:self action:@selector(resend) forControlEvents:UIControlEventTouchUpInside];
//            [self.contentView addSubview:resendBtn];
//        }else if(state == 2){   // 正在发送
//            self.textLabel.text = [model[@"type"] isEqualToString:@"user_reply"]?@"我(正在发送)":@"烟台公交客服";
//        }
//    }
//}
//
//- (void)prepareForReuse{
//    [[self.contentView viewWithTag:1001] removeFromSuperview];
//    self.model = nil;
//}
//
//- (void)resend{
//    [self.controller syncUI:_model[@"content"]];
//    [self.controller.feedback post:@{@"content":_model[@"content"]}];
//}
//
//@end


typedef enum{
    FeedbackLoadTypeLoad,
    FeedbackLoadTypeSubmit,
    FeedbackLoadTypeMore
}FeedbackLoadType;


@interface JDOFeedbackController () <UMFeedbackDataDelegate,JDOReviewTargetDelegate,UIBubbleTableViewDataSource>

@property (strong, nonatomic) UITapGestureRecognizer *closeReviewGesture;
@property (strong, nonatomic) JDONewsReviewView *reviewPanel;

@property (nonatomic,strong) UIImageView *noNetWorkView;
@property (nonatomic,strong) UIImageView *logoView;
@property (nonatomic,strong) UIImageView *retryView;
@property (nonatomic,strong) UIImageView *noDataView;
@property (nonatomic,strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic,assign) ViewStatusType status;

@end

@implementation JDOFeedbackController{
    FeedbackLoadType loadType;
    CGRect endFrame;
    NSTimeInterval timeInterval;
    BOOL isKeyboardShowing;
    NSString *toSubmitData;
}

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor colorWithHex:Main_Background_Color];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:_tableView];
    __block JDOFeedbackController *blockSelf = self;
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [blockSelf loadMore];
    }];
    self.btnItem.target = self;
    self.btnItem.action = @selector(writeReview);
    
    
    self.closeReviewGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideReviewView)];
    [self.view.blackMask addGestureRecognizer:self.closeReviewGesture];
    
    // 各种状态
    self.noDataView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"status_no_data"]];
    self.noDataView.backgroundColor = [UIColor colorWithHex:Main_Background_Color];
    self.noDataView.contentMode = UIViewContentModeScaleAspectFit;
    self.noDataView.userInteractionEnabled = true;
    [self.view addSubview:self.noDataView];
    
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
    
    self.listArray = [[NSMutableArray alloc] init];
    self.feedback = [UMFeedback sharedInstance];
    
    _reviewPanel = [[JDONewsReviewView alloc] initWithTarget:self];
    [(HPTextViewInternal *)_reviewPanel.textView.internalTextView setPlaceholder:@"请留下您的宝贵意见"];
    
    
    self.tableView.snapInterval = 120;
    self.tableView.showAvatars = YES;
    self.tableView.typingBubble = NSBubbleTypingTypeNobody;
    
}

- (NSInteger)rowsForBubbleTable:(UIBubbleTableView *)tableView
{
    return [self.listArray count];
}

- (NSDictionary *)bubbleTableView:(UIBubbleTableView *)tableView dataForRow:(NSInteger)row
{
    return [self.listArray objectAtIndex:row];
}

- (void) resendMsg:(NSString *)content{
    [self syncUI:content];
    [self.feedback post:@{@"content":content}];
}

- (void)writeReview{
    _reviewPanel.textView.text=nil;
    self.btnItem.enabled = false;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [self.view pushView:_reviewPanel process:^(CGRect *_startFrame, CGRect *_endFrame, NSTimeInterval *_timeInterval) {
        [_reviewPanel.textView becomeFirstResponder];
        isKeyboardShowing = true;
        *_startFrame = _reviewPanel.frame;
        *_endFrame = endFrame;
        *_timeInterval = timeInterval;
    } complete:^{
        
    }];
    // TODO 发送语音
}

- (void)hideReviewView{
    [_reviewPanel.textView resignFirstResponder];
    isKeyboardShowing = false;
    [_reviewPanel popView:self.view process:^(CGRect *_startFrame, CGRect *_endFrame, NSTimeInterval *_timeInterval) {
        *_startFrame = _reviewPanel.frame;
        *_endFrame = CGRectMake(0, App_Height, 320, _reviewPanel.frame.size.height);
        *_timeInterval = timeInterval;
    } complete:^{
        [_reviewPanel removeFromSuperview];
    }];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    self.btnItem.enabled = true;
}

- (void)submitReview:(id)sender{
    if([JDOUtils isEmptyString:_reviewPanel.textView.text]){
        return;
    }
    [self hideReviewView];
    
    self.btnItem.enabled = false;   // 上一条发送完成后再允许发下一条
    [self syncUI:_reviewPanel.textView.text];
    
    // 先获取最新的后台回复数据，否则时间戳错乱会导致尚未接收到的后台回复在前端丢失(每次把前端最后一条的时间作为参考去后台获取更晚的数据)
    loadType = FeedbackLoadTypeSubmit;
    toSubmitData = _reviewPanel.textView.text;
    [self.feedback get];
}

- (void)syncUI:(NSString *)text{
    NSDictionary *reply = @{@"content":text,@"created_at":[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]*1000],@"is_failed":[NSNumber numberWithInt:2],@"type":@"user_reply"};
    [self.listArray addObject:[NSMutableDictionary dictionaryWithDictionary:reply]];

    if (self.listArray.count>1) {
//        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.listArray.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView reloadData];
        [self scrollToEnd:true];
    }else{
        self.status = ViewStatusNormal;
        [self.tableView reloadData];
    }
}

- (void)postFinishedWithError:(NSError *)error{
    // 该回调在NSOperationQueue中执行，修改ui会导致页面不刷新
    [self performSelectorOnMainThread:@selector(onPostFinished:) withObject:error waitUntilDone:false];
}

- (void) onPostFinished:(NSError *)error {
    NSMutableDictionary *lastReply = [self.listArray lastObject];
    if (error) {
        NSLog(@"提交内容错误--%@", error.description);
        if ([lastReply[@"is_failed"] intValue] == 2) {
            lastReply[@"is_failed"] = [NSNumber numberWithInt:1];
        }
    }else{
        if ([lastReply[@"is_failed"] intValue] == 2) {
            lastReply[@"is_failed"] = [NSNumber numberWithInt:0];
        }
    }
    self.btnItem.enabled = true;
    [self.tableView reloadData];
}

- (void)loadDataFromNetwork{
    if(![Reachability isEnableNetwork]){
        self.status = ViewStatusNoNetwork;
        return;
    }else{
        self.status = ViewStatusLoading;
    }
    loadType = FeedbackLoadTypeLoad;
    [self.feedback get];
}

- (void) loadMore{
    if(![Reachability isEnableNetwork]){
        [JDOUtils showHUDText:@"请检查网络连接" inView:self.view];
        [self.tableView.infiniteScrollingView stopAnimating];
        return ;
    }
    loadType = FeedbackLoadTypeMore;
    [self.feedback get];
}

- (void)getFinishedWithError: (NSError *)error{
    [self performSelectorOnMainThread:@selector(onGetFinished:) withObject:error waitUntilDone:false];
}

- (void) onGetFinished:(NSError *)error{
    if (error) {
        NSLog(@"获取内容错误--%@", error.description);
        if(error.code == 1000){ // 第一次使用，尚未创建过id
            if (loadType != FeedbackLoadTypeSubmit) {
                self.status = ViewStatusLogo;
            }else{
                [self.feedback post:@{@"content":toSubmitData}];
            }
        }else{
            if (loadType == FeedbackLoadTypeLoad) {
                self.status = ViewStatusRetry;
            }else if(loadType == FeedbackLoadTypeMore){
                [self.tableView.infiniteScrollingView stopAnimating];
                [JDOUtils showHUDText:@"加载数据出错!" inView:self.view];
            }else if(loadType == FeedbackLoadTypeSubmit){
                // 提交前先获取，如果获取失败，为了防止数据不同步，则认为提交也是失败的
                NSMutableDictionary *lastReply = [self.listArray lastObject];
                if ([lastReply[@"is_failed"] intValue] == 2) {
                    lastReply[@"is_failed"] = [NSNumber numberWithInt:1];
                }
                self.btnItem.enabled = true;
                [self.tableView reloadData];
            }
        }
    }else{
        NSMutableDictionary *lastReply;
        if(loadType == FeedbackLoadTypeSubmit){
            lastReply = [self.listArray lastObject];
        }
        NSArray *dataList = [NSArray arrayWithArray:self.feedback.topicAndReplies];
        [self.listArray removeAllObjects];
        [self.listArray addObjectsFromArray:dataList];
        if (lastReply) {
            [self.listArray addObject:lastReply];
        }
        [self.tableView reloadData];
        
        if (loadType == FeedbackLoadTypeLoad) {
            self.status = ViewStatusNormal;
            [self scrollToEnd:false];
        }else if(loadType == FeedbackLoadTypeMore){
            [self.tableView.infiniteScrollingView stopAnimating];
        }else if(loadType == FeedbackLoadTypeSubmit){
            [self scrollToEnd:true];
            [self.feedback post:@{@"content":toSubmitData}];
        }
    }
}

// 显示键盘和切换输入法时都会执行
- (void)keyboardWillShow:(NSNotification *)notification{
    NSDictionary *userInfo = [notification userInfo];
    
    NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [aValue CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    CGRect reviewPanelFrame = _reviewPanel.frame;
    int deltaY = 0;
    if (After_iOS7) {
        deltaY = 64; // iOS7后，controller.view的superview(UIViewControllerWrapperView)从(0,0)开始计算，而之前是从(0,64)开始计算
    }
    reviewPanelFrame.origin.y = self.view.bounds.size.height + deltaY + 49/*tab栏高度*/ - (keyboardRect.size.height + reviewPanelFrame.size.height);
    CGRect _endFrame = reviewPanelFrame;
    
    if( isKeyboardShowing == false){
        endFrame = _endFrame;
        NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
        [animationDurationValue getValue:&timeInterval];
    }else{
        _reviewPanel.frame = _endFrame;
    }
}

- (void)keyboardWillHide:(NSNotification *)notification{
    NSDictionary *userInfo = [notification userInfo];
    
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [animationDurationValue getValue:&timeInterval];
}

- (void)viewWillAppear:(BOOL)animated{
    self.feedback.delegate = self;
    [self loadDataFromNetwork];
    
    [MobClick beginLogPageView:@"feedback"];
    
    self.noDataView.frame = self.view.bounds;
    self.noNetWorkView.frame = self.view.bounds;
    self.retryView.frame = self.view.bounds;
    self.logoView.frame = self.view.bounds;
    self.activityIndicator.center = CGPointMake(self.logoView.center.x,self.logoView.center.y-80);
    
    
}

- (void)viewWillDisappear:(BOOL)animated{
    self.feedback.delegate = nil;
    
    [MobClick endLogPageView:@"feedback"];
    [self hideReviewView];
}

- (void) onRetryClicked{
    self.status = ViewStatusLoading;
    self.listArray = [[NSMutableArray alloc] init];
    [self loadDataFromNetwork];
}

- (void) setStatus:(ViewStatusType)status{
    _status = status;
    switch (status) {
        case ViewStatusNormal:
            self.noDataView.hidden = self.logoView.hidden = self.retryView.hidden = self.noNetWorkView.hidden = self.btnItem.enabled = true;
            break;
        case ViewStatusNoNetwork:
            self.noNetWorkView.hidden = self.btnItem.enabled = false;
            self.noDataView.hidden = self.logoView.hidden = self.retryView.hidden = true;
            break;
        case ViewStatusLogo:
            self.noDataView.hidden = false;
            self.logoView.hidden = self.activityIndicator.hidden = self.btnItem.enabled = true;
            self.noNetWorkView.hidden = self.retryView.hidden = true;
            break;
        case ViewStatusLoading:
            self.logoView.hidden = self.activityIndicator.hidden = self.btnItem.enabled = false;
            self.noDataView.hidden = self.noNetWorkView.hidden = self.retryView.hidden = true;
            break;
        case ViewStatusRetry:
            self.retryView.hidden = self.btnItem.enabled = false;
            self.noDataView.hidden = self.noNetWorkView.hidden = self.logoView.hidden = true;
            break;
    }
    if(status == ViewStatusLoading){
        [self.activityIndicator startAnimating];
    }else{
        [self.activityIndicator stopAnimating];
    }
}

- (void) scrollToEnd:(BOOL)animated{
    [self.tableView scrollBubbleViewToBottomAnimated:animated];
//    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.listArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
}


//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    if(self.listArray.count == 0){
//        return 1;
//    }
//    return self.listArray.count;
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    static NSString *identifier = @"identifier";
//    
//    JDOFeedbackCell *cell = (JDOFeedbackCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
//    if(cell == nil){
//        cell = [[JDOFeedbackCell alloc] initWithReuseIdentifier:identifier];
//        cell.controller = self;
//    }
//    if(self.listArray.count == 0){
//        [cell setContent:nil];
//    }else{
//        [cell setContent:self.listArray[indexPath.row]];
//    }
//    return cell;
//}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    if(self.listArray.count == 0){
//        return 0;
//    }else{
//        NSDictionary *model = [self.listArray objectAtIndex:indexPath.row];
//        NSString *content = model[@"content"];
//        
//        float contentHeight = JDOSizeOfString(content, CGSizeMake(300, MAXFLOAT), [UIFont systemFontOfSize:Review_Font_Size], NSLineBreakByWordWrapping, 0).height;
//        return contentHeight + Feedback_Name_Height + 10+15 /*上下边距*/ +5 /*间隔*/ ;
//    }
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
