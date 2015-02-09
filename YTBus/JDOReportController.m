//
//  JDOReportController.m
//  YTBus
//
//  Created by zhang yi on 15-2-9.
//  Copyright (c) 2015年 胶东在线. All rights reserved.
//

#import "JDOReportController.h"
#import "SSTextView.h"
#import "JDOConstants.h"
#import "IQKeyboardManager.h"

#define TextColor [UIColor colorWithRed:100/255.0f green:100/255.0f blue:100/255.0f alpha:1.0f]

@interface JDOReportController () <UITextFieldDelegate,UITextViewDelegate>

@end

@implementation JDOReportController{
    NSString *_station;
    NSString *_direction;
}

- (id)init{
    self = [super init];
    if (self){
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonClickHandler:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"提交" style:UIBarButtonItemStylePlain target:self action:@selector(publishButtonClickHandler:)];
        self.title = @"我要纠错";
    }
    return self;
}

-(id)initWithStation:(NSString *)station direction:(NSString *)direction{
    self = [self init];
    if (self){
        _station = station;
        _direction = direction;
    }
    return self;
}

-(void)loadView{
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view = scrollView;
}

- (void)viewWillAppear:(BOOL)animated{
    [[IQKeyboardManager sharedManager] setEnable:true];
}

- (void)viewWillDisappear:(BOOL)animated{
    [[IQKeyboardManager sharedManager] setEnable:false];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (After_iOS7){
        [self setExtendedLayoutIncludesOpaqueBars:NO];
    }
    self.view.backgroundColor = [UIColor colorWithHex:@"dfded9"];
    
    // line1
    int deltaY = 10;
//    UIImageView *line1BG = [[UIImageView alloc] initWithFrame:CGRectMake(10, deltaY, 300, 40)];
//    line1BG.image = [[UIImage imageNamed:@"纠错-输入框"] stretchableImageWithLeftCapWidth:3 topCapHeight:3];
//    [self.view addSubview:line1BG];
    UIImageView *icon1 = [[UIImageView alloc] initWithFrame:CGRectMake(20, deltaY+6.5f, 22, 17)];
    icon1.image = [UIImage imageNamed:@"纠错-时间"];
    [self.view addSubview:icon1];
    UILabel *line1Label = [[UILabel alloc] initWithFrame:CGRectMake(50, deltaY, 260, 30)];
    line1Label.backgroundColor = [UIColor clearColor];
    line1Label.font = [UIFont systemFontOfSize:14];
    line1Label.textColor = TextColor;
    line1Label.text = [JDOUtils formatDate:[NSDate date] withFormatter:DateFormatYMDHM];
    [self.view addSubview:line1Label];
    
    // line2
    deltaY += 30;
//    UIImageView *line2BG = [[UIImageView alloc] initWithFrame:CGRectMake(10, deltaY, 300, 40)];
//    line2BG.image = [[UIImage imageNamed:@"纠错-输入框"] stretchableImageWithLeftCapWidth:3 topCapHeight:3];
//    [self.view addSubview:line2BG];
    UIImageView *icon2 = [[UIImageView alloc] initWithFrame:CGRectMake(20, deltaY+6.5f, 22, 17)];
    icon2.image = [UIImage imageNamed:@"纠错-线路"];
    [self.view addSubview:icon2];
    UILabel *line2Label = [[UILabel alloc] initWithFrame:CGRectMake(50, deltaY, 260, 30)];
    line2Label.backgroundColor = [UIColor clearColor];
    line2Label.font = [UIFont systemFontOfSize:14];
    line2Label.textColor = TextColor;
    line2Label.text = _direction;
    [self.view addSubview:line2Label];
    
    // line3
    if (_station) {
        deltaY += 30;
//        UIImageView *line3BG = [[UIImageView alloc] initWithFrame:CGRectMake(10, deltaY, 300, 40)];
//        line3BG.image = [[UIImage imageNamed:@"纠错-输入框"] stretchableImageWithLeftCapWidth:3 topCapHeight:3];
//        [self.view addSubview:line3BG];
        UIImageView *icon3 = [[UIImageView alloc] initWithFrame:CGRectMake(20, deltaY+6.5f, 22, 17)];
        icon3.image = [UIImage imageNamed:@"纠错-定位"];
        [self.view addSubview:icon3];
        UILabel *line3Label = [[UILabel alloc] initWithFrame:CGRectMake(50, deltaY, 260, 30)];
        line3Label.backgroundColor = [UIColor clearColor];
        line3Label.font = [UIFont systemFontOfSize:14];
        line3Label.textColor = TextColor;
        line3Label.text = _station;
        [self.view addSubview:line3Label];
    }
    
    //line4
    deltaY += 40;
    UIImageView *line4BG = [[UIImageView alloc] initWithFrame:CGRectMake(10, deltaY, 300, 40)];
    line4BG.image = [[UIImage imageNamed:@"纠错-输入框"] stretchableImageWithLeftCapWidth:3 topCapHeight:3];
    [self.view addSubview:line4BG];
    UIImageView *icon4 = [[UIImageView alloc] initWithFrame:CGRectMake(20, deltaY+11.5f, 22, 17)];
    icon4.image = [UIImage imageNamed:@"纠错-电话"];
    [self.view addSubview:icon4];
    UITextField *line4Label = [[UITextField alloc] initWithFrame:CGRectMake(50, deltaY, 260, 40)];
    line4Label.backgroundColor = [UIColor clearColor];
    line4Label.font = [UIFont systemFontOfSize:14];
    line4Label.textColor = TextColor;
    line4Label.placeholder = @"请输入手机号码";
    line4Label.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:line4Label];
    
    //line5
    deltaY += 50;
    UIImageView *line5BG = [[UIImageView alloc] initWithFrame:CGRectMake(10, deltaY, 300, 120)];
    line5BG.image = [[UIImage imageNamed:@"纠错-输入框"] stretchableImageWithLeftCapWidth:3 topCapHeight:3];
    [self.view addSubview:line5BG];
    UIImageView *icon5 = [[UIImageView alloc] initWithFrame:CGRectMake(20, deltaY+11.5f, 22, 17)];
    icon5.image = [UIImage imageNamed:@"纠错-输入"];
    [self.view addSubview:icon5];
    SSTextView *line5Label = [[SSTextView alloc] initWithFrame:CGRectMake(45, deltaY+3, 265, 117)];
    line5Label.backgroundColor = [UIColor clearColor];
    line5Label.font = [UIFont systemFontOfSize:14];
    line5Label.textColor = TextColor;
    line5Label.placeholder = @"请填写纠错内容";
    line5Label.placeholderTextColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
    [self.view addSubview:line5Label];
}

- (void)cancelButtonClickHandler:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)publishButtonClickHandler:(id)sender{
    // TODO 后台数据接口，以及数据有效性校验
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
