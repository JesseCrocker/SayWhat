//
//  audioPlayer.m
//  Say What
//
//  Created by Jesse Crocker on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "sayWhatPlayer.h"
#import "AppDelegate.h"

@interface sayWhatPlayer (){
    AVAudioPlayer *audioPlayer;
    //AVPlayer *audioPlayer;
    NSTimer *updatePlayerTimer;
    NSTimer *levelMeterTimer;
}

@end

@implementation sayWhatPlayer

@synthesize levelMeter = _levelMeter;
@synthesize recording = _recording;
@synthesize playerView = _playerView;
@synthesize playbackRate = _playbackRate;
@synthesize playbackWasInterupted;

- (id)init{
    self = [super init];
    if (self) {
        self.playbackRate = [NSNumber numberWithFloat:1.0];
        self.playbackWasInterupted = NO;
    }
    return self;
}

#pragma mark - controls
-(void)play{
#ifdef DEBUG
    NSLog(@"sayWhatPlayer: play");
#endif
    if(audioPlayer ){
        sayWhatRecorder *recorder = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).sharedRecorder;
        if(recorder.currentMode == recorderModeRecording){
            [recorder stopRecording];
            if(recorder.queueDelegate)
                [recorder.queueDelegate setUIForCurrentRecordingMode];
        }else if(recorder.currentMode == recorderModeReplay){
            [recorder disableInstantReplay];
            if(recorder.queueDelegate)
                [recorder.queueDelegate setUIForCurrentRecordingMode];
        }   
        audioPlayer.rate = self.playbackRate.floatValue;
        [audioPlayer play];
        [self startPlayerTimer];
        if(self.playerView){
            [self.playerView updatePlayButton];
            if(self.playerView.closerDelegate)
                [self.playerView.closerDelegate showPlayer];
        }
        [self startLevelMeterTimer];
    }
    self.playbackWasInterupted = NO;
}

-(void)pause{
    if(audioPlayer && self.isPlaying){
        [audioPlayer pause];
        [self stopPlayerTimer];
        [self stopLevelMeterTimer];
        if(self.playerView)
            [self.playerView updatePlayButton];
    }
}

-(void)stop{
    if(audioPlayer && self.isPlaying){
        //[audioPlayer stop];
        [audioPlayer pause];
        [self stopPlayerTimer];
        [self stopLevelMeterTimer];
    }
}

-(void)setPlayPoint:(CGFloat)playPoint{
    audioPlayer.currentTime = playPoint;
}

-(CGFloat)playPoint{
    return audioPlayer.currentTime;
}

-(void)setPlaybackRate:(NSNumber *)playbackRate{
#ifdef DEBUG
    NSLog(@"set playback rate:%@", playbackRate);
#endif
    _playbackRate = playbackRate;
    if(audioPlayer && self.isPlaying)
        audioPlayer.rate = playbackRate.floatValue;
}

#pragma mark - status
-(bool)isPlaying{
    if(audioPlayer == nil)
        return NO;
    return audioPlayer.isPlaying;
    //return audioPlayer.rate != 0.0;
}

#pragma mark - 
-(void)setRecordingByID:(NSManagedObjectID *)recordingID{
    NSManagedObjectContext *managedObjectContext = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    Recording *thisRecording = (Recording *)[managedObjectContext objectWithID:recordingID];
    //NSLog(@"found recording by id:%@", thisRecording);
    self.recording = thisRecording;
}

-(void)setRecording:(Recording *)recording{
    _recording = nil;
    [audioPlayer pause];
    audioPlayer = nil;

    //NSLog(@"got recording in player:%@", recording);
    
    _recording = recording;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:recording.path]){
#ifdef DEBUG
        NSLog(@"playing back file:%@", recording.path);
#endif
    }else{
#ifdef DEBUG
        NSLog(@"cant play file, file does not exist:%@", recording.path);
#endif
        return;
    }
    
    NSURL *fileUrl = recording.url;
    NSError *error;
    audioPlayer = [[AVAudioPlayer alloc] 
                   initWithContentsOfURL:fileUrl                  
                   error:&error];
    if (error){
        NSLog(@"Error initializing audio player: %@", 
              [error localizedDescription]);
    } else{
#ifdef DEBUG
        NSLog(@"audio player initialized");
#endif
        audioPlayer.delegate = self;
        audioPlayer.enableRate = YES;
        audioPlayer.meteringEnabled = YES;
        [audioPlayer prepareToPlay];
    }
    if(self.playerView){
        [self setPlayerViewUIToCurrentValues];
    }
    self.playbackWasInterupted = NO;
}

