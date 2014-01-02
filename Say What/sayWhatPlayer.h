//
//  audioPlayer.h
//  Say What
//
//  Created by Jesse Crocker on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "Recording.h"
#import "Recording+addons.h"
#import "sayWhatPlayerView.h"
#import "levelMeterView.h"

@interface sayWhatPlayer : NSObject <AVAudioPlayerDelegate>
@property (nonatomic, strong) Recording *recording;
@property (nonatomic, strong) NSNumber *playbackRate;

@property (weak, nonatomic) sayWhatPlayerView *playerView;
@property (weak, nonatomic) levelMeterView *levelMeter;

@property (assign) BOOL playbackWasInterupted;

-(void)setRecordingByID:(NSManagedObjectID *)recordingID;

-(void)play;
-(void)pause;
-(void)stop;
-(void)setPlayPoint:(CGFloat)playPoint;
-(CGFloat)playPoint;
-(bool)isPlaying;

@end
