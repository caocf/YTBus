//
//  JDONewsReviewView.m
//  JiaodongOnlineNews
//
//  Created by zhang yi on 13-6-16.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import "JDONewsReviewView.h"
#import "JDOConstants.h"

#define Review_Text_Init_Height 44
#define Review_ShareBar_Height 40
#define Review_Input_Height 35

#define Review_Left_Margin 10
#define Review_Right_Margin 10
#define SubmitBtn_Width 55
#define Review_Content_MaxLength 130
#define Review_SubmitBtn_Tag 200

@interface JDONewsReviewView ()

@property (strong, nonatomic) UILabel *textLabel;
@property (strong, nonatomic) NSMutableArray *shareTypeArray;

@end

@implementation JDONewsReviewView{

}

- (id)initWithTarget:(id<JDOReviewTargetDelegate>)target
{
    self = [super initWithFrame: [self initialFrame]];
    if (self) {
        self.target = target;
        self.backgroundColor = [UIColor colorWithHex:@"f0f0f0"];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        
        // HPGrowingTextView根据字体的大小有最小高度限制,15号字最少需要35的高度
        _textView = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(Review_Left_Margin, (Review_Text_Init_Height-Review_Input_Height)/2.0, 240+5, Review_Input_Height)];
        _textView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
        _textView.font = [UIFont systemFontOfSize:15];  // 先设置font，在minNumberOfLines中需要用到
        _textView.minNumberOfLines = 1;
        _textView.maxNumberOfLines = 4;
        _textView.delegate = self;
        _textView.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
//        _textView.animateHeightChange = NO; //turns off animation
        _textView.backgroundColor = [UIColor whiteColor];
        

        // 必须有2x的图片!!!!!否则retina下不起作用,即使图片大小满足2x的尺寸也不行
        UIImage *inputMaskImg = [[UIImage imageNamed:@"inputField"] stretchableImageWithLeftCapWidth:0 topCapHeight:10];
//        UIImage *inputBorderImg = [[UIImage imageNamed:@"inputField"] resizableImageWithCapInsets:UIEdgeInsetsMake(1, 1, 1, 1)];
        UIImageView *inputMask = [[UIImageView alloc] initWithImage:inputMaskImg];
        
        inputMask.frame = CGRectMake(0, 0, 320, Review_Text_Init_Height);
        inputMask.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        
//        UIImageView *background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"inputFieldType2"]];
//        background.frame = CGRectMake(0, 0, 320, Review_Text_Init_Height);
//        background.autoresizingMask = UIViewAutoresizingFlexibleHeight ;
        
//        [self addSubview:background];
        [self addSubview:_textView];
        [self addSubview:inputMask];
        
        UIButton *submitBtn = [UIButton buttonWithType:UIButtonTypeCustom] ;
        submitBtn.tag = Review_SubmitBtn_Tag;
        submitBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
        submitBtn.frame = CGRectMake(320-Review_Right_Margin-SubmitBtn_Width, (Review_Text_Init_Height-30)/2.0, SubmitBtn_Width, 30);
        [submitBtn addTarget:target action:@selector(submitReview:) forControlEvents:UIControlEventTouchUpInside];
        [submitBtn setTitle:@"发表" forState:UIControlStateNormal];
        [submitBtn setTitleShadowColor:[UIColor colorWithWhite:0 alpha:0.4] forState:UIControlStateNormal];
        submitBtn.titleLabel.shadowOffset = After_iOS7?CGSizeMake(0, 0):CGSizeMake(0, -1);
        submitBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        [submitBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        NSString *btnBackground = After_iOS7?@"input_btn~iOS7":@"input_btn";
        [submitBtn setBackgroundImage:[UIImage imageNamed:btnBackground] forState:UIControlStateNormal];
        [submitBtn setBackgroundImage:[UIImage imageNamed:btnBackground] forState:UIControlStateSelected];
        [self addSubview:submitBtn];
        
        _remainWordNum = [[UILabel alloc] initWithFrame:CGRectMake(320-Review_Right_Margin-SubmitBtn_Width+2, 7, SubmitBtn_Width, 30)];
        _remainWordNum.hidden = true;
        _remainWordNum.backgroundColor =[UIColor clearColor];
        _remainWordNum.numberOfLines = 2;
        _remainWordNum.font = [UIFont systemFontOfSize:12];
        _remainWordNum.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
        [self addSubview:_remainWordNum];
        
    }
    return self;
}

