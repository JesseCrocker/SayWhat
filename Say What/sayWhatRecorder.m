//
//  sayWhatRecorder.m
//  Say What
//
//  Created by Jesse Crocker on 6/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "sayWhatRecorder.h"
#import "AppDelegate.h"
#import "Recording.h"
#import "SVProgressHUD.h"

#define kTimerInterval 5.0

@interface NSMutableArray (ShiftExtension)
-(id)shift;
@end
@implementation NSMutableArray (ShiftExtension)
-(id)shift {//remove first element of array and return it
    if([self count] < 1) return nil;
    id obj = [self objectAtIndex:0];
    [self removeObjectAtIndex:0];
    return obj;
}
@end

@interface sayWhatRecorder (){
    AVAudioRecorder *audioRecorder;
    NSTimer *instantReplayTimer;
    NSMutableArray *instantReplayRecordings;
    NSDictionary *recorderSettings;
    bool playFilesOnCompletion;
    NSTimer *levelMeterTimer;
    NSTimer *queueDelegateTimer;
    int instantReplayTime;
    NSOperationQueue *audioProcessingQueue;
}

@end

@implementation sayWhatRecorder
@synthesize levelMeter = _levelMeter;
@synthesize queueDelegate;
@synthesize currentMode;
@synthesize instantReplayStoppedOnInteruption;
@synthesize recordStoppedOnInteruption;

- (id)init{
    self = [super init];
    if (self) {
        currentMode = recorderModeStandby;
        recorderSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:AVAudioQualityMax],         AVEncoderAudioQualityKey,
                            [NSNumber numberWithInt:16],                        AVEncoderBitRateKey,
                            [NSNumber numberWithInt: 1],                        AVNumberOfChannelsKey,
                            [NSNumber numberWithInt:kAudioFormatAppleLossless], AVFormatIDKey,
                            //[NSNumber numberWithInt:kAudioFormatMPEG4AAC_HE],   AVFormatIDKey, doesnt work
                            //[NSNumber numberWithFloat:44100.0],                 AVSampleRateKey,
                            [NSNumber numberWithFloat:22000.0],                 AVSampleRateKey,
                            nil];
        audioProcessingQueue = [[NSOperationQueue alloc] init];
        [self resetInteruptionFlags];
    }
    return self;
}

-(void)initializeRecorder{    
    NSURL *soundFileURL = [self generateUrlForRecording];
#ifdef DEBUG
    NSLog(@"initializing recorder to url:%@", soundFileURL);
#endif
    
    NSError *error = nil;
    audioRecorder = [[AVAudioRecorder alloc]
                     initWithURL:soundFileURL
                     settings:recorderSettings
                     error:&error];
    audioRecorder.delegate = self;
    
    if (error){
        NSLog(@"error initializing recorder: %@", [error localizedDescription]);
        return;
    }
    [audioRecorder prepareToRecord];
    if(self.levelMeter)
        audioRecorder.meteringEnabled = YES;
}

#pragma mark - instant replay on/off public interface
-(void)enableInstantReplay{
#ifdef DEBUG
    NSLog(@"enableing instant replay");
#endif
    
    if(currentMode == recorderModeReplay){
        NSLog(@"ERROR: enable instant replay called, but already in replay mode");
    }
    
    [self resetInteruptionFlags];
    self.currentMode = recorderModeReplay;
    [self startLevelMeterTimer];
    [self instantReplayDumpAllFiles];
    instantReplayTime = 0;
    queueDelegateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                          target:self
                                                        selector:@selector(updateQueueDelegate)
                                                        userInfo:nil
                                                         repeats:YES];
    
    instantReplayRecordings = [[NSMutableArray alloc] init];
    
    [self instantReplaySwitchToNewFile];
    instantReplayTimer = [NSTimer scheduledTimerWithTimeInterval:kTimerInterval 
                                                          target:self
                                                        selector:@selector(instantReplaySwitchToNewFile) 
                                                        userInfo:nil 
                                                         repeats:YES];
    
    if([[NSUserDefaults standardUserDefaults] valueForKey:@"remote_preference"] == nil ||
       [[[NSUserDefaults standardUserDefaults] valueForKey:@"remote_preference"] boolValue]){
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    }else{
#ifdef DEBUG
        NSLog(@"Not using remote control due to preference setting");
#endif
    }
}

