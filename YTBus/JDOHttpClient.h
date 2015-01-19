//
//  JDOHttpClient.h
//  YTBus
//
//  Created by zhang yi on 14-10-31.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@interface JDOHttpClient : AFHTTPClient

+ (JDOHttpClient *)sharedDFEClient;
+ (JDOHttpClient *)sharedJDOClient;
+ (JDOHttpClient *)sharedBUSClient;

@end
