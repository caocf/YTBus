//
//  UIBubbleTableViewCell.m
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#import <QuartzCore/QuartzCore.h>
#import "UIBubbleTableViewCell.h"
#import "NSBubbleData.h"

#define Avatar_Size 32

@interface UIBubbleTableViewCell ()

@property (nonatomic, retain) UIView *customView;
@property (nonatomic, retain) UIImageView *bubbleImage;
@property (nonatomic, retain) UIImageView *avatarImage;
@property (nonatomic, retain) UIButton *stateBtn;
@property (nonatomic,strong) UIActivityIndicatorView *activityIndicator;

- (void) setupInternalData;

@end

@implementation UIBubbleTableViewCell

@synthesize data = _data;
@synthesize customView = _customView;
@synthesize bubbleImage = _bubbleImage;
@synthesize showAvatar = _showAvatar;
@synthesize avatarImage = _avatarImage;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.bubbleImage = [[UIImageView alloc] init];
        [self.contentView addSubview:self.bubbleImage];
        
        self.avatarImage = [[UIImageView alloc] init];
        [self.contentView addSubview:self.avatarImage];
        
        _stateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_stateBtn addTarget:self action:@selector(resend:) forControlEvents:UIControlEventTouchUpInside];
        [_stateBtn setImage:[UIImage imageNamed:@"发送失败"] forState:UIControlStateNormal];
        _stateBtn.hidden = true;
        [self.contentView addSubview:_stateBtn];
        
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.activityIndicator.hidden = true;
        [self.contentView addSubview:self.activityIndicator];
    }
    return self;
}

- (void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    [self setupInternalData];
}

- (void) setupInternalData{
    
    NSBubbleType type = self.data.type;
    
    CGFloat width = self.data.view.frame.size.width;
    CGFloat height = self.data.view.frame.size.height;

    CGFloat x = (type == BubbleTypeSomeoneElse) ? 0 : self.frame.size.width - width - self.data.insets.left - self.data.insets.right;
    CGFloat y = 0;
    
    
    self.avatarImage.image = (self.data.avatar ? self.data.avatar : [UIImage imageNamed:@"missingAvatar.png"]);
    CGFloat avatarX = (type == BubbleTypeSomeoneElse) ? 8 : self.frame.size.width - (Avatar_Size+8);
    CGFloat avatarY = self.frame.size.height - Avatar_Size;
    
    self.avatarImage.frame = CGRectMake(avatarX, avatarY, Avatar_Size, Avatar_Size);
    CGFloat delta = self.frame.size.height - (self.data.insets.top + self.data.insets.bottom + height);
    if (delta > 0) y = delta;
    
    [self.customView removeFromSuperview];
    self.customView = self.data.view;
    [self.contentView addSubview:self.customView];
    
    if (type == BubbleTypeSomeoneElse) {
        x += Avatar_Size+8+2;
        [(UILabel *)self.customView setTextColor:[UIColor whiteColor]];
        self.bubbleImage.image = [[UIImage imageNamed:@"someoneBubble"] stretchableImageWithLeftCapWidth:21 topCapHeight:9];
    }
    if (type == BubbleTypeMine){
        x -= Avatar_Size+8+2;
        [(UILabel *)self.customView setTextColor:[UIColor blackColor]];
        self.bubbleImage.image = [[UIImage imageNamed:@"myBubble"] stretchableImageWithLeftCapWidth:15 topCapHeight:9];
    }

    self.customView.frame = CGRectMake(x + self.data.insets.left, y + self.data.insets.top, width, height);
    self.bubbleImage.frame = CGRectMake(x, y, width + self.data.insets.left + self.data.insets.right, height + self.data.insets.top + self.data.insets.bottom);
    
    
    // 增加内容
    self.contentView.backgroundColor = [UIColor clearColor];
    self.backgroundColor = [UIColor clearColor];
    
    // TODO 区分状态
    if (self.data.type == BubbleTypeMine) { // 只有用户内容才区分发送状态
        int state = self.data.status;
        if (state == 0) {   // 发送成功
            _stateBtn.hidden = true;
            _activityIndicator.hidden = true;
            [self.activityIndicator stopAnimating];
        }else if(state == 1){   // 发送失败
            _stateBtn.frame = CGRectMake(x-25, self.data.view.center.y-10, 20, 20);
            _stateBtn.hidden = false;
            _activityIndicator.hidden = true;
            [self.activityIndicator stopAnimating];
        }else if(state == 2){   // 正在发送
            _activityIndicator.frame = CGRectMake(x-30, self.data.view.center.y-12, 25, 25);
            _stateBtn.hidden = true;
            _activityIndicator.hidden = false;
            [self.activityIndicator startAnimating];
        }
    }else{
        _stateBtn.hidden = true;
        _activityIndicator.hidden = true;
        [self.activityIndicator stopAnimating];
    }
}

- (void) resend:(UIButton *)btn {
    [self.tableView.bubbleDataSource resendMsg:self.data.content];
}

@end
