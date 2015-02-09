//
//  JDOReportController.m
//  YTBus
//
//  Created by zhang yi on 15-2-9.
//  Copyright (c) 2015年 胶东在线. All rights reserved.
//

#import "JDOReportController.h"
#import "ActionSheetCustomPicker.h"
#import "ActionSheetStringPicker.h"
#import "SSTextView.h"

@interface InsetsTextField : UITextField

@end

@implementation  InsetsTextField
// 控制placeHolder的位置，左右缩 5
-  (CGRect)textRectForBounds:(CGRect)bounds {
    return  CGRectInset( bounds , 5 , 5 );
}

// 控制文本的位置，左右缩 5
-  (CGRect)editingRectForBounds:(CGRect)bounds {
    return  CGRectInset( bounds , 5 , 5 );
}
@end

@interface JDOReportController () <ActionSheetCustomPickerDelegate,UITextFieldDelegate,UITextViewDelegate>

@end

@implementation JDOReportController

- (id)init{
    self = [super init];
    if (self){
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonClickHandler:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"提交" style:UIBarButtonItemStylePlain target:self action:@selector(publishButtonClickHandler:)];
        self.title = @"我要纠错";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *lin1BG = [UIImageView alloc] initWithFrame:CGRectMake(<#CGFloat x#>, <#CGFloat y#>, <#CGFloat width#>, <#CGFloat height#>)

}

- (void)cancelButtonClickHandler:(id)sender{
    [_textView resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)publishButtonClickHandler:(id)sender{
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
