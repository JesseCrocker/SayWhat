//
//  AppDelegate.h
//  Say What
//
//  Created by Jesse Crocker on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "sayWhatRecorder.h"
#import "sayWhatPlayer.h"
#import <DropboxSDK/DropboxSDK.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, DBRestClientDelegate, AVAudioSessionDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) sayWhatRecorder *sharedRecorder;
@property (strong, nonatomic) sayWhatPlayer *sharedPlayer;
@property (strong, nonatomic) DBRestClient *dbRestClient;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory;
-(void)saveContext;
- (void)dropboxLink;

@end
