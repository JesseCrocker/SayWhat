//
//  savedSoundsViewController.h
//  Say What
//
//  Created by Jesse Crocker on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "sayWhatPlayerView.h"
#import "sayWhatPlayer.h"

@interface savedSoundsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, 
sayWhatPlayerViewDelegate, UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) sayWhatPlayerView *playerView;
@property (strong, nonatomic) IBOutlet UIView *playerViewContainer;

@end
