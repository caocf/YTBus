//
//  JDONewsDetailModel.h
//  JiaodongOnlineNews
//
//  Created by zhang yi on 13-6-4.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGTemplateEngine.h"

@interface JDONewsDetailModel : NSObject <NSCoding, MGTemplateEngineDelegate>

@property (nonatomic,copy) NSString *id;
@property (nonatomic,copy) NSString *title;
@property (nonatomic,copy) NSString *subtitle;
@property (nonatomic,copy) NSString *summary;
@property (nonatomic,copy) NSString *source;
@property (nonatomic,copy) NSString *content;
@property (nonatomic,copy) NSString *author;
@property (nonatomic,copy) NSString *commentCount;//跟帖数
@property (nonatomic,copy) NSString *mpic;
@property (nonatomic,copy) NSString *channelid;//频道
@property (nonatomic,copy) NSString *murl;    //图片url
@property (nonatomic,copy) NSString *addtime;//发布时间
@property (nonatomic,copy) NSString *clicknum;//点击量
@property (nonatomic,copy) NSArray *relates;
@property (nonatomic,copy) NSString *tinyurl;
@property (nonatomic,copy) NSArray *advs;

+ (MGTemplateEngine *) sharedTemplateEngine;
+ (NSString *) mergeToHTMLTemplateFromDictionary:(NSDictionary *)dictionary;
//- (NSString *) mergeToHTMLTemplate;

@end
