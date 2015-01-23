//
//  JDOFeedbackController.h
//  YTBus
//
//  Created by zhang yi on 15-1-19.
//  Copyright (c) 2015年 胶东在线. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JDOToolBar.h"
#import "JDOToolbarModel.h"
#import "UMFeedback.h"
#import "UIBubbleTableView.h"

@interface JDOFeedbackController : UIViewController

@property (nonatomic,strong) IBOutlet UIBubbleTableView *tableView;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *btnItem;

@property (nonatomic,strong) NSMutableArray *listArray;

@property (strong, nonatomic) UMFeedback *feedback;

- (void)syncUI:(NSString *)text;

@end
