//
//  JDOShareModel.h
//  JiaodongOnlineNews
//
//  Created by zhang yi on 13-6-26.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol JDOToolbarModel <NSObject>

@required
@property (nonatomic,strong) NSString *id;
@optional
@property (nonatomic,strong) NSString *title;
@property (nonatomic,strong) NSString *summary;
@property (nonatomic,strong) NSString *imageurl;
@property (nonatomic,strong) NSString *reviewService;
@property (nonatomic,strong) NSString *tinyurl;
//@property (nonatomic,strong) NSString *mpic;

@property (nonatomic,strong) NSString *department;
@property (nonatomic,strong) NSString *dept_code;
@property (nonatomic,strong) NSString *entry_date;
@property (nonatomic,strong) NSString *info_type;
@property (nonatomic,strong) NSNumber *reply;
@property (nonatomic,strong) NSString *pubtime;

@property (nonatomic,strong) NSNumber *secret;
@property (nonatomic,strong) NSString *pwd;
@property (nonatomic,strong) NSString *collectType;
@end
