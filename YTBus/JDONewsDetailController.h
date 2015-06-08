//
//  JDONewsDetailController.h
//  JiaodongOnlineNews
//
//  Created by zhang yi on 13-6-4.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WebViewJavascriptBridge_iOS.h"

@class JDONewsModel;

@interface JDONewsDetailController : UIViewController <UITextViewDelegate>

@property (nonatomic,strong) JDONewsModel *newsModel;
@property (strong, nonatomic) WebViewJavascriptBridge *bridge;
@property (nonatomic,strong) UIWebView *webView;

- (id)initWithNewsModel:(JDONewsModel *)newsModel;

@end
