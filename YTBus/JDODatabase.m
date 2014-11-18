//
//  JDODatabase.m
//  YTBus
//
//  Created by zhang yi on 14-10-31.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import "JDODatabase.h"

#define docsPath NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES)[0]
#define dbPath  [docsPath stringByAppendingPathComponent:@"bus.db/"]
#define zipPath [docsPath stringByAppendingPathComponent:@"bus.zip"]
#define dbPathAtBundle [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"bus.db"]

static FMDatabase *DB;
static int currentDB;

@implementation JDODatabase

+ (BOOL) isDBExistInDocument{
    NSFileManager *fm = [NSFileManager defaultManager];
    return [fm fileExistsAtPath:dbPath];
}

+ (BOOL) saveZipFile:(NSData *)zipData{
    NSError *error;
    [zipData writeToFile:zipPath options:NSDataWritingAtomic error:&error];
    if(error){
        NSLog(@"保存数据库zip文件出错:%@",error);
        return false;
    }
    return true;
}

+ (BOOL) unzipDBFile:(id<SSZipArchiveDelegate>) delegate{
    NSError *error;
    BOOL result = [SSZipArchive unzipFileAtPath:zipPath toDestination:docsPath overwrite:YES password:nil error:&error delegate:delegate];
    if (!result) {
        NSLog(@"解压数据库zip文件出错:%@",error);
    }
    return result;

}

+ (void) openDB:(int) which{   //   which:1,2
    if (DB) {
        if (which==currentDB) {
            return;
        }
    }
    currentDB = which;
    NSString *path = which==1?dbPathAtBundle:dbPath;
    FMDatabase *db = [FMDatabase databaseWithPath:path];
    if (db) {
        BOOL success = [db open];
        if ( success) {
            if (DB) {
                [DB close];
            }
            DB = db;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"db_finished" object:nil];
        }
    }
}

+ (FMDatabase *) sharedDB{
    return DB;
}

@end
