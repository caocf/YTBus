//
//  JDOFaqController.m
//  YTBus
//
//  Created by zhang yi on 15-5-12.
//  Copyright (c) 2015年 胶东在线. All rights reserved.
//

#import "JDOFaqController.h"
#import "JDOConstants.h"
#import "JDOHttpClient.h"
#import "Reachability.h"
#import "JSONKit.h"
#import "UIWebView+RemoveShadow.h"
#import "MGTemplateEngine.h"
#import "ICUTemplateMatcher.h"

@interface JDOFaqController () <UIWebViewDelegate>

@property (nonatomic,strong) UIImageView *noNetWorkView;
@property (nonatomic,strong) UIImageView *logoView;
@property (nonatomic,strong) UIImageView *retryView;
@property (nonatomic,strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic,assign) ViewStatusType status;

@end

@implementation JDOFaqController{
    long selectedRow;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    selectedRow = -1;
    self.tableView.backgroundColor = [UIColor colorWithHex:Main_Background_Color];
    
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

- (void)viewWillAppear:(BOOL)animated{
    self.noNetWorkView.frame = self.view.bounds;
    self.retryView.frame = self.view.bounds;
    self.logoView.frame = self.view.bounds;
    self.activityIndicator.center = CGPointMake(self.logoView.center.x,self.logoView.center.y-80);
}

- (void)viewWillDisappear:(BOOL)animated{

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) onRetryClicked{
    self.status = ViewStatusLoading;
    self.listArray = [[NSMutableArray alloc] initWithCapacity:20];
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

- (void)loadDataFromNetwork{
    [[JDOHttpClient sharedBUSClient] getPath:@"index/getQas" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSData *jsonData = responseObject;
        NSDictionary *obj = [jsonData objectFromJSONData];
        NSString *status = obj[@"status"];
        if ([status isEqualToString:@"success"]) {
            NSArray *data = obj[@"data"];
            self.listArray = [[NSMutableArray alloc] initWithCapacity:20];
            for (int i = 0; i < data.count; i++) {
                [self.listArray addObject:data[i]];
            }
            self.status = ViewStatusNormal;
            [self.tableView reloadData];
        }else{
            self.status = ViewStatusRetry;
            [JDOUtils showHUDText:obj[@"info"] inView:self.view];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.status = ViewStatusRetry;
        [JDOUtils showHUDText:error.localizedDescription inView:self.view];
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"faqCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    cell.backgroundColor = [UIColor clearColor];
    
    UIImageView *bg = (UIImageView *)[cell.contentView viewWithTag:1001];
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:1002];
    UILabel *seq = (UILabel *)[cell.contentView viewWithTag:1003];
    UIWebView *webView = (UIWebView *)[cell viewWithTag:1004];
    
    seq.text = [NSString stringWithFormat:@"%ld.",(long)indexPath.row+1];
    NSDictionary *obj = self.listArray[indexPath.row];
    label.text = obj[@"title"];
    
    if (indexPath.row == selectedRow) {
        seq.textColor = [UIColor whiteColor];
        label.textColor = [UIColor whiteColor];
        seq.shadowColor = [UIColor colorWithHex:@"505050"];
        label.shadowColor = [UIColor colorWithHex:@"505050"];
        bg.image = [UIImage imageNamed:@"faq_background_selected"];
        webView.hidden = false;
    }else{
        seq.textColor = [UIColor colorWithHex:@"505050"];
        label.textColor = [UIColor colorWithHex:@"505050"];
        seq.shadowColor = [UIColor whiteColor];
        label.shadowColor = [UIColor whiteColor];
        bg.image = [UIImage imageNamed:@"faq_background"];
        webView.hidden = true;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (selectedRow == indexPath.row) {
        return 250+44;
    }
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    selectedRow = indexPath.row;
    [tableView reloadData];
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:true];
    
    MGTemplateEngine *engine = [self sharedTemplateEngine];
    [engine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:engine]];
    NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"template" ofType:@"html"];
    NSDictionary *obj = self.listArray[indexPath.row];
    NSDictionary *variables = @{@"content":obj[@"content"], @"font_class":@"small_font"};
    NSString *mergedHTML = [engine processTemplateInFileAtPath:templatePath withVariables:variables];

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedRow inSection:0]];
    UIWebView *webView = (UIWebView *)[cell viewWithTag:1004];
    [webView makeTransparentAndRemoveShadow];
    [webView loadHTMLString:mergedHTML baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath] isDirectory:true]];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{

}

- (MGTemplateEngine *) sharedTemplateEngine{
    static MGTemplateEngine *_sharedEngine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedEngine = [MGTemplateEngine templateEngine];
    });
    return _sharedEngine;
}


@end