-(void)setPlayerView:(sayWhatPlayerView *)playerView{
    _playerView = playerView;
    if(audioPlayer){
        [self setPlayerViewUIToCurrentValues];
    }
}

#pragma mark -
-(void)startPlayerTimer{
#ifdef DEBUG
    NSLog(@"start player timer");
#endif
    if(updatePlayerTimer != nil)
        [updatePlayerTimer invalidate];
    updatePlayerTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updatePlayerView) userInfo:nil repeats:YES];
}

-(void)stopPlayerTimer{
#ifdef DEBUG
    NSLog(@"stop player timer");
#endif
    [updatePlayerTimer invalidate];
    updatePlayerTimer = nil;
}

-(void)setPlayerViewUIToCurrentValues{
#ifdef DEBUG
    NSLog(@"duration:%1.1f", audioPlayer.duration );
#endif
    self.playerView.timeSlider.minimumValue = 0;
    self.playerView.timeSlider.maximumValue = audioPlayer.duration;
    self.playerView.timeSlider.value = audioPlayer.currentTime;
    
    int duration = audioPlayer.duration;
    self.playerView.endTimeLabel.text = [NSString stringWithFormat:@"%i:%02i", (duration / 60), (duration % 60)];
    [self.playerView updatePlayRateButton];
}

-(void)updatePlayerView{
    //if(audioPlayer && audioPlayer.isPlaying){
#ifdef DEBUG
    NSLog(@"current time:%1.1f", audioPlayer.currentTime);
#endif
    if(self.playerView)
        self.playerView.timeSlider.value = audioPlayer.currentTime;
}

#pragma mark - level meter
-(void)startLevelMeterTimer{
#ifdef DEBUG
    NSLog(@"starting level meter timer");
#endif
    if(levelMeterTimer != nil)
        return;
    
    if(! self.levelMeter)
        return;
    levelMeterTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self
                                                     selector:@selector(updateLevelMeter) 
                                                     userInfo:nil 
                                                      repeats:YES];
}

-(void)stopLevelMeterTimer{
#ifdef DEBUG
    NSLog(@"stopping level meter timer");
#endif
    [levelMeterTimer invalidate];
    levelMeterTimer = nil;
    if(self.levelMeter)
        [self.levelMeter updateMeterAveragePower:-160 peakPower:-160];
}

-(void)updateLevelMeter{
    if(! self.levelMeter){
        [self stopLevelMeterTimer];
        return;
    }
    [audioPlayer updateMeters];
    [self.levelMeter updateMeterAveragePower:[audioPlayer averagePowerForChannel:0]
                                   peakPower:[audioPlayer peakPowerForChannel:0]];
}

#pragma mark - audio player delegate
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player 
                      successfully:(BOOL)flag{
    [self stopPlayerTimer];
    [self stopLevelMeterTimer];
    if(self.playerView){
        [self.playerView updatePlayButton];
        self.playerView.timeSlider.value = 0;
        [self setPlayPoint:0];
    }
#ifdef DEBUG
    NSLog(@"audio player did finish playing delegate message successfully:%i", flag);
#endif
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player 
                                error:(NSError *)error{
#ifdef DEBUG
    NSLog(@"Decode Error occurred delegate message");
#endif
    [self stopLevelMeterTimer];
    if(self.playerView)
        [self.playerView updatePlayButton];
}

-(void)audioPlayerBeginInterruption:(AVAudioPlayer *)player{
    self.playbackWasInterupted = YES;
    [self stopLevelMeterTimer];
    
    if(self.playerView)
        [self.playerView updatePlayButton];
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player{
    if(self.playbackWasInterupted){
        [player play];
        
        [self startLevelMeterTimer];
        
        if(self.playerView)
            [self.playerView updatePlayButton];
    }
    self.playbackWasInterupted = NO;
}

@end
