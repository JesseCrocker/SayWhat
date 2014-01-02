//
//  levelMeterView.h
//  Say What
//
//  Created by Jesse Crocker on 7/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LevelMeter.h"

@interface levelMeterView : UIView
@property (strong, nonatomic) IBOutlet UILabel *peakPowerLabel;
@property (strong, nonatomic) IBOutlet UILabel *averagePowerLabel;
@property (strong, nonatomic) IBOutlet LevelMeter *levelMeter;

-(void)setup;
-(void)updateMeterAveragePower:(CGFloat)averagePower peakPower:(CGFloat)peakPower;

@end
