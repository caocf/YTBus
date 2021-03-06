//
//  TBCoordinateQuadTree.m
//  TBAnnotationClustering
//
//  Created by Theodore Calmes on 9/27/13.
//  Copyright (c) 2013 Theodore Calmes. All rights reserved.
//

#import "TBCoordinateQuadTree.h"
#import "TBClusterAnnotation.h"
#import "JDOStationModel.h"
#import "JDOConstants.h"

typedef struct JDOStationInfo {
    char* stationId;
    char* stationName;
} JDOStationInfo;

TBQuadTreeNodeData TBDataFromModel(JDOStationModel *station)
{
    double latitude = [station.gpsY doubleValue];
    double longitude = [station.gpsX doubleValue];

    JDOStationInfo* stationInfo = malloc(sizeof(JDOStationInfo));

    // 原来的代码中文乱码
//    NSString *stationId = [station.fid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//    stationInfo->stationId = malloc(sizeof(char) * stationId.length + 1);
//    strncpy(stationInfo->stationId, [stationId UTF8String], stationId.length + 1);
//    
//    NSString *stationName = [station.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//    stationInfo->stationName = malloc(sizeof(char) * stationName.length + 1);
//    strncpy(stationInfo->stationName, [stationName UTF8String], stationName.length + 1);
    
    const char *stationId = [[station.fid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] UTF8String];
    size_t stationIdLength = strlen(stationId) + 1;
    stationInfo->stationId = malloc(stationIdLength);
    memset(stationInfo->stationId, 0, stationIdLength);
    strncpy(stationInfo->stationId, stationId, stationIdLength);
    
    const char *stationName = [[station.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] UTF8String];
    size_t stationNameLength = strlen(stationName) + 1;
    stationInfo->stationName = malloc(stationNameLength);
    memset(stationInfo->stationName, 0, stationNameLength);
    strncpy(stationInfo->stationName, stationName, stationNameLength);

    

    return TBQuadTreeNodeDataMake(latitude, longitude, stationInfo);
}

TBBoundingBox TBBoundingBoxForMapRect(BMKMapRect mapRect)
{
    CLLocationCoordinate2D topLeft = BMKCoordinateForMapPoint(mapRect.origin);
    CLLocationCoordinate2D botRight = BMKCoordinateForMapPoint(BMKMapPointMake(BMKMapRectGetMaxX(mapRect), BMKMapRectGetMaxY(mapRect)));

    CLLocationDegrees minLat = botRight.latitude;
    CLLocationDegrees maxLat = topLeft.latitude;

    CLLocationDegrees minLon = topLeft.longitude;
    CLLocationDegrees maxLon = botRight.longitude;

    return TBBoundingBoxMake(minLat, minLon, maxLat, maxLon);
}

BMKMapRect TBMapRectForBoundingBox(TBBoundingBox boundingBox)
{
    BMKMapPoint topLeft = BMKMapPointForCoordinate(CLLocationCoordinate2DMake(boundingBox.x0, boundingBox.y0));
    BMKMapPoint botRight = BMKMapPointForCoordinate(CLLocationCoordinate2DMake(boundingBox.xf, boundingBox.yf));

    return BMKMapRectMake(topLeft.x, botRight.y, fabs(botRight.x - topLeft.x), fabs(botRight.y - topLeft.y));
}

NSInteger TBZoomScaleToZoomLevel(BMKZoomScale scale)
{
    double totalTilesAtMaxZoom = BMKMapSizeWorld.width / 256.0;
    NSInteger zoomLevelAtMaxZoom = log2(totalTilesAtMaxZoom);
    NSInteger zoomLevel = MAX(0, zoomLevelAtMaxZoom + floor(log2f(scale) + 0.5));

    return zoomLevel;
}

float TBCellSizeForZoomScale(BMKZoomScale zoomScale)
{
    NSInteger zoomLevel = TBZoomScaleToZoomLevel(zoomScale);
    switch (zoomLevel) {
        case 14:
            return 72;
        case 15:
            return 54;
        case 16:
            return 36;
        case 17:
            return 18;
        case 18:
        case 19:
            return 12;
        default:
            return 88;
    }
}

@implementation TBCoordinateQuadTree

- (void)buildTree:(NSArray *)stations
{
    @autoreleasepool {
        TBQuadTreeNodeData *dataArray = malloc(sizeof(TBQuadTreeNodeData) * stations.count);
        for (NSInteger i = 0; i < stations.count; i++) {
            dataArray[i] = TBDataFromModel(stations[i]);
        }
        TBBoundingBox world = TBBoundingBoxMake(YT_MIN_Y, YT_MIN_X, YT_MAX_Y, YT_MAX_X);
        _root = TBQuadTreeBuildWithData(dataArray, stations.count, world, 4);
    }
}

