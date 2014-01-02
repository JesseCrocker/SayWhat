//
//  AppDelegate.m
//  Say What
//
//  Created by Jesse Crocker on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import <CoreData/CoreData.h>
#import "SoundRecorderViewController.h"
#import "savedSoundsViewController.h"
#import "sayWhatPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@implementation AppDelegate

@synthesize window = _window;
@synthesize sharedRecorder = _sharedRecorder;
@synthesize sharedPlayer = _sharedPlayer;
@synthesize dbRestClient;

@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self customizeUI];
    [self setupAudioSession];
    self.sharedRecorder = [[sayWhatRecorder alloc] init];
    [self.sharedRecorder enableInstantReplay];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.sharedPlayer = [[sayWhatPlayer alloc] init];
        [self initializeSoundcloud];
        [self initializeDropbox];
    });
   
    return YES;
}

-(void)setupAudioSession{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    //session.delegate = self;//deprecated in 6

    AudioSessionAddPropertyListener (
                                     kAudioSessionProperty_AudioRouteChange,
                                     audioRouteChangeListenerCallback,
                                     (__bridge void*)self);//deprecated in 6
    // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChange:) name:AVAudioSessionRouteChangeNotification object:session];
    
    NSError *error;
    if(![session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error]){
        NSLog(@"Error setting category on audio session: %@", error);
    }
   // if(![session setMode:AVAudioSessionModeVoiceChat error:&error]){
     //   NSLog(@"Error setting mode on audio session:%@", error);
    //}
    if(![session setActive:YES error:&error]){
        NSLog(@"error setting audio session active: %@", error);
    }

    
    UInt32 allowBluetoothInput = 1;
    
    AudioSessionSetProperty (
                             kAudioSessionProperty_OverrideCategoryEnableBluetoothInput,
                             sizeof (allowBluetoothInput),
                             &allowBluetoothInput
                             );

}

-(void)customizeUI{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent
                                                animated:NO];
    UIImage *buttonBackground;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        buttonBackground = [[UIImage imageNamed:@"button.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    }else{
      //  NSLog(@"using ipad buttons");
        buttonBackground = [[UIImage imageNamed:@"button-ipad.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0,15, 0, 15)];

    }
    
    id buttonAppearance = [UIButton appearanceWhenContainedIn:[sayWhatPlayerView class], nil];
    [buttonAppearance setFont:[UIFont fontWithName:@"Copperplate" size:17]];
    [buttonAppearance setBackgroundImage:buttonBackground forState:UIControlStateNormal];
    [buttonAppearance setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [buttonAppearance setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];

    buttonAppearance = [UIButton appearanceWhenContainedIn:[SoundRecorderViewController class], nil];    
    [buttonAppearance setFont:[UIFont fontWithName:@"Copperplate" size:17]];
    [buttonAppearance setBackgroundImage:buttonBackground forState:UIControlStateNormal];
    [buttonAppearance setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [buttonAppearance setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];

    [[UITabBar appearance] setSelectedImageTintColor:[UIColor colorWithRed:0.70f green:0.00f blue:0.00f alpha:1.00f]];
    [[UITabBarItem appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor whiteColor], UITextAttributeTextColor, 
      [UIColor blackColor], UITextAttributeTextShadowColor, 
      [NSValue valueWithUIOffset:UIOffsetMake(0, 1)], UITextAttributeTextShadowOffset, 
      [UIFont fontWithName:@"Copperplate" size:12.0], UITextAttributeFont, 
      nil] 
                                             forState:UIControlStateNormal];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
#pragma mark - 
- (void)remoteControlReceivedWithEvent:(UIEvent *)theEvent {
#ifdef DEBUG
    NSLog(@"- (void)remoteControlReceivedWithEvent:(UIEvent *)%@", theEvent);
#endif
    
	if (theEvent.type == UIEventTypeRemoteControl) {
        switch(theEvent.subtype) {
            case UIEventSubtypeRemoteControlTogglePlayPause:
                //NSLog(@"Play pause event");
                
            case UIEventSubtypeRemoteControlPlay:
				//NSLog(@"remote control play event");
                if(self.sharedRecorder.instantReplayEnabled)
                    [self.sharedRecorder startRecordingWithInstandReplay];
                else if(self.sharedRecorder.currentMode == recorderModeStandby)
                    [self.sharedRecorder startRecordingNow];
                else if(self.sharedRecorder.currentMode == recorderModeRecording){
                    [self.sharedRecorder stopRecording];
                    [self.sharedRecorder enableInstantReplay];
                }
				break;
                
            case UIEventSubtypeRemoteControlPause:
				//NSLog(@"remote control pause event");
                break;
                
            case UIEventSubtypeRemoteControlStop:
                //NSLog(@"UIEventSubtypeRemoteControlStop");
                if(self.sharedRecorder.instantReplayEnabled)
                    [self.sharedRecorder disableInstantReplay];
                else if(self.sharedRecorder.currentMode == recorderModeRecording)
                    [self.sharedRecorder stopRecording];
                break;
                
            case UIEventSubtypeRemoteControlBeginSeekingBackward:
                //NSLog(@"UIEventSubtypeRemoteControlBeginSeekingBackward");
                if(self.sharedRecorder.instantReplayEnabled)
                    [self.sharedRecorder instantReplay];
                break;
            
            case UIEventSubtypeRemoteControlPreviousTrack:
               // NSLog(@"UIEventSubtypeRemoteControlPreviousTrack");
                if(self.sharedRecorder.instantReplayEnabled)
                    [self.sharedRecorder instantReplay];
                break;
                
            default:
                //NSLog(@"unknown event sub type");
                return;
        }
        if(self.sharedRecorder.queueDelegate)
            [self.sharedRecorder.queueDelegate performSelectorOnMainThread:@selector(setUIForCurrentRecordingMode) withObject:nil waitUntilDone:NO];
    }else{
#ifdef DEBUG
        NSLog(@"unknown event type" );
#endif
    }
}

#pragma mark - file sharing services
-(void)initializeDropbox{
#ifdef DEBUG
    NSLog(@"initializing dropbox");
#endif
    DBSession* dbSession =
    [[DBSession alloc]
     initWithAppKey:@"xxxxx"
     appSecret:@"xxxx"
     root:kDBRootAppFolder];
    [DBSession setSharedSession:dbSession];
    
}

- (void)dropboxLink {
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self.window.rootViewController];
    }
}

- (DBRestClient *)dbRestClient {
    if (!dbRestClient) {
#ifdef DEBUG
        NSLog(@"initializing dropbox rest client");
#endif
        dbRestClient =
        [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        dbRestClient.delegate = self;
    }
    return dbRestClient;
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                    message:@"Recording Uploaded to Dropbox"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
#ifdef DEBUG
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
#endif
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"There was a problem sending a recording to Dropbox"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
#ifdef DEBUG
    NSLog(@"File upload failed with error - %@", error);
#endif
}

-(void)initializeSoundcloud{
#ifdef DEBUG
    NSLog(@"initializing sound cloud");
#endif
    [SCSoundCloud  setClientID:@"xxxxxx"
                        secret:@"xxxxxx"
                   redirectURL:[NSURL URLWithString:@"saywhat://soundcloud"]];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
#ifdef DEBUG
            NSLog(@"App linked successfully!");
#endif
        }
        return YES;
    }
    // Add whatever other url handling code your app requires here
    return NO;
}

#pragma mark - Application's Documents directory
// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


#pragma mark - Core Data stack
- (void)saveContext{
#ifdef DEBUG
    NSLog(@"appDelegate saveContext");
#endif
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"sayWhatModel" withExtension:@"momd"];
    //NSLog(@"model url:%@", modelURL);
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"SayWhat.sqlite"];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return __persistentStoreCoordinator;
}

