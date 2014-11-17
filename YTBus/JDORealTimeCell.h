//
//  JDORealTimeCell.h
//  YTBus
//
//  Created by zhang yi on 14-11-10.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JDORealTimeCell : UITableViewCell

@property (nonatomic,assign) IBOutlet UIImageView *stationIcon;
@property (nonatomic,assign) IBOutlet UILabel *stationName;
@property (nonatomic,assign) IBOutlet UIImageView *arrivingBus;
@property (nonatomic,assign) IBOutlet UIImageView *arrivedBus;

@end