- (NSArray *)clusteredAnnotationsWithinMapView:(BMKMapView *)mapView{
    double TBCellSize;
    if (mapView.zoomLevel < 13.0f) {
        TBCellSize = 0.06f;
    }else if(mapView.zoomLevel < 13.5f){
        TBCellSize = 0.04f;
    }else if(mapView.zoomLevel < 14.0f){
        TBCellSize = 0.025f;
    }else if(mapView.zoomLevel < 14.5f){
        TBCellSize = 0.016f;
    }else if(mapView.zoomLevel < 15.0f){
        TBCellSize = 0.012f;
    }else if(mapView.zoomLevel < 15.5f){
        TBCellSize = 0.008f;
    }else if(mapView.zoomLevel < 16.0f){
        TBCellSize = 0.006f;
    }else if(mapView.zoomLevel < 16.5f){
        TBCellSize = 0.004f;
    }else if(mapView.zoomLevel < 17.0f){
        TBCellSize = 0.003f;
    }else if(mapView.zoomLevel < 18.0f){
        TBCellSize = 0.002f;
    }else if(mapView.zoomLevel < 18.5f){
        TBCellSize = 0.001f;
    }else{
        TBCellSize = 0.0005f;
    }
//    NSLog(@"level:%g,size:%g",mapView.zoomLevel,TBCellSize);
    
    double leftX = mapView.region.center.longitude - mapView.region.span.longitudeDelta/2;
    double rightX = mapView.region.center.longitude + mapView.region.span.longitudeDelta/2;
    double bottomY = mapView.region.center.latitude - mapView.region.span.latitudeDelta/2;
    double topY = mapView.region.center.latitude + mapView.region.span.latitudeDelta/2;
    
    double minX = YT_MIN_X, maxX = rightX, minY = bottomY, maxY = YT_MAX_Y;
    while (minX < leftX) {
        minX += TBCellSize;
    }
    minX -= TBCellSize;
    while (maxY > topY) {
        maxY -= TBCellSize;
    }
    maxY += TBCellSize;
    
    NSMutableArray *clusteredAnnotations = [[NSMutableArray alloc] init];
    for (double x = minX; x <= maxX; x+=TBCellSize) {
        for (double y = maxY; y >= minY; y-=TBCellSize) {
            
            __block double totalX = 0;
            __block double totalY = 0;
            __block int count = 0;
            
            NSMutableArray *stations = [[NSMutableArray alloc] initWithCapacity:6];
            TBQuadTreeGatherDataInRange(self.root, TBBoundingBoxMake(y-TBCellSize, x, y, x+TBCellSize), ^(TBQuadTreeNodeData data) {
                totalX += data.x;
                totalY += data.y;
                count++;
                
                if (count<=4) { //4个站点以下的集群，点击后以列表的形式显示
                    JDOStationInfo stationInfo = *(JDOStationInfo *)data.data;
                    JDOStationModel *sModel = [JDOStationModel new];
                    sModel.fid = [NSString stringWithUTF8String:stationInfo.stationId];
                    sModel.name = [NSString stringWithUTF8String:stationInfo.stationName];
                    sModel.gpsX = [NSNumber numberWithDouble:data.y];
                    sModel.gpsY = [NSNumber numberWithDouble:data.x];
                    [stations addObject:sModel];
                }else{
                    [stations removeAllObjects];
                }
            });
            
            if(count>0){
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(totalX / count, totalY / count);
                TBClusterAnnotation *annotation = [[TBClusterAnnotation alloc] initWithCoordinate:coordinate count:count];
                annotation.stations = stations;
                [clusteredAnnotations addObject:annotation];
            }
            
        }
    }
    
    return [NSArray arrayWithArray:clusteredAnnotations];
}

// 地图平移时，瓦片切分会变动。。不知道是什么原因，把直角坐标替换为经纬度坐标划分区域不会有该问题。。方法见上
- (NSArray *)clusteredAnnotationsWithinMapRect:(BMKMapRect)rect withZoomScale:(double)zoomScale
{
    double TBCellSize = TBCellSizeForZoomScale(zoomScale);
    double scaleFactor = zoomScale / TBCellSize;

    NSInteger minX = floor(BMKMapRectGetMinX(rect) * scaleFactor);
    NSInteger maxX = floor(BMKMapRectGetMaxX(rect) * scaleFactor);
    NSInteger minY = floor(BMKMapRectGetMinY(rect) * scaleFactor);
    NSInteger maxY = floor(BMKMapRectGetMaxY(rect) * scaleFactor);

    NSMutableArray *clusteredAnnotations = [[NSMutableArray alloc] init];
    for (NSInteger x = minX; x <= maxX; x++) {
        for (NSInteger y = minY; y <= maxY; y++) {
            BMKMapRect mapRect = BMKMapRectMake(x / scaleFactor, y / scaleFactor, 1.0 / scaleFactor, 1.0 / scaleFactor);
            
            __block double totalX = 0;
            __block double totalY = 0;
            __block int count = 0;

            NSMutableArray *stations = [[NSMutableArray alloc] initWithCapacity:6];
            TBQuadTreeGatherDataInRange(self.root, TBBoundingBoxForMapRect(mapRect), ^(TBQuadTreeNodeData data) {
                totalX += data.x;
                totalY += data.y;
                count++;

                if (count<=4) { //4个站点以下的集群，点击后以列表的形式显示
                    JDOStationInfo stationInfo = *(JDOStationInfo *)data.data;
                    JDOStationModel *sModel = [JDOStationModel new];
                    sModel.fid = [NSString stringWithUTF8String:stationInfo.stationId];
                    sModel.name = [NSString stringWithUTF8String:stationInfo.stationName];
                    sModel.gpsX = [NSNumber numberWithDouble:data.y];
                    sModel.gpsY = [NSNumber numberWithDouble:data.x];
                    [stations addObject:sModel];
                }else{
                    [stations removeAllObjects];
                }
            });

            if(count>0){
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(totalX / count, totalY / count);
                TBClusterAnnotation *annotation = [[TBClusterAnnotation alloc] initWithCoordinate:coordinate count:count];
                annotation.stations = stations;
                [clusteredAnnotations addObject:annotation];
            }
            
        }
    }

    return [NSArray arrayWithArray:clusteredAnnotations];
}

@end