- (void)dealloc{
    
    
}

- (CGRect) initialFrame{
    return CGRectMake(0, App_Height, 320, Review_Text_Init_Height);
}

- (NSArray *)selectedClients
{
    NSMutableArray *clients = [NSMutableArray array];
    
    for (int i = 0; i < [_shareTypeArray count]; i++)
    {
        NSDictionary *item = [_shareTypeArray objectAtIndex:i];
        if ([[item objectForKey:@"selected"] boolValue])
        {
            [clients addObject:[item objectForKey:@"type"]];
        }
    }
    
    return clients;
}

#pragma mark - GrowingTextView delegate

//- (BOOL)growingTextViewShouldBeginEditing:(HPGrowingTextView *)growingTextView;
//- (BOOL)growingTextViewShouldEndEditing:(HPGrowingTextView *)growingTextView;

//- (void)growingTextViewDidBeginEditing:(HPGrowingTextView *)growingTextView;
//- (void)growingTextViewDidEndEditing:(HPGrowingTextView *)growingTextView;

- (BOOL)growingTextView:(HPGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if (After_iOS7) { // iOS7 文本输入到最大值的时候再输入汉字状态的拼音会闪退
        if (range.location >= Review_Content_MaxLength){
            return false;
        }
    }
    return YES;
} 
- (void)growingTextViewDidChange:(HPGrowingTextView *)growingTextView{
    // 计算剩余可输入字数
    int remain = Review_Content_MaxLength-_textView.text.length;
    [_remainWordNum setText:[NSString stringWithFormat:@"还有%d字可以输入",remain<0 ? 0:remain]];
    // 使用-1是因为，在还差2个字到上限的时候输入中文，输入两个字母再删除一个，之后若再输入一个字母，系统会自动添加上一个空格，这样会造成文本总长度比上限大1。导致对编辑的内容进行substring，而iOS7中不允许对用户正在输入的内容进行裁剪，直接出异常
    if (remain<-1) {
        // 在这里substring是为了避免复制粘贴进来的内容直接超过最大限制。并且如果超过最大长度，shouldChangeTextInRange:中的location越界会造成删除也无法进行
         _textView.text = [_textView.text substringWithRange:[_textView.text rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, Review_Content_MaxLength)] ];
    }
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height{
    float diff = (growingTextView.frame.size.height - height);
    
	CGRect r = self.frame;
    r.size.height -= diff;
    r.origin.y += diff;
	self.frame = r;
    
    if(r.size.height > Review_Input_Height*3-10){
        [_remainWordNum setHidden:false];
    }else{
        [_remainWordNum setHidden:true];
    }
}
//- (void)growingTextView:(HPGrowingTextView *)growingTextView didChangeHeight:(float)height;

//- (void)growingTextViewDidChangeSelection:(HPGrowingTextView *)growingTextView;
//- (BOOL)growingTextViewShouldReturn:(HPGrowingTextView *)growingTextView;

#pragma mark - TextView delegate

//- (void)textViewDidBeginEditing:(UITextView *)textView{
//
//}
//- (void)textViewDidEndEditing:(UITextView *)textView{
//
//}
//
//- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
//    if (range.location>=Review_Max_Length){
//        return  NO;
//    }else{
//        return YES;
//    }
//}
//
//- (void)textViewDidChange:(UITextView *)textView{
//    int remain = Review_Max_Length-textView.text.length;
//    [(UILabel *)[self.reviewPanel viewWithTag:Remain_Word_Label] setText:[NSString stringWithFormat:@"还有%d字可输入",remain<0 ? 0:remain]];
//}
//
//- (void)textViewDidChangeSelection:(UITextView *)textView{
//
//}


@end