-(void)disableInstantReplay{
    if(currentMode != recorderModeReplay){
        NSLog(@"ERROR: disableInstantReplay called, but were not in replay mode");
    }
    
#ifdef DEBUG
    NSLog(@"disableing instant replay");
#endif
    self.currentMode = recorderModeStandby;
    [instantReplayTimer invalidate];
    [queueDelegateTimer invalidate];
    [audioRecorder stop];
    [self stopLevelMeterTimer];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

-(bool)instantReplayEnabled{
    return self.currentMode == recorderModeReplay;
}

#pragma mark - public recording interface
-(void)instantReplay{
    if(currentMode != recorderModeReplay){
        NSLog(@"ERROR: instantReplay called, but we're no in recorderModeReplay");
    }
    
    self.currentMode = recorderModeStandby;
    playFilesOnCompletion = YES;
    [self stopLevelMeterTimer];
    [queueDelegateTimer invalidate];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self combineInstantReplayFiles];
}

-(bool)recording{
    return self.currentMode == recorderModeRecording;
}

-(void)stopRecording{
    if(currentMode != recorderModeRecording){
        NSLog(@"ERROR: stopRecording called, but not in recording mode");
    }
    
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    self.currentMode = recorderModeStandby;
    if([audioRecorder isRecording]){
#ifdef DEBUG
        NSLog(@"stopping recording");
#endif
        [self stopLevelMeterTimer];
        if(instantReplayTimer){
            [instantReplayTimer invalidate];
            instantReplayTimer = nil;
        }
        
        [audioRecorder stop];
        if(instantReplayRecordings && instantReplayRecordings.count > 0){
            
        }else{
            instantReplayRecordings = [[NSMutableArray alloc] initWithCapacity:1];
            [instantReplayRecordings addObject:audioRecorder.url];
        }
        playFilesOnCompletion = NO;
        [self combineInstantReplayFiles];
    }
}

-(void)startRecordingNow{
    if(currentMode == recorderModeRecording){
        NSLog(@"ERROR: startRecorordingNowCalled, but we're already in recording mode");
    }
    
    [self startLevelMeterTimer];
    [queueDelegateTimer invalidate];
    
    if(instantReplayTimer != nil){
        [instantReplayTimer invalidate];
        instantReplayTimer = nil;
    }
    
    if([audioRecorder isRecording]){
        if(instantReplayRecordings && instantReplayRecordings.count){
            [instantReplayRecordings removeLastObject];
        }
    }else{
        [self initializeRecorder];
        [audioRecorder record];
    }

    if(instantReplayRecordings && instantReplayRecordings.count){
        [self instantReplayDumpAllFiles];
        instantReplayRecordings = nil;
    }
    
    self.currentMode = recorderModeRecording;
}

-(void)startRecordingWithInstandReplay{
#ifdef DEBUG
    NSLog(@"starting recording with instant replay files");
#endif
    if(currentMode != recorderModeReplay){
        NSLog(@"ERROR: startRecordingWithInstandReplay called, when not in replay mode");
    }
    [queueDelegateTimer invalidate];
    [instantReplayTimer invalidate];
    instantReplayTimer = nil;
    currentMode = recorderModeRecording;
}

#pragma mark - queue delegate
-(void)updateQueueDelegate{
    if(instantReplayTime < (60 * 5))
        instantReplayTime++;
    
    if(self.queueDelegate)
        [self.queueDelegate queueContains:instantReplayTime];
}

#pragma mark - level meter
-(void)setLevelMeter:(levelMeterView *)levelMeter{
    _levelMeter = levelMeter;
    if(self.currentMode == recorderModeRecording || self.currentMode == recorderModeReplay)
        [self startLevelMeterTimer];
}

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
    [audioRecorder updateMeters];
    [self.levelMeter updateMeterAveragePower:[audioRecorder averagePowerForChannel:0]
                                   peakPower:[audioRecorder peakPowerForChannel:0]];
}

#pragma mark - instant replay files
-(void)instantReplaySwitchToNewFile{
#ifdef DEBUG
    NSLog(@"instant replay switch to new file");
#endif
    
    AVAudioRecorder *oldRecorder = audioRecorder;
    [self initializeRecorder];
    [instantReplayRecordings addObject:audioRecorder.url];
    [audioRecorder record];
    if(oldRecorder != nil)
        [oldRecorder stop];
    [self instantReplayPruneFiles:60];
}

