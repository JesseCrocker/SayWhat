//
//  SoundRecorderViewController.h
//  Say What
//
//  Created by Jesse Crocker on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "sayWhatPlayerView.h"
#import "sayWhatPlayer.h"
#import "sayWhatRecorder.h"
#import "levelMeterView.h"

@interface SoundRecorderViewController : UIViewController <sayWhatPlayerViewDelegate, recorderQueueDelegate, UISplitViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIButton *stopButton;
@property (strong, nonatomic) IBOutlet UISwitch *instantReplaySwitch;
@property (strong, nonatomic) IBOutlet UIButton *SayWhatButton;
@property (strong, nonatomic) IBOutlet UIButton *startRecordingBeginBufferButton;
@property (strong, nonatomic) IBOutlet UIButton *startRecording30Button;
@property (strong, nonatomic) IBOutlet UIButton *startRecordingNowButton;

@property (strong, nonatomic) IBOutlet UIImageView *recordingLightImageView;

@property (strong, nonatomic) IBOutlet UILabel *instantReplayLabel;
@property (strong, nonatomic) IBOutlet UILabel *startRecordingLabel;

@property (strong, nonatomic) IBOutlet UIView *playerViewContainer;
@property (strong, nonatomic) sayWhatPlayerView *playerView;

@property (strong, nonatomic) IBOutlet UIView *levelMeterContainerView;
@property (strong, nonatomic) levelMeterView *levelMeter;
@property (strong, nonatomic) IBOutlet UIView *helpView;
@property (strong, nonatomic) IBOutlet UIButton *closeHelpButton;

- (IBAction)stopButtonHit:(id)sender;
- (IBAction)instantReplaySwitchChanged:(id)sender;
- (IBAction)sayWhatButtonHit:(id)sender;
- (IBAction)startRecordingButtonHit:(UIButton *)sender;
- (IBAction)closeHelpButtonHit:(id)sender;

@end
