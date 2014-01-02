//
//  SoundRecorderViewController.m
//  Say What
//
//  Created by Jesse Crocker on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SoundRecorderViewController.h"
#import "AppDelegate.h"

@interface SoundRecorderViewController (){
}

@end

@implementation SoundRecorderViewController
@synthesize stopButton;
@synthesize instantReplaySwitch;
@synthesize SayWhatButton;
@synthesize startRecordingBeginBufferButton;
@synthesize startRecording30Button;
@synthesize startRecordingNowButton;
@synthesize recordingLightImageView;
@synthesize instantReplayLabel;
@synthesize startRecordingLabel;

@synthesize playerViewContainer;
@synthesize playerView;

@synthesize levelMeterContainerView;
@synthesize levelMeter;
@synthesize helpView;
@synthesize closeHelpButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupUI];
    [self setupPlayerView];
    [self setupLevelMeter];
    [self queueContains:0];
    
    UIViewController *root = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).window.rootViewController;
    if([root isKindOfClass:[UISplitViewController class]]){
        UISplitViewController *split = (UISplitViewController *)root;
        split.delegate = self;
        if([split respondsToSelector:@selector(setPresentsWithGesture:)])
            split.presentsWithGesture = YES;
    }
    
    if([[NSUserDefaults standardUserDefaults] valueForKey:@"launchScreenShown"] == nil){
        [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"launchScreenShown"];
        self.helpView.hidden = NO;
        self.helpView.layer.cornerRadius = 10.0;
    }
}

- (void)viewDidUnload
{
    [self setStopButton:nil];
    [self setInstantReplaySwitch:nil];
    [self setSayWhatButton:nil];
    [self setInstantReplayLabel:nil];
    [self setStartRecordingLabel:nil];
    [self setPlayerView:nil];
    [self setPlayerViewContainer:nil];
    [self setStartRecordingBeginBufferButton:nil];
    [self setStartRecording30Button:nil];
    [self setStartRecordingNowButton:nil];
    [self setLevelMeterContainerView:nil];
    [self setRecordingLightImageView:nil];
    [self setHelpView:nil];
    [self setCloseHelpButton:nil];
    [super viewDidUnload];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [instantReplaySwitch setOn:self.myRecorder.instantReplayEnabled animated:YES];
    ((AppDelegate *)[[UIApplication sharedApplication] delegate]).sharedPlayer.playerView = self.playerView;
    ((AppDelegate *)[[UIApplication sharedApplication] delegate]).sharedPlayer.levelMeter = self.levelMeter;
    ((AppDelegate *)[[UIApplication sharedApplication] delegate]).sharedRecorder.levelMeter = self.levelMeter;
    ((AppDelegate *)[[UIApplication sharedApplication] delegate]).sharedRecorder.queueDelegate = self;
    [self setUIForCurrentRecordingMode];
}

-(void)viewWillDisappear:(BOOL)animated{
    ((AppDelegate *)[[UIApplication sharedApplication] delegate]).sharedPlayer.playerView = nil;
    ((AppDelegate *)[[UIApplication sharedApplication] delegate]).sharedPlayer.levelMeter = nil;
    ((AppDelegate *)[[UIApplication sharedApplication] delegate]).sharedRecorder.levelMeter = nil;
    ((AppDelegate *)[[UIApplication sharedApplication] delegate]).sharedRecorder.queueDelegate = nil;
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    } else {
        return YES;
    }
}

#pragma mark - 
-(void)setupPlayerView{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        NSArray *subviewArray = [[NSBundle mainBundle] loadNibNamed:@"sayWhatPlayerView_iPhone" owner:self options:nil];
        self.playerView = (sayWhatPlayerView *)[subviewArray objectAtIndex:0];
    }else{
        NSArray *subviewArray = [[NSBundle mainBundle] loadNibNamed:@"sayWhatPlayerView_iPad" owner:self options:nil];
        self.playerView = (sayWhatPlayerView *)[subviewArray objectAtIndex:0];
    }
    self.playerView.closerDelegate = self;
    [self.playerView setup];
    [self.playerViewContainer addSubview:self.playerView];
}