-(void)combineInstantReplayFiles{
    [SVProgressHUD showWithStatus:@"Processing Audio"];

    [self disableInstantReplay];
    
    NSMutableArray *tracksToProccess = instantReplayRecordings;
    instantReplayRecordings = nil;

    NSURL *urlForCombinedRecording = [self generateUrlForCombinedRecordings];
    
    [audioProcessingQueue addOperationWithBlock:^{
        AVMutableComposition *composition = [AVMutableComposition composition];
        AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        CMTime startTime = kCMTimeZero;
        bool ok;
        for (NSInteger i = 0; i < tracksToProccess.count; i++) {
            NSURL *url = [tracksToProccess objectAtIndex:i];
#ifdef DEBUG
            NSLog(@"adding file to combined track:%@", url);  
#endif
            
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
            AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            CMTimeRange trackRange = CMTimeRangeMake(kCMTimeZero, [asset duration]);
            
            ok = [compositionAudioTrack insertTimeRange:trackRange ofTrack:audioTrack atTime:startTime error:nil];
            if(!ok){
                NSLog(@"ERROR adding track %i to composition", i);
                break;
            }
            startTime = CMTimeAdd(startTime, [asset duration]);
        }
        NSError *error;
        if(![compositionAudioTrack validateTrackSegments:compositionAudioTrack.segments error:&error]){
            NSLog(@"ERROR validating tracks: %@", [error localizedDescription]);
        }
            
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
        exporter.outputURL = urlForCombinedRecording;
        exporter.outputFileType = [[exporter supportedFileTypes] objectAtIndex:0];
        
#ifdef DEBUG
        NSLog(@"saving combined file of type:%@ to url:%@", exporter.outputFileType, exporter.outputURL);
#endif
        
        [exporter exportAsynchronouslyWithCompletionHandler:^(void){
            [SVProgressHUD dismiss];
            [self combineAudioFinished:exporter.outputURL
                                status:exporter.status
                              duration:(startTime.value/startTime.timescale)
                                 error:exporter.error];
        } ];
    }]; 
}

-(void)combineAudioFinished:(NSURL *)url status:(AVAssetExportSessionStatus)status duration:(NSInteger)duration error:(NSError *)error{
#ifdef DEBUG
    NSLog(@"combine audio finished");
#endif
    NSManagedObjectContext *managedObjectContext = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
    Recording *newRecording = (Recording *)[NSEntityDescription insertNewObjectForEntityForName:@"Recording" inManagedObjectContext:managedObjectContext];
    newRecording.date = [NSDate date];

    NSURL *permUrl = [self generatePermanentUrlForFile];
    NSFileManager *fileManager = [NSFileManager defaultManager];

#ifdef DEBUG
    NSLog(@"moving file at from: %@ to :%@", url, permUrl);
#endif
    
    NSError *fileError;
    if(![fileManager moveItemAtURL:url toURL:permUrl error:&fileError]){
        NSLog(@"ERROR moving file at from: %@ to :%@", url, permUrl);
    }
    newRecording.path = [permUrl path];
    newRecording.length = [NSNumber numberWithInt:duration];
#ifdef DEBUG
    NSLog(@"saving new recording:%@", newRecording);
#endif
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] saveContext];

    sayWhatPlayer *player = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).sharedPlayer;
    player.playbackRate = [NSNumber numberWithFloat:1.0];
    [player performSelectorOnMainThread:@selector(setRecordingByID:) withObject:newRecording.objectID waitUntilDone:YES];
    
    if(player.playerView){
        [player.playerView performSelectorOnMainThread:@selector(updatePlayButton)
                                            withObject:nil
                                         waitUntilDone:NO];
        if(player.playerView.closerDelegate)
            [player.playerView.closerDelegate performSelectorOnMainThread:@selector(showPlayer)
                                                               withObject:nil
                                                            waitUntilDone:NO];
    }
    
    if(playFilesOnCompletion){
        [player performSelectorOnMainThread:@selector(play) withObject:nil waitUntilDone:NO];
    }
}

#pragma mark - file management
-(NSURL *)generateUrlForRecording{
    //NSURL *docUrl = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).applicationDocumentsDirectory;
    NSString *tmpDir = NSTemporaryDirectory();
    NSString *filename = [NSString stringWithFormat:@"%1.0f.caf", [NSDate timeIntervalSinceReferenceDate]];
    NSString *path = [tmpDir stringByAppendingPathComponent:filename];
    return [NSURL fileURLWithPath:path];
}

