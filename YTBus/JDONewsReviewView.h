//
//  JDONewsReviewView.h
//  JiaodongOnlineNews
//
//  Created by zhang yi on 13-6-16.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPGrowingTextView.h"
#import "JDOToolBar.h"

@interface JDONewsReviewView : UIView <HPGrowingTextViewDelegate>

@property (strong, nonatomic) HPGrowingTextView *textView;
@property (strong, nonatomic) UILabel *remainWordNum;
@property (strong, nonatomic) id<JDOReviewTargetDelegate> target;

- (id)initWithTarget:(id<JDOReviewTargetDelegate>)target;
- (NSArray *)selectedClients;
- (CGRect) initialFrame;

@end
