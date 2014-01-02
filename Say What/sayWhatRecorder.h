//
//  sayWhatRecorder.h
//  Say What
//
//  Created by Jesse Crocker on 6/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "levelMeterView.h"
//#import "SoundRecorderViewController.h"

typedef enum {
    recorderModeStandby,
    recorderModeReplay,
    recorderModeRecording
} SWRecordMode;

@protocol recorderQueueDelegate <NSObject>
-(void)queueContains:(int)seconds;
-(void)setUIForCurrentRecordingMode;
@end

@interface sayWhatRecorder : NSObject <AVAudioRecorderDelegate>

@property (weak, nonatomic) levelMeterView *levelMeter;
@property (weak, nonatomic) NSObject<recorderQueueDelegate> *queueDelegate;
@property (assign) SWRecordMode currentMode;
@property (assign) BOOL instantReplayStoppedOnInteruption;
@property (assign) BOOL recordStoppedOnInteruption;

-(bool)instantReplayEnabled;
-(void)enableInstantReplay;
-(void)disableInstantReplay;

-(bool)recording;
-(void)stopRecording;
-(void)startRecordingNow;
-(void)startRecordingWithInstandReplay;

-(void)instantReplay;

-(void)instantReplayPruneFiles:(NSInteger)maxFiles;

@end
