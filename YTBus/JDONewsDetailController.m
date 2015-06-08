//
//  JDONewsDetailController.m
//  JiaodongOnlineNews
//
//  Created by zhang yi on 13-6-4.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import "JDONewsDetailController.h"
#import "JDONewsModel.h"
#import "JDONewsDetailModel.h"
#import "JDOConstants.h"
#import "UIWebView+RemoveShadow.h"
#import "Reachability.h"
#import "JDOHttpClient.h"
#import "JSONKit.h"

@interface JDONewsDetailController () <UIWebViewDelegate>

@property (nonatomic,strong) UIImageView *noNetWorkView;
@property (nonatomic,strong) UIImageView *logoView;
@property (nonatomic,strong) UIImageView *retryView;
@property (nonatomic,strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic,assign) ViewStatusType status;

@end

@implementation JDONewsDetailController{
    NSArray *imageUrls;
}

- (id)initWithNewsModel:(JDONewsModel *)newsModel{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.newsModel = newsModel;
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.navigationItem.title = @"公交资讯";
    
    self.view.backgroundColor = [UIColor colorWithHex:Main_Background_Color];// 与html的body背景色相同
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.webView makeTransparentAndRemoveShadow];
    self.webView.delegate = self;
    self.webView.scalesPageToFit = true;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.webView];
    
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
    
    [self.retryView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loadWebView)]];
    [self.noNetWorkView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loadWebView)]];
    
    [self loadWebView];
    [self buildWebViewJavascriptBridge];
    
    
}

- (void)viewWillAppear:(BOOL)animated{
    self.noNetWorkView.frame = self.view.bounds;
    self.retryView.frame = self.view.bounds;
    self.logoView.frame = self.view.bounds;
    self.activityIndicator.center = CGPointMake(self.logoView.center.x,self.logoView.center.y-80);
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

- (void) loadWebView{
    if( ![Reachability isEnableNetwork]){
        self.status = ViewStatusNoNetwork;
    }else{
        self.status = ViewStatusLoading;
        [[JDOHttpClient sharedJDOClient] getPath:@"Data/getArticleByAid" parameters:@{@"aid":self.newsModel.id} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSData *jsonData = responseObject;
            NSDictionary *obj = [jsonData objectFromJSONData];
            if ([obj[@"status"] intValue]==1) {
                if ([obj[@"data"] isKindOfClass:[NSDictionary class]]) {
                    NSString *mergedHTML = [JDONewsDetailModel mergeToHTMLTemplateFromDictionary:obj[@"data"]];
                    [self.webView loadHTMLString:mergedHTML baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath] isDirectory:true]];
                }else{
                    self.status = ViewStatusRetry;
                }
            }else{
                self.status = ViewStatusRetry;
                [JDOUtils showHUDText:obj[@"info"] inView:self.view];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            self.status = ViewStatusRetry;
            [JDOUtils showHUDText:error.localizedDescription inView:self.view];
        }];
        
    }
}

-(void) callJsToRefreshWebview:(NSString *)realUrl andLocal:(NSString *) localUrl {
    //图片加载成功，调用js，刷新图片
    NSMutableString *js = [[NSMutableString alloc] init];
    [js appendString:@"refreshImg('"];
    [js appendString:realUrl];
    [js appendString:@"', '"];
    [js appendString:localUrl];
    [js appendString:@"')"];
    [self.webView stringByEvaluatingJavaScriptFromString:js];
    
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        return false;
    }
    return true;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    self.status = ViewStatusNormal;
    //webview加载完成，再开始异步加载图片
//    if(imageUrls) {
//        for (int i=0; i<[imageUrls count]; i++) {
//            NSString *realUrl = [imageUrls objectAtIndex:i];
//            NSURL *url = [NSURL URLWithString:realUrl];
//            SDImageCache *imageCache = [SDImageCache sharedImageCache];
//            UIImage *cachedImage = [imageCache imageFromKey:realUrl fromDisk:YES]; // 将需要缓存的图片加载进来
//            if (cachedImage) {
//                [self callJsToRefreshWebview:realUrl andLocal:[imageCache cachePathForKey:realUrl]];
//            } else {
//                if ([JDOCommonUtil ifNoImage]) {//3g下，不下载图片
//                    [self callJsToRefreshWebview:realUrl andLocal:@"base_empty_view.png"];
//                } else {
//                    SDWebImageManager *manager = [SDWebImageManager sharedManager];
//                    [manager downloadWithURL:url delegate:self storeDelegate:self];
//                }
//            }
//        }
//    }
    
}

- (void) buildWebViewJavascriptBridge{
//    _bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
//        NSLog(@"ObjC received message from JS: %@", data);
//        responseCallback(@"Response for message from ObjC");
//    }];
}

@end
