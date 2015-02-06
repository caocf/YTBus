//
//  Created by ShareSDK.cn on 13-1-14.
//  官网地址:http://www.mob.com
//  技术支持邮箱:support@sharesdk.cn
//  官方微信:ShareSDK   （如果发布新版本的话，我们将会第一时间通过微信将版本更新内容推送给您。如果使用过程中有任何问题，也可以通过微信与我们取得联系，我们将会在24小时内给予回复）
//  商务QQ:4006852216
//  Copyright (c) 2013年 ShareSDK.cn. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <ShareSDK/ShareSDK.h>

/**
 *	@brief	自定义分享视图控制器
 */
@interface JDOShareController : UIViewController <UITextViewDelegate>
{
@private
    UITextView *_textView;
    UIImageView *_contentBG;
    UIImageView *_picBG;
    UIImageView *_pinImageView;
    UILabel *_wordCountLabel;
    
    UIImage *_image;
    NSString *_content;
    ShareType _type;
    CGFloat _keyboardHeight;
}

/**
 *	@brief	初始化视图控制器
 *
 *	@param 	image 	图片
 *	@param 	content 	内容
 *
 *	@return	视图控制器
 */
- (id)initWithImage:(UIImage *)image content:(NSString *)content type:(ShareType)type ;


@end
