//
//  Created by ShareSDK.cn on 13-1-14.
//  官网地址:http://www.mob.com
//  技术支持邮箱:support@sharesdk.cn
//  官方微信:ShareSDK   （如果发布新版本的话，我们将会第一时间通过微信将版本更新内容推送给您。如果使用过程中有任何问题，也可以通过微信与我们取得联系，我们将会在24小时内给予回复）
//  商务QQ:4006852216
//  Copyright (c) 2013年 ShareSDK.cn. All rights reserved.
//
#import "JDOShareController.h"
#import <AGCommon/UIImage+Common.h>
#import <AGCommon/UIDevice+Common.h>
#import <AGCommon/UINavigationBar+Common.h>
#import <AGCommon/UIColor+Common.h>
#import <AGCommon/NSString+Common.h>
#import "JDOConstants.h"

#define PADDING_LEFT 5.0
#define PADDING_TOP 5.0
#define PADDING_RIGHT 5.0
#define PADDING_BOTTOM 5.0
#define HORIZONTAL_GAP 2.0
#define VERTICAL_GAP 5.0

#define IMAGE_PADDING_TOP 19
#define IMAGE_PADDING_RIGHT 10

#define PIN_PADDING_TOP 4

#define WORD_COUNT_LABEL_PADDING_RIGHT 10
#define WORD_COUNT_LABEL_PADDING_BOTTOM 19

@interface JDOShareController () <ISSViewDelegate>

@end


@implementation JDOShareController{
    NSInteger count;
}

- (id)initWithImage:(UIImage *)image content:(NSString *)content type:(ShareType)type{
    self = [self init];
    if (self){
        _image = image;
        _content = content;
        _type = type;
    }
    return self;
}

- (id)init{
    self = [super init];
    if (self){
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonClickHandler:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"发布" style:UIBarButtonItemStylePlain target:self action:@selector(publishButtonClickHandler:)];
        self.title = @"我要分享";
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    if ([[UIDevice currentDevice].systemVersion versionStringCompare:@"7.0"] != NSOrderedAscending){
        [self setExtendedLayoutIncludesOpaqueBars:NO];
        [self setEdgesForExtendedLayout:SSRectEdgeBottom | SSRectEdgeLeft | SSRectEdgeRight];
    }
    self.view.backgroundColor = [UIColor colorWithHex:@"dfded9"];
    
    _contentBG = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"5sBG"]];
    _contentBG.frame = CGRectMake(10, 10, 300, 186);
    [self.view addSubview:_contentBG];
	
    //图片
//    _picBG = [[UIImageView alloc] initWithImage:_image];
//    _picBG.frame = CGRectMake(234, Screen_Height>480?45:70, 65, Screen_Height>480?117:98);
//    _picBG.contentMode = UIViewContentModeScaleToFill;
//    [self.view addSubview:_picBG];
    
    _pinImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SharePin"]];
    _pinImageView.frame = CGRectMake(CGRectGetWidth(self.view.frame) - CGRectGetWidth(_pinImageView.frame)-7, 10, CGRectGetWidth(_pinImageView.frame), CGRectGetHeight(_pinImageView.frame));
    _pinImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.view addSubview:_pinImageView];
    
    UILabel *contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 23, 200, 60)];
    contentLabel.numberOfLines = 3;
    contentLabel.backgroundColor = [UIColor clearColor];
    contentLabel.font = [UIFont systemFontOfSize:14.0];
    contentLabel.textColor = [UIColor lightGrayColor];
    contentLabel.text = _content;
    [contentLabel sizeToFit];
    [self.view addSubview:contentLabel];
    
    //文本框
    _textView = [[UITextView alloc] initWithFrame:CGRectMake(18, 79, 204, 105)];
    _textView.backgroundColor = [UIColor clearColor];
    _textView.font = [UIFont systemFontOfSize:14.0];
    _textView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _textView.layer.borderWidth = 1.0f;
    _textView.layer.cornerRadius = 5;
    _textView.delegate = self;
    [self.view addSubview:_textView];
    
    //字数
    _wordCountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _wordCountLabel.backgroundColor = [UIColor clearColor];
    _wordCountLabel.textColor = [UIColor colorWithRGB:0xd2d2d2];
    _wordCountLabel.text = @"70";
    _wordCountLabel.font = [UIFont boldSystemFontOfSize:15];
    [_wordCountLabel sizeToFit];
    _wordCountLabel.frame = CGRectMake(198,168,30,15);
    [self.view addSubview:_wordCountLabel];
    
    [self updateWordCount];
    [_textView becomeFirstResponder];
}

