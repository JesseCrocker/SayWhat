//
//  sayWhatPlayerView.m
//  Say What
//
//  Created by Jesse Crocker on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "sayWhatPlayerView.h"
#import "AppDelegate.h"
#import "sayWhatPlayer.h"

#define kRewindTimerDuration 0.05

@interface sayWhatPlayerView (){
    NSTimer *rewindTimer;
    NSNumber *originalPlaybackRate;
}

@end


@implementation sayWhatPlayerView
@synthesize timeSlider;
@synthesize playButton;
@synthesize pauseButton;
@synthesize backButton;
@synthesize forwardButton;
@synthesize deleteButton;
@synthesize playbackRateButton;
@synthesize endTimeLabel;
@synthesize startTimeLabel;
@synthesize actionButton;
@synthesize closerDelegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)setup{
    [self.playbackRateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.timeSlider.minimumTrackTintColor = [UIColor colorWithRed:0.70f green:0.00f blue:0.00f alpha:1.00f];
    self.timeSlider.thumbTintColor = [UIColor colorWithRed:0.57f green:0.57f blue:0.57f alpha:1.00f];
}

-(sayWhatPlayer *)sharedPlayer{
    return ((AppDelegate *)[[UIApplication sharedApplication] delegate]).sharedPlayer;
}

- (IBAction)rateButtonHit:(id)sender {
    CGFloat currentRate = self.sharedPlayer.playbackRate.floatValue;
    if(currentRate > 1.99){//2
        self.sharedPlayer.playbackRate = [NSNumber numberWithFloat:0.5];
    }else if(currentRate > 1.49){//1.5
        self.sharedPlayer.playbackRate = [NSNumber numberWithFloat:2.0];
    }else if(currentRate > 0.99){//1
        self.sharedPlayer.playbackRate = [NSNumber numberWithFloat:1.5];
    }else{//.5
        self.sharedPlayer.playbackRate = [NSNumber numberWithFloat:1.0];
    }
    [self updatePlayRateButton];
}

-(void)updatePlayRateButton{
#ifdef DEBUG
    NSLog(@"updating rate button");
#endif
    
    CGFloat currentRate = self.sharedPlayer.playbackRate.floatValue;
    if(currentRate > 1.99){//2
        [self setTitleForPlayRateButton:@"2X"];
    }else if(currentRate > 1.49){//1.5
       [self setTitleForPlayRateButton:@"1½X"];
    }else if(currentRate > 0.99){//1
        [self setTitleForPlayRateButton:@"1X"];
    }else{//.5
        [self setTitleForPlayRateButton:@"½X"];
    }
}

-(void)setTitleForPlayRateButton:(NSString *)string{
    [self.playbackRateButton setTitle:string forState:UIControlStateNormal];
    [self.playbackRateButton setTitle:string forState:UIControlStateHighlighted];
}

- (IBAction)sliderChanged:(id)sender {
    [self.sharedPlayer setPlayPoint:timeSlider.value];
}

-(void)updatePlayButton{
    if([self.sharedPlayer isPlaying]){
        self.playButton.hidden = YES;
        self.pauseButton.hidden = NO;
    }else{
        self.playButton.hidden = NO;
        self.pauseButton.hidden = YES;
    }
}

- (IBAction)playButtonHit:(id)sender {
    [self.sharedPlayer play];
}

- (IBAction)pauseButtonHit:(id)sender {
    [self.sharedPlayer pause];
}

- (IBAction)stopButtonHit:(id)sender {
    [self.sharedPlayer stop];
}

- (IBAction)deleteButtonHit:(id)sender {
    Recording *rec = self.sharedPlayer.recording;
    self.sharedPlayer.recording = nil;
    if(rec == nil)
        return;
    [self.sharedPlayer stop];
    [rec deleteFile];
    [((AppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext deleteObject:rec];
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] saveContext];
    
    self.timeSlider.maximumValue = 0;
    self.endTimeLabel.text = @"0:00";
    [self updatePlayButton];
    
    if(self.closerDelegate)
        [self.closerDelegate hidePlayer];
}

#pragma mark - rewind
- (IBAction)rewindButtonDown:(id)sender {
    [self startRewindTimer];
}

- (IBAction)rewindButtonUp:(id)sender {
    [self stopRewindTimer];
}

-(void)startRewindTimer{
    if(rewindTimer)
        [rewindTimer invalidate];
    rewindTimer = [NSTimer scheduledTimerWithTimeInterval:kRewindTimerDuration target:self
                                                 selector:@selector(rewindAction)
                                                 userInfo:nil repeats:YES];
}

-(void)stopRewindTimer{
    [rewindTimer invalidate];
    rewindTimer = nil;
}

-(void)rewindAction{
    CGFloat newPoint = self.sharedPlayer.playPoint - (kRewindTimerDuration * 3);
    if(newPoint < 0)
        newPoint = 0;
    [self.sharedPlayer setPlayPoint:newPoint];
}

#pragma mark fast forward
- (IBAction)fastForwardButtonDown:(id)sender {
    //[self startFastForwardTimer];
    originalPlaybackRate = self.sharedPlayer.playbackRate;
    self.sharedPlayer.playbackRate = [NSNumber numberWithInt:4];
}

- (IBAction)fastForwardButtonUp:(id)sender {
    //[self stopRewindTimer];
    if(originalPlaybackRate)
        self.sharedPlayer.playbackRate = originalPlaybackRate;
}

#pragma mark - export
- (IBAction)actionButtonHit:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Share Recording" 
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Sound Cloud", @"Dropbox", @"Email", nil];
    [actionSheet showInView:self];
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(buttonIndex == actionSheet.firstOtherButtonIndex){//sound cloud
        [self soundCloudUpload];
    }else if(buttonIndex == actionSheet.firstOtherButtonIndex + 1){//drop box
        [self sendToDropBox];
    }else if(buttonIndex == actionSheet.firstOtherButtonIndex + 2){//email
        [self sendEmail];
    }
}