-(NSURL *)generateUrlForCombinedRecordings{
    NSString *tmpDir = NSTemporaryDirectory();
    NSString *filename = [NSString stringWithFormat:@"%1.0fcombined.m4a", [NSDate timeIntervalSinceReferenceDate]];
    NSString *path = [tmpDir stringByAppendingPathComponent:filename];
    return [NSURL fileURLWithPath:path];
}

-(NSURL *)generatePermanentUrlForFile{
    NSURL *docUrl = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).applicationDocumentsDirectory;
    NSString *filename = [NSString stringWithFormat:@"%1.0f.m4a", [NSDate timeIntervalSinceReferenceDate]];
    return [docUrl URLByAppendingPathComponent:filename];
}

-(void)instantReplayPruneFiles:(NSInteger)maxFiles{
#ifdef DEBUG
    NSLog(@"pruning files");
#endif
    while(instantReplayRecordings.count > maxFiles){
        NSURL *toDelete = [instantReplayRecordings shift];
        [self deleteFileAtUrl:toDelete];
    }
}

-(void)instantReplayDumpAllFiles{
#ifdef DEBUG
    NSLog(@"dumping all instant replay files");
#endif
    if(instantReplayRecordings == nil || instantReplayRecordings.count == 0)
        return;
    
    for(NSURL *url in instantReplayRecordings){
        [self deleteFileAtUrl:url];
    }
}

-(void)deleteFileAtUrl:(NSURL *)url{
#ifdef DEBUG
    NSLog(@"deleteing file:%@", url);
#endif
    
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager removeItemAtURL:url error:&error]){
        NSLog(@"ERROR deleteing file at url:%@", url);
    }
}

#pragma mark - audio recorder delegate
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder 
                          successfully:(BOOL)flag{
#ifdef DEBUG
    NSLog(@"recorder did finish recording");
#endif
}

-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder 
                                  error:(NSError *)error{
#ifdef DEBUG
    NSLog(@"Encode Error occurred");
#endif
}

- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder{
#ifdef DEBUG
    NSLog(@"audio recorder begin interuption");
#endif
    if(self.currentMode == recorderModeReplay){
        self.instantReplayStoppedOnInteruption = YES;
        [self disableInstantReplay]; 
    }else if(self.currentMode == recorderModeRecording){
        self.recordStoppedOnInteruption = YES;
        
        [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
        self.currentMode = recorderModeStandby;
        [self stopLevelMeterTimer];
        if(instantReplayTimer){
            [instantReplayTimer invalidate];
            instantReplayTimer = nil;
        }        
        [audioRecorder stop];
        
    }else{
        //if it isnt in the above modes, then there wasnt anything to interupt
    }
    if(self.queueDelegate)
        [self.queueDelegate setUIForCurrentRecordingMode];
}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withFlags:(NSUInteger)flags{
#ifdef DEBUG
    NSLog(@"audio recorder end interuption");
#endif
    if(self.instantReplayStoppedOnInteruption){
        self.currentMode = recorderModeReplay;
        [self startLevelMeterTimer];
        queueDelegateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                              target:self
                                                            selector:@selector(updateQueueDelegate)
                                                            userInfo:nil
                                                             repeats:YES];
        [self instantReplaySwitchToNewFile];
        instantReplayTimer = [NSTimer scheduledTimerWithTimeInterval:kTimerInterval 
                                                              target:self
                                                            selector:@selector(instantReplaySwitchToNewFile) 
                                                            userInfo:nil 
                                                             repeats:YES];
        
        if([[NSUserDefaults standardUserDefaults] valueForKey:@"remote_preference"] == nil ||
           [[[NSUserDefaults standardUserDefaults] valueForKey:@"remote_preference"] boolValue]){
            [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        }
        
    }else if(self.recordStoppedOnInteruption){
        [self startLevelMeterTimer];
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        [audioRecorder record];
    }
    
    [self resetInteruptionFlags];
    if(self.queueDelegate)
        [self.queueDelegate setUIForCurrentRecordingMode];
}

-(void)resetInteruptionFlags{
    self.instantReplayStoppedOnInteruption = NO;
    self.recordStoppedOnInteruption = NO;
}
@end
