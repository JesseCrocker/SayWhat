//
//  levelMeterView.m
//  Say What
//
//  Created by Jesse Crocker on 7/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "levelMeterView.h"

@implementation levelMeterView
@synthesize peakPowerLabel;
@synthesize averagePowerLabel;
@synthesize levelMeter;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}

-(void)setup{
    //levelMeter.borderColor = [UIColor whiteColor];
    levelMeter.backgroundColor = [UIColor clearColor];
    levelMeter.vertical = YES;
    levelMeter.numLights = 16;
}

-(void)updateMeterAveragePower:(CGFloat)averagePower peakPower:(CGFloat)peakPower{
    if(averagePower < -159.9)
        levelMeter.level = 0;
    else
        levelMeter.level = pow (10, (0.05 * averagePower));
    if(peakPower < -159.9)
        levelMeter.peakLevel = 0;
    else
        levelMeter.peakLevel = pow (10, (0.05 * peakPower));
    [levelMeter setNeedsDisplay];
}

@end
