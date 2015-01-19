//
//  TBCoordinateQuadTree.h
//  TBAnnotationClustering
//
//  Created by Theodore Calmes on 9/27/13.
//  Copyright (c) 2013 Theodore Calmes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TBQuadTree.h"
#import "BMapKit.h"

@interface TBCoordinateQuadTree : NSObject

@property (assign, nonatomic) TBQuadTreeNode* root;
//@property (strong, nonatomic) BMKMapView *mapView;

- (void)buildTree:(NSArray *)stations;
- (NSArray *)clusteredAnnotationsWithinMapRect:(BMKMapRect)rect withZoomScale:(double)zoomScale;
- (NSArray *)clusteredAnnotationsWithinMapView:(BMKMapView *)mapView;

@end
