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
#define GetLinesByStation @"select t0.STATIONNAME as STATIONNAME,t0.GEOGRAPHICALDIRECTION as DIRECTION,t1.BUSLINEID as LINEID ,t1.buslinedetail as LINEDETAILID,t3.buslinename as LINENAME,t2.buslinename as LINEDETAIL,t2.DIRECTION as LINEDIRECTION,t3.runtime as RUNTIME, t3.ZHIXIAN as ZHIXIAN from station t0 inner join LINESTATION t1 on t0.id = t1.stationid inner join BUSLINEDETAIL t2 on t1.buslinedetail = t2.id inner join BUSLINE t3 on t1.buslineid = t3.id where t0.id = ? and t3.appshow = 1 order by (case when cast(t3.buslinename as int)=0 then 999 else cast(t3.buslinename as int) end)"

// 某条线路的所有站点(单向)，在“线路实时”的地图界面中使用
#define GetStationsByLineDetail @"select t0.buslinename as LINEDETAIL,t1.BUSLINEID as LINEID ,t1.buslinedetail as LINEDETAILID,t2.ID as STATIONID, t2.STATIONNAME as STATIONNAME,t2.GEOGRAPHICALDIRECTION as DIRECTION,t2.MAPX as GPSX,t2.MAPY as GPSY from BUSLINEDETAIL t0 inner join LINESTATION t1 on t0.id = t1.buslinedetail inner join STATION t2 on t1.stationid = t2.id where t0.id = ? order by t1.SEQUENCE"

// 某条线路名称及其起点站和终点站，在“线路查询”的收藏中使用
//#define GetLineById @"select ID,BUSLINENAME,(select stationname from STATION where id=t0.STATIONA) as STATIONANAME,(select stationname from STATION where id=t0.STATIONB) as STATIONBNAME from BusLine t0 where ID in (?)"
// 收藏的基本单元从线路改为线路详情
#define GetLineById @"select t0.ID as LINEID, t1.ID as DETAILID, t0.BUSLINENAME as BUSLINENAME, t0.ZHIXIAN as ZHIXIAN,  t1.BUSLINENAME as LINEDETAILNAME, t1.DIRECTION as DIRECTION from BusLine t0 inner join BusLineDetail t1 on t0.ID = t1.BUSLINEID where t1.ID in (?)"

// 所有线路名称及其起点站和终点站，在“线路查询”的所有线路中使用
#define GetAllLines @"select ID,BUSLINENAME, ZHIXIAN, (select stationname from STATION where id=t0.STATIONA) as STATIONANAME,(select stationname from STATION where id=t0.STATIONB) as STATIONBNAME from BusLine t0 where t0.appshow = 1 order by ID"

// 所有站点名称，及站点通过的线路数[******暂时不用******]
#define GetAllStations @"select t0.ID, STATIONNAME, sum(1) as NUM from STATION t0 inner join LINESTATION t1 on t0.ID = t1.STATIONID inner join BusLineDetail t2 on t1.BUSLINEDETAIL = t2.ID where t0.MAPX<>0 and t0.MAPY<>0 group by t0.ID order by STATIONNAME"

// 所有站点名称，及站点通过的线路名称
#define GetAllStationsWithLine @"select t0.ID as STATIONID, (CASE WHEN SUBSTR(STATIONNAME,-1,1)='2' and SUBSTR(STATIONNAME,-2,1) not in ('1','2','3','4','5','6','7','8','9','0') THEN SUBSTR(STATIONNAME,1,LENGTH(STATIONNAME)-1) ELSE STATIONNAME END) as STATIONNAME,t3.BUSLINENAME as BUSLINENAME,t3.ID as BUSLINEID from STATION t0 inner join LINESTATION t1 on t0.ID = t1.STATIONID inner join BusLineDetail t2 on t1.BUSLINEDETAIL = t2.ID inner join BusLine t3 on t2.BUSLINEID = t3.ID where t0.MAPX<>0 and t0.MAPY<>0 and t3.appshow = 1 order by STATIONNAME,t0.ID,(case when cast(t3.buslinename as int)=0 then 999 else cast(t3.buslinename as int) end)"

// 根据站点名称，查询是否有同名的对向站点
#define GetConverseStation @"select t2.ID as STATIONID,t2.STATIONNAME as STATIONNAME,t2.GEOGRAPHICALDIRECTION as DIRECTION,t2.MAPX as GPSX,t2.MAPY as GPSY from BusLineDetail t0 inner join LINESTATION t1 on t0.ID = t1.BUSLINEDETAIL inner join STATION t2 on t1.STATIONID = t2.ID where t2.STATIONNAME = ? and t0.ID = ?"

// 根据站点名称，查询所有同名站点及通过的所有线路
#define GetStationsWithLinesByName @"select t0.ID as STATIONID, (CASE WHEN SUBSTR(STATIONNAME,-1,1)='2' and SUBSTR(STATIONNAME,-2,1) not in ('1','2','3','4','5','6','7','8','9','0') THEN SUBSTR(STATIONNAME,1,LENGTH(STATIONNAME)-1) ELSE STATIONNAME END) as STATIONNAME,t0.MAPX as GPSX, t0.MAPY as GPSY, t3.ID as BUSLINEID, t3.BUSLINENAME as BUSLINENAME,t2.ID as LINEDETAILID, t2.BUSLINENAME as BUSLINEDETAIL, t2.DIRECTION as DIRECTION from STATION t0 inner join LINESTATION t1 on t0.ID = t1.STATIONID inner join BusLineDetail t2 on t1.BUSLINEDETAIL = t2.ID inner join BusLine t3 on t2.BUSLINEID = t3.ID where STATIONNAME=? and t0.MAPX<>0 and t0.MAPY<>0 and t3.appshow = 1 order by t0.ID, (case when cast(t3.buslinename as int)=0 then 999 else cast(t3.buslinename as int) end)"

// 查询所有的站点，用来填充四叉树
#define GetAllStationsInfo @"SELECT distinct t0.ID AS STATIONID,t0.stationname as STATIONNAME,t0.GEOGRAPHICALDIRECTION as DIRECTION,t0.MAPX as GPSX,t0.MAPY as GPSY FROM STATION t0 INNER JOIN LINESTATION t1 ON t0.ID = t1.STATIONID INNER JOIN BusLineDetail t2 ON t1.BUSLINEDETAIL = t2.ID INNER JOIN BusLine t3 ON t2.BUSLINEID = t3.ID WHERE t0.MAPX <> 0 AND t0.MAPY <> 0 and t3.appshow = 1"

// 附近的站点，跟上面的只有where条件不同
#define GetNearbyStations @"SELECT distinct t0.ID AS ID,t0.stationname as STATIONNAME,t0.GEOGRAPHICALDIRECTION as DIRECTION,t0.MAPX as GPSX,t0.MAPY as GPSY FROM STATION t0 INNER JOIN LINESTATION t1 ON t0.ID = t1.STATIONID INNER JOIN BusLineDetail t2 ON t1.BUSLINEDETAIL = t2.ID INNER JOIN BusLine t3 ON t2.BUSLINEID = t3.ID WHERE t0.MAPX>? and t0.MAPX<? and t0.MAPY>? and t0.MAPY<? and t3.appshow = 1"


@interface JDODatabase : NSObject

+ (BOOL) isDBExistInDocument;
+ (BOOL) saveZipFile:(NSData *)zipData;
+ (BOOL) unzipDBFile:(id<SSZipArchiveDelegate>) delegate;
+ (void) openDB:(int) which;
+ (void) openDB:(int) which force:(BOOL) force;
+ (FMDatabase *) sharedDB;

@end