#pragma mark - AVAudioSession Delegate
/*
-(void)beginInterruption{
#ifdef DEBUG
    NSLog(@"Audio session delegate begin interuption");
#endif
   }

-(void)endInterruption{
#ifdef DEBUG
    NSLog(@"Audio session delegate end interuption");
#endif
}

-(void)inputIsAvailableChanged:(BOOL)isInputAvailable{
#ifdef DEBUG
    NSLog(@"input is available changed %i", isInputAvailable);
#endif  
}
*/

//-(void)audioRouteChange:(NSDictionary *)option{
    //ios 6
//}

void audioRouteChangeListenerCallback (
                                       void                      *inUserData,
                                       AudioSessionPropertyID    inPropertyID,
                                       UInt32                    inPropertyValueSize,
                                       const void                *inPropertyValue) 
{
    if (inPropertyID != kAudioSessionProperty_AudioRouteChange) return;
    
    CFDictionaryRef routeChangeDictionary = inPropertyValue;
    
    CFNumberRef routeChangeReasonRef =
    CFDictionaryGetValue (
                          routeChangeDictionary,
                          CFSTR (kAudioSession_AudioRouteChangeKey_Reason));
    
    SInt32 routeChangeReason;
    
    CFNumberGetValue (
                      routeChangeReasonRef,
                      kCFNumberSInt32Type,
                      &routeChangeReason);
    
    CFStringRef oldRouteRef =
    CFDictionaryGetValue (
                          routeChangeDictionary,
                          CFSTR (kAudioSession_AudioRouteChangeKey_OldRoute));
       
    UInt32 routeSize = sizeof (CFStringRef);
    CFStringRef newRoute;
    AudioSessionGetProperty (
                             kAudioSessionProperty_AudioRoute,
                             &routeSize,
                             &newRoute
                             );
    
    
    NSString *oldRouteString = (__bridge NSString *)oldRouteRef;
#ifdef DEBUG
    NSLog(@"audio route changed, old route:%@, new route:%@", oldRouteString, newRoute);
#endif
    /*
    if (routeChangeReason == kAudioSessionRouteChangeReason_NewDeviceAvailable){
        //NSLog(@"routeChangeReason = kAudioSessionRouteChangeReason_NewDeviceAvailable");

        if ([oldRouteString isEqualToString:@"Speaker"])
        {
        }
    }
    
    if (routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
        //NSLog(@"routeChangeReason = kAudioSessionRouteChangeReason_OldDeviceUnavailable");
        if ([oldRouteString isEqualToString:@"Headphone"] ||
             [oldRouteString isEqualToString:@"LineOut"]){
        }
    } */
}
@end