#pragma mark - Private

- (void)updateWordCount{
    count = 70 - [_textView.text length];
    _wordCountLabel.text = [NSString stringWithFormat:@"%ld", (long)count];
    
    if (count < 0){
        _wordCountLabel.textColor = [UIColor redColor];
    }else{
        _wordCountLabel.textColor = [UIColor colorWithRGB:0xd2d2d2];
    }
}

- (void)cancelButtonClickHandler:(id)sender{
    [_textView resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)publishButtonClickHandler:(id)sender{    
    id<ISSContent> publishContent = [ShareSDK content:[_textView.text stringByAppendingFormat:@"//%@",_content]
                                       defaultContent:nil
                                                image:[ShareSDK jpegImageWithImage:[UIImage imageNamed:@"iphone5s"] quality:1]
                                                title:@"“烟台公交”上线啦！"
                                                  url:Redirect_Url
                                          description:[_textView.text stringByAppendingFormat:@"//%@",_content]
                                            mediaType:SSPublishContentMediaTypeText];
    // QQ空间的内容
//    [publishContent addQQSpaceUnitWithTitle:INHERIT_VALUE url:INHERIT_VALUE site:@"胶东在线" fromUrl:@"http://www.jiaodong.net" comment:[JDOUtils isEmptyString:_textView.text]?@"分享":_textView.text summary:_content image:INHERIT_VALUE type:INHERIT_VALUE playUrl:INHERIT_VALUE nswb:INHERIT_VALUE];
    
    [publishContent addSinaWeiboUnitWithContent:[_textView.text stringByAppendingFormat:@"//%@//下载地址:%@",_content,Redirect_Url] image:INHERIT_VALUE];
    // 人人的内容，ShareSDK的bug，把description和message搞成一样的了
    [publishContent addRenRenUnitWithName:@"“烟台公交”上线啦！等车不再捉急，到点准时来接你。" description:_content url:INHERIT_VALUE message:[JDOUtils isEmptyString:_textView.text]?@"分享":_textView.text image:INHERIT_VALUE caption:INHERIT_VALUE];
    
    id<ISSAuthOptions> authOptions = [ShareSDK authOptionsWithAutoAuth:YES
                                                         allowCallback:YES
                                                         authViewStyle:SSAuthViewStyleModal
                                                          viewDelegate:nil
                                               authManagerViewDelegate:nil];
    
    
    BOOL needAuth = NO;
    if (![ShareSDK hasAuthorizedWithType:_type]){
        needAuth = YES;
        [ShareSDK getUserInfoWithType:_type authOptions:authOptions result:^(BOOL result, id<ISSPlatformUser> userInfo, id<ICMErrorInfo> error) {
            if (result){
               [ShareSDK shareContent:publishContent type:_type authOptions:authOptions statusBarTips:NO result:^(ShareType type, SSResponseState state, id<ISSPlatformShareInfo> statusInfo, id<ICMErrorInfo> error, BOOL end) {
                   if (error) {
                       [JDOUtils showHUDText:@"分享失败，请重试" inView:self.view];
                       NSLog(@"%@",error.errorDescription);
                       [self performSelector:@selector(textGetFocus) withObject:nil afterDelay:1.0f];
                   }else{
                       [_textView resignFirstResponder];
                       [self dismissViewControllerAnimated:YES completion:nil];
                   }
               }];
            }else{
               [JDOUtils showHUDText:@"授权失败，请重试" inView:self.view];
                [self performSelector:@selector(textGetFocus) withObject:nil afterDelay:1.0f];
            }
       }];
    }
    
    if (!needAuth){
        [ShareSDK shareContent:publishContent type:_type authOptions:authOptions statusBarTips:NO result:^(ShareType type, SSResponseState state, id<ISSPlatformShareInfo> statusInfo, id<ICMErrorInfo> error, BOOL end) {
            if (error) {
                [JDOUtils showHUDText:@"分享失败，请重试" inView:self.view];
                NSLog(@"%@",error.errorDescription);
                [self performSelector:@selector(textGetFocus) withObject:nil afterDelay:1.0f];
            }else{
                [_textView resignFirstResponder];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }];
    }
}

- (void)viewOnWillDismiss:(UIViewController *)viewController shareType:(ShareType)shareType{
    
}
- (void) textGetFocus{
    [_textView becomeFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView
{
    [self updateWordCount];
}

@end
