//
//  sayWhatPlayerView.h
//  Say What
//
//  Created by Jesse Crocker on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "SCUI.h"

@protocol sayWhatPlayerViewDelegate <NSObject>
-(void)hidePlayer;
-(void)showPlayer;
@end

@interface sayWhatPlayerView : UIView <UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate>
@property (strong, nonatomic) IBOutlet UISlider *timeSlider;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) IBOutlet UIButton *pauseButton;
@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (strong, nonatomic) IBOutlet UIButton *forwardButton;
@property (strong, nonatomic) IBOutlet UIButton *deleteButton;
@property (strong, nonatomic) IBOutlet UIButton *playbackRateButton;
@property (strong, nonatomic) IBOutlet UILabel *endTimeLabel;
@property (strong, nonatomic) IBOutlet UILabel *startTimeLabel;
@property (strong, nonatomic) IBOutlet UIButton *actionButton;

@property (weak, nonatomic) NSObject<sayWhatPlayerViewDelegate> *closerDelegate;

-(void)setup;
-(void)updatePlayRateButton;
-(void)updatePlayButton;

- (IBAction)sliderChanged:(id)sender;
- (IBAction)rateButtonHit:(id)sender;
- (IBAction)playButtonHit:(id)sender;
- (IBAction)pauseButtonHit:(id)sender;
- (IBAction)deleteButtonHit:(id)sender;
- (IBAction)rewindButtonDown:(id)sender;
- (IBAction)rewindButtonUp:(id)sender;
- (IBAction)fastForwardButtonDown:(id)sender;
- (IBAction)fastForwardButtonUp:(id)sender;
- (IBAction)actionButtonHit:(id)sender;


- (IBAction)stopButtonHit:(id)sender;

@end
