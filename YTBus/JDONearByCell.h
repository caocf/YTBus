//
//  JDONearByCell.h
//  YTBus
//
//  Created by zhang yi on 14-10-30.
//  Copyright (c) 2014年 胶东在线. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JDOBusLine.h"

@interface JDONearByCell : UITableViewCell

@property (nonatomic,strong) JDOBusLine *busLine;

@property (nonatomic,assign) UITableView *tableView;
@property (nonatomic,strong) NSIndexPath *indexPath;

@property (nonatomic,assign) IBOutlet UILabel *lineNameLabel;
@property (nonatomic,assign) IBOutlet UILabel *lineDetailLabel;
@property (nonatomic,assign) IBOutlet UILabel *stationLabel;
@property (nonatomic,assign) IBOutlet UIButton *switchDirection;

- (IBAction) onSwitchClicked:(UIButton *)btn;

@end
