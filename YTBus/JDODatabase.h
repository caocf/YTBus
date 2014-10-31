//
//  JDODatabase.h
//  YTBus
//
//  Created by zhang yi on 14-10-31.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FMDB.h"
#import "SSZipArchive.h"

#define GetLinesByStation @"select t0.STATIONNAME as STATIONNAME,t0.GEOGRAPHICALDIRECTION as DIRECTION,t1.BUSLINEID as LINEID ,t1.buslinedetail as LINEDETAILID,t3.buslinename as LINENAME,t2.buslinename as LINEDETAIL from station t0 inner join LINESTATION t1 on t0.id = t1.stationid left join BUSLINEDETAIL t2 on t1.buslinedetail = t2.id left join BUSLINE t3 on t1.buslineid = t3.id where t0.id = ? order by LINENAME"

@interface JDODatabase : NSObject

+ (BOOL) isDBExistInDocument;
+ (BOOL) saveZipFile:(NSData *)zipData;
+ (BOOL) unzipDBFile:(id<SSZipArchiveDelegate>) delegate;
+ (void) openDB:(int) which;
+ (FMDatabase *) sharedDB;

@end
