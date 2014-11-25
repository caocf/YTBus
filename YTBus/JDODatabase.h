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

// 某个站点通过的所有线路，在“我的附近”中使用
#define GetLinesByStation @"select t0.STATIONNAME as STATIONNAME,t0.GEOGRAPHICALDIRECTION as DIRECTION,t1.BUSLINEID as LINEID ,t1.buslinedetail as LINEDETAILID,t3.buslinename as LINENAME,t2.buslinename as LINEDETAIL,t2.DIRECTION as LINEDIRECTION,t3.runtime as RUNTIME from station t0 inner join LINESTATION t1 on t0.id = t1.stationid inner join BUSLINEDETAIL t2 on t1.buslinedetail = t2.id inner join BUSLINE t3 on t1.buslineid = t3.id where t0.id = ? order by (case when cast(t3.buslinename as int)=0 then 999 else cast(t3.buslinename as int) end)"

// 某条线路的所有站点(单向)，在“线路实时”的地图界面中使用
#define GetStationsByLineDetail @"select t0.buslinename as LINEDETAIL,t1.BUSLINEID as LINEID ,t1.buslinedetail as LINEDETAILID,t2.ID as STATIONID, t2.STATIONNAME as STATIONNAME,t2.GEOGRAPHICALDIRECTION as DIRECTION,t2.GPSX2 as GPSX,t2.GPSY2 as GPSY from BUSLINEDETAIL t0 inner join LINESTATION t1 on t0.id = t1.buslinedetail inner join STATION t2 on t1.stationid = t2.id where t0.id = ? order by t1.SEQUENCE"

// 某条线路名称及其起点站和终点站，在“线路查询”的收藏中使用
#define GetLineById @"select ID,BUSLINENAME,(select stationname from STATION where id=t0.STATIONA) as STATIONANAME,(select stationname from STATION where id=t0.STATIONB) as STATIONBNAME from BusLine t0 where ID in (?)"

// 所有线路名称及其起点站和终点站，在“线路查询”的所有线路中使用
#define GetAllLines @"select ID,BUSLINENAME,(select stationname from STATION where id=t0.STATIONA) as STATIONANAME,(select stationname from STATION where id=t0.STATIONB) as STATIONBNAME from BusLine t0 order by ID"

// 所有站点名称，及站点通过的线路数[******暂时不用******]
#define GetAllStations @"select t0.ID, STATIONNAME, sum(1) as NUM from STATION t0 inner join LINESTATION t1 on t0.ID = t1.STATIONID inner join BusLineDetail t2 on t1.BUSLINEDETAIL = t2.ID where t0.GPSX2<>0 and t0.GPSY2<>0 group by t0.ID order by STATIONNAME"

// 所有站点名称，及站点通过的线路名称
#define GetAllStationsWithLine @"select t0.ID as ID, (CASE WHEN SUBSTR(STATIONNAME,-1,1)='2' and SUBSTR(STATIONNAME,-2,1) not in ('1','2','3','4','5','6','7','8','9','0') THEN SUBSTR(STATIONNAME,1,LENGTH(STATIONNAME)-1) ELSE STATIONNAME END) as STATIONNAME,GEOGRAPHICALDIRECTION,t3.BUSLINENAME as BUSLINENAME,t3.ID as BUSLINEID from STATION t0 inner join LINESTATION t1 on t0.ID = t1.STATIONID inner join BusLineDetail t2 on t1.BUSLINEDETAIL = t2.ID inner join BusLine t3 on t2.BUSLINEID = t3.ID where t0.GPSX2<>0 and t0.GPSY2<>0 order by STATIONNAME,t0.ID,t3.ID"

#define GetConverseStation @"select t2.* from BusLineDetail t0 inner join LINESTATION t1 on t0.ID = t1.BUSLINEDETAIL inner join STATION t2 on t1.STATIONID = t2.ID where t2.STATIONNAME = ? and t0.ID = ?"

@interface JDODatabase : NSObject

+ (BOOL) isDBExistInDocument;
+ (BOOL) saveZipFile:(NSData *)zipData;
+ (BOOL) unzipDBFile:(id<SSZipArchiveDelegate>) delegate;
+ (void) openDB:(int) which;
+ (FMDatabase *) sharedDB;

@end