-(void)setupLevelMeter{
    NSArray *subviewArray = [[NSBundle mainBundle] loadNibNamed:@"levelMeterView" owner:self options:nil];
    self.levelMeter = (levelMeterView *)[subviewArray objectAtIndex:0];
    [self.levelMeterContainerView addSubview:self.levelMeter];
    [self.levelMeter setup];
}

-(void)setupUI{
    UIFont *labelFont = [UIFont fontWithName:@"Copperplate" size:15];
    UIColor *labelColor = [UIColor whiteColor];
    
    self.startRecordingLabel.layer.cornerRadius = 2.0;
    self.startRecordingLabel.font = labelFont;
    self.startRecordingLabel.textColor = labelColor;
    
    UIImage *rewindButtonImage = [UIImage imageNamed:@"rewind button.png"];
    [self.startRecording30Button setBackgroundImage:rewindButtonImage forState:UIControlStateNormal];
    [self.startRecordingBeginBufferButton setBackgroundImage:rewindButtonImage forState:UIControlStateNormal];

    [self.SayWhatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
    
    self.instantReplaySwitch.onTintColor = [UIColor colorWithRed:0.70f green:0.00f blue:0.00f alpha:1.00f];

}

-(sayWhatRecorder *)myRecorder{
    return  ((AppDelegate *)[[UIApplication sharedApplication] delegate]).sharedRecorder;
}

-(void)showPlayer{
    self.playerViewContainer.hidden = NO;
}

-(void)hidePlayer{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        self.playerViewContainer.hidden = YES;
}

-(void)setUIForCurrentRecordingMode{
    if (self.myRecorder.currentMode == recorderModeStandby) {
#ifdef DEBUG
        NSLog(@"setting UI for recorderModeStandby");
#endif
        [self queueContains:0];
        self.stopButton.enabled = NO;
        self.recordingLightImageView.image = [UIImage imageNamed:@"red light off.png"];
        self.instantReplaySwitch.enabled = YES;
        [self.instantReplaySwitch setOn:NO animated:YES];
        self.SayWhatButton.enabled = NO;
    }else if(self.myRecorder.currentMode == recorderModeReplay) {
#ifdef DEBUG
        NSLog(@"setting UI for recorderModeReplay");
#endif
        self.stopButton.enabled = NO;
        self.startRecordingNowButton.hidden = NO;//hide stop button
        self.recordingLightImageView.image = [UIImage imageNamed:@"red light off.png"];
        self.instantReplaySwitch.enabled = YES;
        [self.instantReplaySwitch setOn:YES animated:YES];
        self.SayWhatButton.enabled = YES;
    }else if(self.myRecorder.currentMode == recorderModeRecording) {
#ifdef DEBUG
        NSLog(@"setting UI for recorderModeRecording");
#endif
        [self queueContains:0];
        self.stopButton.enabled = YES;
        self.recordingLightImageView.image = [UIImage imageNamed:@"red light on.png"];
        self.instantReplaySwitch.enabled = NO;
        [self.instantReplaySwitch setOn:NO animated:YES];
        self.SayWhatButton.enabled = NO;
    }
}

#pragma mark - user input
- (IBAction)stopButtonHit:(id)sender {//stop recording button
    [self.myRecorder stopRecording];
    [self queueContains:0];
    [self showPlayer];
    [self setUIForCurrentRecordingMode];
}

- (IBAction)instantReplaySwitchChanged:(id)sender {
#ifdef DEBUG
    NSLog(@"instant replay switch changed");
#endif
    if(instantReplaySwitch.on){
        [self.myRecorder enableInstantReplay];
    }else{
        [self.myRecorder disableInstantReplay];
        [self queueContains:0];
    }
    [self setUIForCurrentRecordingMode];
}

- (IBAction)sayWhatButtonHit:(id)sender {
    [self.myRecorder instantReplay];
    [self setUIForCurrentRecordingMode];
    [self showPlayer];
    [self queueContains:0];
}

- (IBAction)startRecordingButtonHit:(UIButton *)sender {
    [instantReplaySwitch setOn:NO animated:YES];
    
    if(sender == self.startRecordingBeginBufferButton){//begining of buffer
        [self.myRecorder startRecordingWithInstandReplay];
    }else if(sender == self.startRecording30Button){//30 seconds
        [self.myRecorder instantReplayPruneFiles:7];
        [self.myRecorder startRecordingWithInstandReplay];
    }else{//start recording now
        [self.myRecorder startRecordingNow];
        //[instantReplaySwitch setOn:NO animated:YES];
    }
    [self queueContains:0];
    [self setUIForCurrentRecordingMode];
}

- (IBAction)closeHelpButtonHit:(id)sender {
    self.helpView.hidden = YES;
}

-(void)queueContains:(int)seconds{
    if(self.myRecorder.currentMode == recorderModeRecording){
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            self.startRecordingNowButton.hidden = YES;
        self.startRecordingNowButton.enabled = NO;
    }else{
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            self.startRecordingNowButton.hidden = NO;
        self.startRecordingNowButton.enabled = YES;
    }
    
    if(seconds == 0){
        [self.startRecording30Button setTitle:@":00" forState:UIControlStateNormal];
        [self.startRecording30Button setTitle:@":00" forState:UIControlStateHighlighted];
        self.startRecording30Button.enabled = NO;
        
        [self.startRecordingBeginBufferButton setTitle:@":00" forState:UIControlStateNormal];
        [self.startRecordingBeginBufferButton setTitle:@":00" forState:UIControlStateHighlighted];
    
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            self.startRecordingBeginBufferButton.hidden = YES;
        else
            self.startRecordingBeginBufferButton.enabled = NO;
    
    }else if(seconds < 30){
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            self.startRecordingBeginBufferButton.hidden = YES;
        else
            self.startRecordingBeginBufferButton.enabled = NO;

        
        [self.startRecording30Button setTitle:[NSString stringWithFormat:@":%02i", seconds%60]
                                     forState:UIControlStateNormal];
        [self.startRecording30Button setTitle:[NSString stringWithFormat:@":%02i", seconds%60]
                                     forState:UIControlStateHighlighted];
        self.startRecording30Button.enabled = YES;
    }else{
        self.startRecording30Button.enabled = YES;
        [self.startRecording30Button setTitle:@":30" forState:UIControlStateNormal];
        [self.startRecording30Button setTitle:@":30" forState:UIControlStateHighlighted];
    
        self.startRecordingBeginBufferButton.enabled = YES;
        if(self.startRecordingBeginBufferButton.hidden){
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationBeginsFromCurrentState:YES];
            [UIView setAnimationDuration:0.3f];
            self.startRecordingBeginBufferButton.hidden = NO;
            [UIView commitAnimations];
        }
        
        NSString *titleString;
        if(seconds >= 60)
            titleString = [NSString stringWithFormat:@"%i:%02i", seconds/60, seconds%60];
        else 
            titleString = [NSString stringWithFormat:@":%02i", seconds%60];
        
        [self.startRecordingBeginBufferButton setTitle:titleString
                                              forState:UIControlStateNormal];
        [self.startRecordingBeginBufferButton setTitle:titleString
                                              forState:UIControlStateHighlighted];
    }
}

#pragma mark - split view controller delegate
- (void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController 
withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc{
    barButtonItem.title = @"Recordings";
    self.navigationItem.leftBarButtonItem = barButtonItem;
}

- (void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController 
invalidatingBarButtonItem:(UIBarButtonItem *)button{
    self.navigationItem.leftBarButtonItem = nil;
}

@end