-(void)sendToDropBox{
    Recording *thisRecording = self.sharedPlayer.recording;
    if (![[DBSession sharedSession] isLinked]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cop Watch is not linked to your Dropbox"
                                                        message:@"Send again after linking your account"
                                                       delegate:self
                                              cancelButtonTitle:@"Forget it"
                                              otherButtonTitles:@"Link Now", nil];
        [alert show];
    }else{
#ifdef DEBUG
        NSLog(@"sending file to dropbox");
#endif
        [((AppDelegate *)[[UIApplication sharedApplication] delegate]).dbRestClient uploadFile:thisRecording.filenameForExport 
                                                                                    toPath:@"/"
                                                                             withParentRev:nil
                                                                                fromPath:thisRecording.path];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sending recording to your Dropbox"
                                                        message:nil
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(buttonIndex == alertView.firstOtherButtonIndex){
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] dropboxLink];
    }
}



-(void)sendEmail{
    if(![MFMailComposeViewController canSendMail])
        return;
    
    Recording *thisRecording = self.sharedPlayer.recording;
    
    MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
    composer.mailComposeDelegate = self;
    
    NSData *soundData = [[NSData alloc] initWithContentsOfURL:thisRecording.url];
    [composer addAttachmentData:soundData
                               mimeType:@"audio/mp4"
                               fileName:thisRecording.filenameForExport];
    
    [composer setSubject:@"Recording from Cop Watch!?"];
    
    NSMutableString *emailBody = [NSMutableString stringWithString:@"Recording From Cop Watch\n"];
    if(thisRecording.name && thisRecording.name.length > 0){
        [emailBody appendFormat:@"Title: %@\n", thisRecording.name];
    }
    
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    [emailBody appendFormat:@"Recorded: %@\n", [dateFormatter stringFromDate:thisRecording.date]];
    
    [emailBody appendFormat:@"Recording length: %i:%02i\n", thisRecording.length.intValue/60, thisRecording.length.intValue%60];
    [composer setMessageBody:emailBody isHTML:NO];
    
    [((AppDelegate *)[[UIApplication sharedApplication] delegate]).window.rootViewController presentModalViewController:composer
                                                                                                               animated:YES];

}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self becomeFirstResponder];
	[((AppDelegate *)[[UIApplication sharedApplication] delegate]).window.rootViewController dismissModalViewControllerAnimated:YES];
}

- (void)soundCloudUpload{
#ifdef DEBUG
    NSLog(@"sending to sound cloud");
#endif
    NSURL *trackURL = self.sharedPlayer.recording.url;
    
    SCShareViewController *shareViewController;
    shareViewController = [SCShareViewController shareViewControllerWithFileURL:trackURL
                                                              completionHandler:^(NSDictionary *trackInfo, NSError *error){
                                                                  
                                                                  if (SC_CANCELED(error)) {
#ifdef DEBUG
                                                                      NSLog(@"Canceled!");
#endif
                                                                  } else if (error) {
                                                                      NSLog(@"error sending to sound cloud: %@", [error localizedDescription]);
                                                                  } else {
#ifdef DEBUG
                                                                      NSLog(@"Uploaded track to sound cloud: %@", trackInfo);
#endif
                                                                  }
                                                              }];
    
    [shareViewController setFoursquareClientID:@"IYN10SFV5LXBR2CP340MZJ33CP020KST32CQQIXLJVOEQ4O2"
                                  clientSecret:@"ZPZR5YYOHXQJFOOH4KWG2AWJJKRLBIHMQV3QLMGP4NPNVYHO"];
    
    [shareViewController setPrivate:NO];
    
    [((AppDelegate *)[[UIApplication sharedApplication] delegate]).window.rootViewController presentModalViewController:shareViewController animated:YES];
}

/*
-(void)startFastForwardTimer{
    if(rewindTimer)
        [rewindTimer invalidate];
    rewindTimer = [NSTimer scheduledTimerWithTimeInterval:kRewindTimerDuration target:self
                                                 selector:@selector(fastForwardAction)
                                                 userInfo:nil repeats:YES];
}

-(void)fastForwardAction{
    CGFloat newPoint = self.sharedPlayer.playPoint + (kRewindTimerDuration * 4);
    if(newPoint > self.timeSlider.maximumValue)
        newPoint = self.timeSlider.maximumValue;
    [self.sharedPlayer setPlayPoint:newPoint];
}*/
@end
