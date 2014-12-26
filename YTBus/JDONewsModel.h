//
//  JDONewsModel.h
//  JiaodongOnlineNews
//
//  Created by zhang yi on 13-5-31.
//  Copyright (c) 2013年 胶东在线. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JDONewsModel : NSObject <NSCoding>
@property (nonatomic,strong) NSString *atype;
@property (nonatomic,strong) NSString *clicknum;
@property (nonatomic,strong) NSString *id;
@property (nonatomic,strong) NSString *mpic;
@property (nonatomic,strong) NSString *pubtime;
@property (nonatomic,strong) NSString *summary;
@property (nonatomic,strong) NSString *title;
@property (nonatomic,strong) NSString *spic;
@property (nonatomic,strong) NSString *modifytime;
@property (nonatomic,strong) NSString *tinyurl;

@property (nonatomic,strong) NSString *imageurl;
@property (nonatomic,strong) NSString *reviewService;

@property (nonatomic,strong) NSString *contentType;

@property (nonatomic,strong) NSArray *g_pics;
//@property (nonatomic,strong) NSString *commentCount;

- (JDONewsModel *)initWithDict:(NSDictionary *)dict;
@end
